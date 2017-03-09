defmodule TM.Mercury.Reader do
  @timeout 5000
  @read_timeout 500

  import TM.Mercury.Utils.Binary
  use Bitwise

  alias TM.Mercury.Protocol.{Opcode, Command}
  alias TM.Mercury.Message
  alias TM.Mercury.Connection, as: Serial
  alias TM.Mercury.ReadPlan

  # Basic Commands

  def start_link(device, opts) do
    Connection.start_link(Serial, {device, defaults(opts)})
  end

  @doc """
  Disconnect the reader.  The connection will be restarted.
  """
  def disconnect(pid, wait? \\ false)
  def disconnect(pid, wait?) do
    Connection.call(pid, {:close, wait?})
  end

  def reboot(pid) do
    # Drop baud rate down to 9600 before rebooting
    with :ok <- change_baud_rate(pid, 9600),
         :ok <- boot_bootloader(pid),
          Process.sleep(200),
          :ok <- disconnect(pid, true),
          # Reconnected at this point
          {:ok, :bootloader} <- get_current_program(pid),
          {:ok, _version} <- boot_firmware(pid),
          {:ok, :application} <- get_current_program(pid),
          :ok <- change_baud_rate(pid, 115200),
          do: :ok
  end

  def boot_bootloader(pid) do
    Command.build(:boot_bootloader)
    |> send_command(pid)
  end

  def boot_firmware(pid) do
    Command.build(:boot_firmware)
    |> send_command(pid)
  end

  @doc """
  Change baud rate on both reader and host.
  """
  def change_baud_rate(pid, rate) do
    # Change on the reader.
    set_baud_rate(pid, rate)
    # Change on the host
    # Not sure Nerves.UART can change baud rate dynamically yet.
    Serial.set_speed(pid, rate)
  end

  @doc """
  Change baud rate on the reader only.
  """
  def set_baud_rate(pid, rate) do
    Command.build(:set_baud_rate, rate: rate)
    |> send_command(pid)
  end

  def get_region(pid) do
    Command.build(:get_region)
    |> send_command(pid)
  end

  def set_region(pid, region) do
    Command.build(:set_region, region: region)
    |> send_command(pid)
  end

  def get_config_param(pid, key) do
    Command.build(:get_reader_optional_params, param: key)
    |> send_command(pid)
  end

  def set_config_param(_pid, _key, _value) do
    # case Config.encode(key) do
    #   {:ok, key} ->
    #
    #     msg =
    #       Opcode.set_reader_optional_params()
    #       |> Message.encode(<<0x01, key :: binary>>)
    #     Serial.send_data(pid, msg)
    #   error ->
    #     error
    #
    # end
  end

  @doc """
  Retrieve hardware, firmware, and bootloader version details.
  """
  def version(pid) do
    Command.build(:version)
    |> send_command(pid)
  end

  @doc """
  Return the identity of the program currently running on the device (bootloader or application).
  """
  def get_current_program(pid) do
    {:ok, <<program>>} = Command.build(:get_current_program)
                         |> send_command(pid)
    # TODO: Move decoding to decoder
    case program &&& 0x03 do
      1 -> {:ok, :bootloader}
      2 -> {:ok, :application}
      _ -> {:error, :unknown_program}
    end
  end

  def get_tag_id_buffer(pid, flags) do
    Command.build(:get_tag_id_buffer, metadata_flags: flags)
    |> send_command(pid)
  end

  def clear_tag_id_buffer(pid) do
    Command.build(:clear_tag_id_buffer)
    |> send_command(pid)
  end

  def get_power_mode(pid) do
    Command.build(:get_power_mode)
    |> send_command(pid)
  end

  def set_power_mode(pid, mode) do
    Command.build(:set_power_mode, mode: mode)
    |> send_command(pid)
  end

  def get_tag_protocol(pid) do
    Command.build(:get_tag_protocol)
    |> send_command(pid)
  end

  def set_tag_protocol(pid, protocol) do
    Command.build(:set_tag_protocol, protocol: protocol)
    |> send_command(pid)
  end

  def get_antenna_port(pid) do
    Command.build(:get_antenna_port)
    |> send_command(pid)
  end

  def set_antenna_port(pid, ports) do
    Command.build(:set_antenna_port, ports: ports)
    |> send_command(pid)
  end

  def get_reader_stats(pid, option \\ :get_per_port, flags \\ :all) do
    initialize_reader(pid)
    Command.build(:get_reader_stats, option: option, flags: flags)
    |> send_command(pid)
  end

  def reset_reader_stats(pid, flags) do
    Command.build(:get_reader_stats, option: :reset, flags: flags)
    |> send_command(pid)
  end

  def initialize_reader(pid) do
    opts = Application.get_env(:tm_mercury, :reader)
    region = opts[:region]
    power_mode = opts[:power_mode]

    :ok = set_region(pid, region)
    :ok = set_power_mode(pid, power_mode)
  end

  def read_sync(pid, %ReadPlan{} = rp, timeout \\ @read_timeout) do
    # Validate the read plan
    case ReadPlan.validate(rp) do
      [errors: []] -> :ok
        :ok = initialize_reader(pid)

        # prepare the read plan
        :ok = ReadPlan.prepare(pid, rp)

        # clear the tag buffer`
        :ok = clear_tag_id_buffer(pid)

        # TODO: Move this to the Command module.
        # assemble the payload
        payload = <<
          0x00, # Option Byte (autonomous_read)
          0x00, 0x13, #Search Flags
          timeout :: uint16
        >>
        # Start the read
        msg =
          Opcode.read_tag_id_multiple
          |> Message.encode(payload)
        case Serial.send_data(pid, msg, timeout: (timeout + 1000)) do
          {:ok, _count} ->
            flags = TM.Mercury.Tag.MetadataFlag.all
            {:ok, _tag} = get_tag_id_buffer(pid, flags)
          {:error, :no_tags_found} ->
            {:error, :no_tags_found}
        end
      [errors: errors] ->
        {:error, errors}
    end
  end

  def read_async_start(pid, %ReadPlan{} = rp, callback \\ nil) do
    cb = callback || self()
    # Validate the read plan
    case ReadPlan.validate(rp) do
      [errors: []] -> :ok
        :ok = initialize_reader(pid)

        # prepare the read plan
        :ok = ReadPlan.prepare(pid, rp)

        # clear the tag buffer`
        :ok = clear_tag_id_buffer(pid)

        # TODO: Move to Command module.
        # assemble the payload
        payload = <<
          0x00 :: uint16, # timout 0 for embedded read
          0x01, # Option Byte (Continuious Read),
          TM.Mercury.Protocol.Opcode.read_tag_id_multiple :: uint8,
          0x00 :: uint16, #Search Flags
          TM.Mercury.Tag.Protocol.encode!(rp.tag_protocol) :: binary,
          0x7, 0x22, 0x10, 0x0, 0x1b, 0x0, 0xfa, 0x1, 0xff # This makes things work ¯\_(ツ)_/¯
        >>
        # Start the read
        msg =
          Opcode.multi_protocol_tag_op
          |> Message.encode(payload)
        case Serial.send_data(pid, msg, timeout: 500) do
          {:ok, _} ->
            Serial.start_async(pid, cb)
          error ->
            error
        end
      [errors: errors] ->
        {:error, errors}
    end
  end

  def read_async_stop(pid) do
    payload = <<
      0x00,
      0x00,
      0x02>>
    msg =
      Opcode.multi_protocol_tag_op
      |> Message.encode(payload)
    case Serial.send_data(pid, msg, timeout: 500) do
      {:ok, _} ->
        Serial.stop_async(pid)
      error ->
        error
    end
  end

  ## Helpers

  defp defaults(opts) do
    Keyword.put_new(opts, :timeout, @timeout)
  end

  def send_command(:error, _pid),
    do: {:error, :command_error}
  def send_command({:error, _reason} = error, _pid),
    do: error
  def send_command({:ok, cmd}, pid),
    do: send_command(cmd, pid)
  def send_command(cmd, pid),
    do: Serial.send_data(pid, cmd)

end
