defmodule TM.Mercury.Reader do
  use GenServer
  require Logger

  @default_opts power_mode: :full, region: :na, antennas: 1,
                tag_protocol: :gen2, read_timeout: 500
  @ts_opt_keys [:device, :speed, :timeout, :framing]

  import TM.Mercury.Utils.Binary
  use Bitwise

  alias __MODULE__
  alias TM.Mercury.{Message, Transport, ReadPlan}
  alias TM.Mercury.Protocol.{Opcode, Command}

  defstruct [:model, :power_mode, :region, :tag_protocol, :antennas]

  # Client API

  @doc """
  Disconnect the reader.  The connection will be restarted.
  """
  def reconnect(pid) do
    GenServer.call(pid, :reconnect)
  end

  @doc """
  Execute the reader's bootloader.
  """
  def boot_bootloader(pid) do
    GenServer.call(pid, :boot_bootloader)
  end

  @doc """
  Execute the reader's firmware from the bootloader.
  """
  def boot_firmware(pid) do
    GenServer.call(pid, :boot_firmware)
  end

  @doc """
  Reboot the reader.
  """
  def reboot(pid) do
    GenServer.call(pid, :reboot)
  end

  @doc """
  Return hardware, firmware, and bootloader version details.
  """
  def get_version(pid) do
    GenServer.call(pid, :version)
  end

  @doc """
  Return the identity of the program currently running on the device.
  Bootloader or application
  """
  def get_current_program(pid) do
    GenServer.call(pid, :get_current_program)
  end

  @doc """
  Set the reader's serial baud rate.
  The host's baud rate must be changed separately.
  """
  def set_baud_rate(pid, rate) do
    GenServer.call(pid, [:set_baud_rate, rate])
  end

  @doc """
  TODO: Docs
  """
  def get_tag_id_buffer(pid, metadata_flags) do
    GenServer.call(pid, [:get_tag_id_buffer, metadata_flags])
  end

  @doc """
  Clear the tag buffer.
  """
  def clear_tag_id_buffer(pid) do
    GenServer.call(pid, :clear_tag_id_buffer)
  end

  @doc """
  Configure the region that the reader will operate within.
  """
  def set_region(pid, region) do
    GenServer.call(pid, [:set_region, region])
  end

  @doc """
  Return the region that the reader is currently configured to operate within.
  """
  def get_region(pid) do
    GenServer.call(pid, :get_region)
  end

  @doc """
  TODO
  """
  def set_power_mode(pid, mode) do
    GenServer.call(pid, [:set_power_mode, mode])
  end

  @doc """
  TODO
  """
  def get_power_mode(pid) do
    GenServer.call(pid, :get_power_mode)
  end

  @doc """
  TODO
  """
  def set_tag_protocol(pid, protocol) do
    GenServer.call(pid, [:set_tag_protocol, protocol])
  end

  @doc """
  TODO
  """
  def get_tag_protocol(pid) do
    GenServer.call(pid, :get_tag_protocol)
  end

  @doc """
  TODO
  """
  def get_antenna_port(pid) do
    GenServer.call(pid, :get_antenna_port)
  end

  @doc """
  TODO
  """
  def set_antenna_port(pid, ports) do
    GenServer.call(pid, [:set_antenna_port, ports])
  end

  @doc """
  TODO
  """
  def get_reader_stats(pid, option, flags) do
    # TODO: Implement decoding.
    # See: https://www.pivotaltracker.com/story/show/141738711
    GenServer.call(pid, [:get_reader_stats, option, flags])
  end

  @doc """
  TODO
  """
  def reset_reader_stats(pid, flags) do
    GenServer.call(pid, [:get_reader_stats, :reset, flags])
  end

  @doc """
  TODO
  """
  def get_param(pid, key) do
    GenServer.call(pid, [:get_reader_optional_params, key])
  end

  @doc """
  TODO
  """
  def set_param(pid, key, value) do
    GenServer.call(pid, [:set_reader_optional_params, key, value])
  end

  @doc """
  Perform a synchronous tag read using the reader configuration
  """
  def read_sync(pid) do
    GenServer.call(pid, :read_sync)
  end

  @doc """
  Perform a synchronous tag read using the provided read plan
  """
  def read_sync(pid, %ReadPlan{} = rp) do
    GenServer.call(pid, [:read_sync, rp])
  end

  @doc """
  Change the read timeout used for synchronous tag reading.
  """
  def set_read_timeout(pid, timeout) do
    GenServer.call(pid, [:set_read_timeout, timeout])
  end

  # Server API

  def start_link(opts) do
    device = opts[:device]
    name = Path.basename(device) |> String.to_atom
    GenServer.start_link(__MODULE__, {device, opts}, name: name)
  end

  def init({device, opts}) do
    Logger.debug "Starting RFID reader process for #{device} with pid #{inspect self()}"

    opts = Keyword.merge(@default_opts, opts)
    ts_opts = Keyword.take(opts, @ts_opt_keys)

    case Connection.start_link(Transport, {self(), ts_opts}) do
      {:ok, ts} ->
        new_reader = struct(%Reader{}, opts)

        state =
          Map.new(opts)
          |> Map.take([:speed, :read_timeout])
          |> Map.put(:init, new_reader)
          |> Map.put(:reader, new_reader)
          |> Map.put(:transport, ts)

        {:ok, state}
      error ->
        Logger.warn "Failed to open connection to RFID device at #{device}: #{inspect error}"
        error
    end
  end

  def handle_info(:connected, state) do
    case initialize_reader(state) do
      {:ok, rdr} -> {:noreply, Map.put(state, :reader, rdr)}
      _ -> {:noreply, state}
    end
  end

  def handle_call(:reboot, _from, state) do
    with :ok <- reboot_reader(state),
      do: {:reply, :ok, state}
  end

  def handle_call(:reconnect, _from, %{transport: ts} = s) do
    resp = Transport.reopen(ts)
    {:reply, resp, s}
  end

  def handle_call(:boot_bootloader, _from, %{transport: ts, reader: rdr} = s) do
    resp = boot_bootloader(ts, rdr)
    {:reply, resp, s}
  end

  def handle_call([:set_region|[region]] = cmd, _from, %{transport: ts, reader: rdr} = s) do
    case execute(ts, rdr, cmd) do
      :ok ->
        {:reply, :ok, update_reader_state(s, :region, region)}
      error ->
        {:reply, error, s}
    end
  end

  def handle_call([:set_power_mode|[mode]] = cmd, _from, %{transport: ts, reader: rdr} = s) do
    # Handle set_power_mode separately so we can track the state change.
    case execute(ts, rdr, cmd) do
      :ok ->
        {:reply, :ok, update_reader_state(s, :power_mode, mode)}
      error ->
        {:reply, error, s}
    end
  end

  def handle_call([:set_tag_protocol|[protocol]] = cmd, _from, %{transport: ts, reader: rdr} = s) do
    # Handle set_tag_protocol separately so we can track the state change.
    case execute(ts, rdr, cmd) do
      :ok ->
        {:reply, :ok, update_reader_state(s, :tag_protocol, protocol)}
      error ->
        {:reply, error, s}
    end
  end

  def handle_call([:set_antenna_port|[ports]] = cmd, _from, %{transport: ts, reader: rdr} = s) do
    # Handle set_antenna_port seperately so we can track the state change.
    case execute(ts, rdr, cmd) do
      :ok ->
        {:reply, :ok, update_reader_state(s, :antennas, ports)}
      error ->
        {:reply, error, s}
    end
  end

  def handle_call([:read_sync, %ReadPlan{} = rp], _from, %{transport: ts, reader: rdr} = s) do
    case read_sync(ts, rdr, rp, s.read_timeout) do
      {:ok, tags, new_reader} ->
        {:reply, {:ok, tags}, %{s | reader: new_reader}}
      {:error, _reason} = error ->
        {:reply, error, s}
    end
  end

  def handle_call(:read_sync, _from, %{transport: ts, reader: rdr} = s) do
    # Create and use a read plan based on the current reader settings
    rp = %ReadPlan{tag_protocol: rdr.tag_protocol, antennas: rdr.antennas}
    case read_sync(ts, rdr, rp, s.read_timeout) do
      {:ok, tags, _} ->
        {:reply, {:ok, tags}, s}
      {:error, _reason} = error ->
        {:reply, error, s}
    end
  end

  def handle_call([:set_read_timeout, timeout], _from, state) do
    {:reply, :ok, %{state | read_timeout: timeout}}
  end

  @doc """
  Catch-all handlers for op commands that don't require any state binding or special handling
  """
  def handle_call(cmd, _from, %{transport: ts, reader: rdr} = s) when is_list(cmd) do
    resp = execute(ts, rdr, cmd)
    {:reply, resp, s}
  end
  def handle_call(cmd, _from, %{transport: ts, reader: rdr} = s) when is_atom(cmd) do
    resp = execute(ts, rdr, [cmd])
    {:reply, resp, s}
  end

  defp initialize_reader(%{transport: ts, init: rdr}) do
    with {:ok, version} <- execute(ts, rdr, :version),
         # Pick up the model first for any downstream encoding/decoding that needs it
         reader = Map.put(rdr, :model, version.model),
         :ok <- execute(ts, reader, [:set_region, reader.region]),
         :ok <- execute(ts, reader, [:set_power_mode, reader.power_mode]),
         :ok <- execute(ts, reader, [:set_tag_protocol, reader.tag_protocol]),
         :ok <- execute(ts, reader, [:set_antenna_port, reader.antennas]),
      do: {:ok, reader}
  end

  defp reboot_reader(%{transport: ts, reader: rdr, speed: speed}) do
    # This should silently fail with {:error, :invalid_opcode} if we're not actually in async mode.
    _ = read_async_stop(ts)

    with :ok <- change_baud_rate(ts, rdr, 9600),
         :ok <- boot_bootloader(ts, rdr),
         :ok <- Transport.reopen(ts),
         # Reconnected at this point
         {:ok, :bootloader} <- execute(ts, rdr, :get_current_program),
         {:ok, _version} <- execute(ts, rdr, :boot_firmware),
         {:ok, :application} <- execute(ts, rdr, :get_current_program),
         :ok <- change_baud_rate(ts, rdr, speed),
      do: :ok
  end

  defp change_baud_rate(ts, reader, rate) do
    # Change the baud rate on both the reader and the host.
    with :ok <- execute(ts, reader, [:set_baud_rate, rate]),
         :ok <- Transport.set_speed(ts, rate),
      do: :ok
  end

  defp boot_bootloader(ts, reader) do
    case execute(ts, reader, :boot_bootloader) do
      :ok ->
        # Give the reader time to gather its wits
        Process.sleep(200)
        :ok
      {:error, :invalid_opcode} ->
        # Already in bootloader, ignore
        :ok
    end
  end

  defp read_sync(ts, rdr, %ReadPlan{} = rp, timeout) do
    # Validate the read plan
    case ReadPlan.validate(rp) do
      [errors: []] ->
        {:ok, new_reader} = prepare_read(ts, rdr, rp)

        search_flags = [:configured_list, :large_tag_population_support]
        op = [:read_tag_id_multiple, search_flags, timeout]

        {:ok, cmd} = Command.build(rdr, op)

        case Transport.send_data(ts, cmd) do
          {:ok, _count} ->
            flags = TM.Mercury.Tag.MetadataFlag.all
            {:ok, tags} = execute(ts, rdr, [:get_tag_id_buffer, flags])
            {:ok, tags, new_reader}
          {:error, _reason} = err ->
            err
        end
      [errors: errors] ->
        {:error, errors}
    end
  end

  defp read_async_start(ts, rdr, %ReadPlan{} = rp, callback \\ nil) do
    cb = callback || self()
    # Validate the read plan
    case ReadPlan.validate(rp) do
      [errors: []] -> :ok
        {:ok, _new_reader} = prepare_read(ts, rdr, rp)

        # TODO: Move to Command module.
        # assemble the payload
        payload = <<
          0x00 :: uint16, # timout 0 for embedded read
          0x01, # Option Byte (Continuious Read),
          TM.Mercury.Protocol.Opcode.read_tag_id_multiple,
          0x00 :: uint16, #Search Flags
          TM.Mercury.Tag.Protocol.encode!(rp.tag_protocol),
          0x7, 0x22, 0x10, 0x0, 0x1b, 0x0, 0xfa, 0x1, 0xff # This makes things work ¯\_(ツ)_/¯
        >>
        # Start the read
        msg =
          Opcode.multi_protocol_tag_op
          |> Message.encode(payload)
        case Transport.send_data(ts, msg) do
          {:ok, _} ->
            Transport.start_async(ts, cb)
          error ->
            error
        end
      [errors: errors] ->
        {:error, errors}
    end
  end

  def read_async_stop(ts) do
    payload = <<0x0::16, 0x02>>
    msg =
      Opcode.multi_protocol_tag_op
      |> Message.encode(payload)
    case Transport.send_data(ts, msg) do
      {:ok, _} ->
        :ok
      error ->
        error
    end
  end

  defp prepare_read(ts, rdr, %ReadPlan{} = rp) do
    # First verify the protocol
    rdr = if rp.tag_protocol != rdr.tag_protocol do
      Logger.debug "Read plan's tag protocol differs from reader, reconfiguring reader"
      :ok = execute(ts, rdr, [:set_tag_protocol, rp.tag_protocol])
      %{rdr | tag_protocol: rp.tag_protocol}
    else
      rdr
    end

    # Next check the antennas
    rdr = if rp.antennas != rdr.antennas do
      Logger.debug "Read plan's antenna settings differ from reader, reconfiguring reader"
      :ok = execute(ts, rdr, [:set_antenna_port, rp.antennas])
      %{rdr | antennas: rp.antennas}
    else
      rdr
    end

    # Clear the tag buffer
    :ok = execute(ts, rdr, :clear_tag_id_buffer)

    # Reset statistics
    {:ok, _} = execute(ts, rdr, [:get_reader_stats, :reset, :rf_on_time])

    {:ok, rdr}
  end

  ## Helpers

  defp execute(ts, %Reader{} = rdr, cmd) when is_atom(cmd),
    do: execute(ts, rdr, [cmd])
  defp execute(ts, %Reader{} = rdr, [_key|_args] = cmd) do
    Command.build(rdr, cmd)
    |> send_command(ts)
  end

  defp send_command(:error, _ts),
    do: {:error, :command_error}
  defp send_command({:error, _reason} = error, _ts),
    do: error
  defp send_command({:ok, cmd}, ts),
    do: send_command(cmd, ts)
  defp send_command(cmd, ts),
    do: Transport.send_data(ts, cmd)

  # More readable than %{state | reader: %{state.reader | key: value}}!
  defp update_reader_state(state, key, value),
    do: %{state | reader: Map.put(state.reader, key, value)}

end
