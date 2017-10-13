defmodule TM.Mercury.Reader do
  use GenServer

  require Logger

  alias TM.Mercury.{Transport, ReadAsyncTask, Protocol.Command}
  alias TM.Mercury.{SimpleReadPlan, StopTriggerReadPlan}

  @def_read_plan        %SimpleReadPlan{}
  @def_read_timeout_ms  100
  @def_async_period_ms  500

  @type command_result :: :ok
  @type query_result :: {:ok, term}
  @type error :: {:error, term}
  @type read_timeout :: pos_integer
  @type read_plan :: SimpleReadPlan.t | StopTriggerReadPlan.t

  defstruct [
    model: nil,
    power_mode: :full,
    region: :na
  ]

  # Client API

  @doc """
  Disconnect the reader.

  The connection will be restarted.
  """
  @spec reconnect(pid) :: command_result | error
  def reconnect(pid) do
    GenServer.call(pid, :reconnect)
  end

  @doc """
  Execute the reader's bootloader.
  """
  @spec boot_bootloader(pid) :: command_result | error
  def boot_bootloader(pid) do
    GenServer.call(pid, :boot_bootloader)
  end

  @doc """
  Execute the reader's firmware from the bootloader.
  """
  @spec boot_firmware(pid) :: command_result | error
  def boot_firmware(pid) do
    GenServer.call(pid, :boot_firmware)
  end

  @doc """
  Reboot the reader.
  """
  @spec reboot(pid) :: command_result | error
  def reboot(pid) do
    GenServer.call(pid, :reboot)
  end

  @doc """
  Return hardware, firmware, and bootloader version details.
  """
  @spec get_version(pid) :: query_result | error
  def get_version(pid) do
    GenServer.call(pid, :version)
  end

  @doc """
  Return the identity of the program currently running on the device.
  """
  @spec get_current_program(pid) :: query_result | error
  def get_current_program(pid) do
    GenServer.call(pid, :get_current_program)
  end

  @doc """
  Set the reader's serial baud rate.

  The host's baud rate must be changed separately.
  """
  @spec set_baud_rate(pid, pos_integer) :: command_result | error
  def set_baud_rate(pid, rate) do
    GenServer.call(pid, [:set_baud_rate, rate])
  end

  @doc """
  Return the tags that have accumulated in the reader's buffer
  while waiting on a synchronous read timeout to expire.
  """
  @spec get_tag_id_buffer(pid, list) :: query_result | error
  def get_tag_id_buffer(pid, metadata_flags) do
    GenServer.call(pid, [:get_tag_id_buffer, metadata_flags])
  end

  @doc """
  Clear the tag buffer.
  """
  @spec clear_tag_id_buffer(pid) :: command_result | error
  def clear_tag_id_buffer(pid) do
    GenServer.call(pid, :clear_tag_id_buffer)
  end

  @doc """
  Set the RF regulatory environment that the reader will operate within.
  """
  @spec set_region(pid, atom) :: command_result | error
  def set_region(pid, region) do
    GenServer.call(pid, [:set_region, region])
  end

  @doc """
  Return the RF regulatory environment that the reader will operate within.
  """
  @spec get_region(pid) :: query_result | error
  def get_region(pid) do
    GenServer.call(pid, :get_region)
  end

  @doc """
  Set the power-consumption mode of the reader.
  """
  @spec set_power_mode(pid, atom) :: command_result | error
  def set_power_mode(pid, mode) do
    GenServer.call(pid, [:set_power_mode, mode])
  end

  @doc """
  Get the power-consumption mode of the reader.

  This is not related to the TX/RX power.
  """
  @spec get_power_mode(pid) :: query_result | error
  def get_power_mode(pid) do
    GenServer.call(pid, :get_power_mode)
  end

  @doc """
  Get the current TX power for reading tags in centi-dBm.

  ## Examples

      iex> TM.Mercury.Reader.get_read_tx_power(pid)
      {:ok, 2500} # 25 dBm

  """
  @spec get_read_tx_power(pid) :: query_result | error
  def get_read_tx_power(pid) do
    GenServer.call(pid, :get_read_tx_power)
  end

  @doc """
  Set the current TX power for reading tags in centi-dBm.

  ## Examples

      iex> TM.Mercury.Reader.set_read_tx_power(pid, 2500) # 25 dBm
      :ok

  """
  @spec set_read_tx_power(pid, number) :: command_result | error
  def set_read_tx_power(pid, level) do
    GenServer.call(pid, [:set_read_tx_power, level])
  end

  @doc """
  Set the tag protocol used by the reader
  """
  @spec set_tag_protocol(pid, atom) :: command_result | error
  def set_tag_protocol(pid, protocol) do
    GenServer.call(pid, [:set_tag_protocol, protocol])
  end

  @doc """
  Return the tag protocol used by the reader
  """
  @spec get_tag_protocol(pid) :: query_result | error
  def get_tag_protocol(pid) do
    GenServer.call(pid, :get_tag_protocol)
  end

  @doc """
  Get the radio's temperature
  """
  @spec get_temperature(pid) :: query_result | error
  def get_temperature(pid) do
    GenServer.call(pid, :get_temperature)
  end

  @doc """
  Return the antenna port configuration used by the reader
  """
  @spec get_antenna_port(pid) :: query_result | error
  def get_antenna_port(pid) do
    GenServer.call(pid, :get_antenna_port)
  end

  @doc """
  Set the antenna port configuration used by the reader
  """
  @spec set_antenna_port(pid, term) :: command_result | error
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
  Return the current value of an optional reader parameter with a given key.
  """
  @spec get_param(pid, atom) :: query_result | error
  def get_param(pid, key) do
    GenServer.call(pid, [:get_reader_optional_params, key])
  end

  @doc """
  Set the value of an optional reader parameter with a given key.
  """
  @spec set_param(pid, atom, term) :: query_result | error
  def set_param(pid, key, value) do
    GenServer.call(pid, [:set_reader_optional_params, key, value])
  end

  @doc """
  Read tags synchronously using a read plan and timeout.

  If a timeout is not provided, it will default to `100`.
  If a read plan is not provided, it will default to `SimpleReadPlan`.
  """
  @spec read_sync(pid, read_timeout, read_plan) :: query_result | error
  def read_sync(pid, timeout_ms \\ @def_read_timeout_ms, rp \\ @def_read_plan) do
    GenServer.call(pid, [:read_sync, timeout_ms, rp])
  end

  @doc """
  Start reading tags asynchronously using a custom read plan.
  Tag reads will be sent to the process with pid `listener` until `stop_read_async` is called.

  If `pulse_width_ms` is not provided, it will default to `100`.
  If `period_ms` is not provided, it will default to `500`.
  If a read plan is not provided, it will default to `SimpleReadPlan`.
  """
  @spec read_async_start(pid, pid, pos_integer, pos_integer, read_plan) :: query_result | error

  def read_async_start(pid, listener,
                       pulse_width_ms \\ @def_read_timeout_ms,
                       period_ms \\ @def_async_period_ms,
                       rp \\ @def_read_plan)

  def read_async_start(_pid, _listener, pulse_width_ms, period_ms, _rp) when pulse_width_ms > period_ms do
    {:error, :bad_duty_cycle}
  end

  def read_async_start(pid, listener, pulse_width_ms, period_ms, rp) do
    GenServer.call(pid, [:read_async_start, {pulse_width_ms, period_ms}, rp, listener])
  end

  @doc """
  Stop reading tags asynchronously
  """
  def read_async_stop(pid) do
    GenServer.call(pid, :read_async_stop, 10_000)
  end

  @doc """
  Return the reader's transport connection status
  """
  def status(pid) do
    GenServer.call(pid, :status)
  end

  # Server API

  @doc """
  Start a process and open a connection
  with the reader over UART connected via TTL / USB

  ## Options

  The reader requires the following keys:

    * `device` - the device file for the reader serial connection.

  The following keys are optional:

    * `speed` - the serial port speed.  Defaults to `115200`.
    * `region` - the regulatory RF environment used by the reader. Defaults to `:na` (North America).
      * `:none` - Unspecified region
      * `:na` - North America
      * `:eu` - European Union
      * `:kr` - Korea
      * `:in` - India
      * `:jp` - Japan
      * `:prc` - People's Republic of China
      * `:eu2` - European Union 2
      * `:eu3` - European Union 3
      * `:kr2` - Korea 2
      * `:prc2` - People's Republic of China (840 MHz)
      * `:au` - Australia
      * `:nz` - New Zealand (Experimental)
      * `:na2` - Reduced FCC region
      * `:na3` - 5 MHz FCC band
      * `:open` - Open
    * `power_mode` - the power-consumption mode of the reader. Defaults to `:full`.
      * `:full`
      * `:min_save`
      * `:med_save`
      * `:max_save`
      * `:sleep`
  """
  @spec start_link(keyword) :: {:ok, pid} | error
  def start_link(opts) do
    device = opts[:device]
    name = Path.basename(device) |> String.to_atom
    GenServer.start_link(__MODULE__, {device, opts}, name: name)
  end

  def init({device, opts}) do
    Logger.debug "Starting RFID reader process for #{device} with pid #{inspect self()}"

    # Pass this subset of options along to the transport process
    ts_opts = Keyword.take(opts, [:device, :speed, :timeout, :framing])

    case Connection.start_link(Transport, {self(), ts_opts}) do
      {:ok, ts} ->
        new_reader = struct(%__MODULE__{}, opts)

        state =
          Map.new(opts)
          |> Map.take([:speed])
          |> Map.put(:init, new_reader)
          |> Map.put(:reader, new_reader)
          |> Map.put(:transport, ts)
          |> Map.put(:status, :disconnected)
          |> Map.put(:async_pid, nil)
          |> Map.put(:async_period, @def_async_period_ms)

        {:ok, state}
      error ->
        Logger.warn "Failed to open connection to RFID device at #{device}: #{inspect error}"
        error
    end
  end

  # handle_info callbacks

  def handle_info(:connected, state) do
    Logger.info("Reader connected")
    case initialize_reader(state) do
      {:ok, rdr} ->
        send_to_async_task(:resume, state)
        {:noreply, %{state | status: :connected, reader: rdr}}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info(:disconnected, state) do
    Logger.warn "Reader disconnected"
    send_to_async_task(:suspend, state)
    {:noreply, %{state | status: :disconnected}}
  end

  # Helpers for handle_info callbacks

  defp send_to_async_task(msg, state) do
    case Map.fetch(state, :async_pid) do
      {:ok, pid} when not is_nil(pid) -> send(pid, msg)
      _ -> :noop
    end
  end

  # handle_call callbacks

  def handle_call(:reboot, _from, state) do
    with :ok <- reboot_reader(state),
                new_state = Map.put(state, :status, :disconnected),
      do: {:reply, :ok, new_state}
  end

  def handle_call(:reconnect, _from, %{transport: ts} = state) do
    send_to_async_task(:suspend, state)
    resp = Transport.reopen(ts)
    {:reply, resp, %{state | status: :disconnected}}
  end

  def handle_call(:boot_bootloader, _from, %{transport: ts, reader: rdr} = s) do
    resp = boot_bootloader(ts, rdr)
    {:reply, resp, s}
  end

  def handle_call([:set_region|[region]] = cmd, _from, %{transport: ts, reader: rdr} = s) do
    exec_command_bind_reader_state(ts, rdr, cmd, s, fn r ->
      %{r | region: region}
    end)
  end

  def handle_call([:set_power_mode|[mode]] = cmd, _from, %{transport: ts, reader: rdr} = s) do
    # Handle set_power_mode separately so we can track the state change.
    exec_command_bind_reader_state(ts, rdr, cmd, s, fn r ->
      %{r | power_mode: mode}
    end)
  end

  def handle_call([:read_sync, timeout, rp], _from, %{transport: ts, reader: rdr} = state) do
    :ok = prepare_read(ts, rdr, rp)

    reply =
      case execute_read_sync(ts, rdr, timeout, rp) do
        {:ok, _tags} = ok -> ok
        {:error, :no_tags_found} -> {:ok, []}
        {:error, _} = error ->
          Logger.error "Error while executing read_sync: #{inspect error}"
          error
      end

    {:reply, reply, state}
  end

  def handle_call([:read_async_start, {pw, period} = cycle, rp, listener], _from, state) do
    case Map.fetch(state, :async_pid) do
      {:ok, pid} when not is_nil(pid) ->
        {:reply, {:error, {:already_started, pid}}, state}
      _ ->
        Logger.info(fn -> "Starting async reads with #{trunc Float.round(pw / (pw + period), 2) * 100}% duty cycle" end)
        {:ok, pid} = Task.start_link(ReadAsyncTask, :start_link, [self(), cycle, rp, listener])
        {:reply, :ok, %{state | async_pid: pid, async_period: period}}
    end
  end

  def handle_call(:read_async_stop, _from, state) do
    case Map.fetch(state, :async_pid) do
      {:ok, pid} when is_pid(pid) ->
        async_period = Map.get(state, :async_period, @def_async_period_ms)
        stop_timeout = async_period * 2

        stop_task =
          Task.async(fn ->
            send(pid, {:stop, self()})
            receive do
              reply -> reply
            end
          end)

        stop_result = 
          case Task.yield(stop_task, stop_timeout) || Task.shutdown(stop_task) do
            nil ->
              Logger.warn "Failed to stop read async process in #{stop_timeout}ms"
              Process.unlink(pid)
              Process.exit(pid, :kill)
              {:ok, :killed}
            other ->
              other
          end
        {:reply, stop_result, %{state | async_pid: nil}}
      _ ->
        {:reply, {:error, :not_started}, state}
    end
  end

  def handle_call(:status, _from, %{status: status} = s) do
    {:reply, status, s}
  end

  @doc """
  Catch-all handlers for op commands that don't require state binding or special handling
  """
  def handle_call(cmd, _from, %{transport: ts, reader: rdr} = s) when is_list(cmd) do
    resp = execute(ts, rdr, cmd)
    {:reply, resp, s}
  end
  def handle_call(cmd, _from, %{transport: ts, reader: rdr} = s) when is_atom(cmd) do
    resp = execute(ts, rdr, [cmd])
    {:reply, resp, s}
  end

  # Helpers for handle_call callbacks

  defp initialize_reader(%{transport: ts, init: rdr}) do
    with {:ok, version} <- execute(ts, rdr, :version),
         # Pick up the model first for downstream encoding/decoding that needs to branch by model.
         reader = Map.put(rdr, :model, version.model),
         # Send CRC regardless of transport mode
         :ok <- execute(ts, reader, [:set_reader_optional_params, :send_crc, true]),
         :ok <- execute(ts, reader, [:set_reader_optional_params, :rssi_in_dbm, true]),
         :ok <- execute(ts, reader, [:set_region, reader.region]),
         :ok <- execute(ts, reader, [:set_power_mode, reader.power_mode]),
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

  defp prepare_read(ts, rdr, rp) do
    # Set the protocol
    rp_proto = rp.protocol
    {:ok, rdr_proto} = execute(ts, rdr, :get_tag_protocol)
    unless rp_proto == rdr_proto do
      Logger.debug "Read plan's tag protocol (#{inspect rp_proto}) differs from reader (#{inspect rdr_proto}), configuring reader"
      :ok = execute(ts, rdr, [:set_tag_protocol, rp_proto])
    end

    # Set the antennas
    rp_antennas = rp.antennas
    {:ok, rdr_antennas} = execute(ts, rdr, :get_antenna_port)
    unless rp_antennas == rdr_antennas do
      Logger.debug "Read plan's antenna settings (#{inspect rp_antennas}) differ from reader (#{inspect rdr_antennas}), configuring reader"
      :ok = execute(ts, rdr, [:set_antenna_port, rp_antennas])
    end

    # Clear the tag buffer
    :ok = execute(ts, rdr, :clear_tag_id_buffer)

    # Reset statistics
    {:ok, _} = execute(ts, rdr, [:get_reader_stats, :reset, :rf_on_time])

    :ok
  end

  defp execute_read_sync(ts, rdr, timeout, rp) do
    flags = [:configured_list, :large_tag_population_support]
            |> add_flag(:fast_search, rp)

    try do
      with {:ok, cmd}    <- build_command_for_plan(rdr, flags, timeout, rp),
           {:ok, _count} <- Transport.send_data(ts, cmd) do
        flags = TM.Mercury.Tag.MetadataFlag.all
        execute(ts, rdr, [:get_tag_id_buffer, flags])
      end
    catch
      :exit, {:timeout, _} ->
        Logger.warn("Timed out waiting for transport to fulfill send_data call")
        {:error, :timeout}
    end
  end

  defp add_flag(flags, :fast_search, %{fast_search: true}) do
   [:read_multiple_fast_search|flags]
  end
  defp add_flag(flags, _, _), do: flags

  defp build_command_for_plan(rdr, flags, timeout, %SimpleReadPlan{}) do
    op = [:read_tag_id_multiple, flags, timeout]
    Command.build(rdr, op)
  end

  defp build_command_for_plan(_rdr, _flags, _timeout, _rp) do
    {:error, :not_implemented}
  end

  # Generic command helpers

  defp exec_command_bind_reader_state(ts, rdr, cmd, state, reader_state_func) do
    case execute(ts, rdr, cmd) do
      :ok ->
        new_reader = reader_state_func.(rdr)
        {:reply, :ok, %{state | reader: new_reader}}
      error ->
        {:reply, error, state}
    end
  end

  defp execute(ts, %__MODULE__{} = rdr, cmd) when is_atom(cmd),
    do: execute(ts, rdr, [cmd])

  defp execute(ts, %__MODULE__{} = rdr, cmd) when is_list(cmd) do
    Command.build(rdr, cmd)
    |> send_command(ts)
  end

  defp send_command({:error, _reason} = error, _ts),
    do: error

  defp send_command({:ok, cmd}, ts),
    do: Transport.send_data(ts, cmd)
end
