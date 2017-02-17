defmodule TM.Mercury.Reader do
  @timeout 5000
  @read_timeout 500

  import TM.Mercury.Utils.Binary
  use Bitwise

  alias TM.Mercury.Protocol.{Parameter, Opcode}
  alias TM.Mercury.Message
  alias TM.Mercury.Connection, as: Serial
  alias TM.Mercury.Reader.Config
  alias TM.Mercury.ReadPlan
  alias __MODULE__
  # Basic Commands

  def start_link(device, opts) do
    opts = defaults(opts)
    Connection.start_link(Serial, {device, opts})
  end

  def stop(pid) do
    Connection.call(pid, :close)
  end

  def get_param(pid, param) do
    Serial.send_data(pid, Parameter.get(param))
  end

  def set_param(pid, param, value) do
    Serial.send_data(pid, Parameter.set(param, value))
  end

  def get_config_param(pid, key) do
    case Config.encode(key) do
      {:ok, key} ->
        msg =
          Opcode.get_reader_optional_params()
          |> Message.encode(<<0x01, key :: binary>>)
        Serial.send_data(pid, msg)
      error ->
        error
    end
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

  def read_sync(pid, %ReadPlan{} = rp, timeout \\ @read_timeout) do
    # Validate the read plan
    case ReadPlan.validate(rp) do
      [errors: []] -> :ok
        # prepare the read plan
        :ok = ReadPlan.prepare(pid, rp)

        # Configure the region
        case get_param(pid, :region_id) do
          {:ok, :na} -> :noop
          {:ok, :none} ->
            set_param(pid, :region_id, :na)
          {:error, error} ->
            raise TM.Mercury.Error, error
        end

        # clear the tag buffer`
        :ok = clear_tag_id_buffer(pid)

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
          {:ok, count} ->
            flags =
              TM.Mercury.Tag.MetadataFlag.all
            {:ok, tag} = get_tag_id_buffer(pid, flags)
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
        # prepare the read plan
        :ok = ReadPlan.prepare(pid, rp)

        # Configure the region
        case get_param(pid, :region_id) do
          {:ok, :na} -> :noop
          {:ok, :none} ->
            set_param(pid, :region_id, :na)
          {:error, error} ->
            raise TM.Mercury.Error, error
        end

        # clear the tag buffer`
        :ok = clear_tag_id_buffer(pid)

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
            Serial.start_async(pid)
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

  # Extended Commands

  def send(pid, command) do
    Serial.send_data(pid, command)
  end

  def version(pid) do
    msg =
      Opcode.version
      |> Message.encode()
    Serial.send_data(pid, msg)
  end

  def get_current_program(pid) do
    msg =
      Opcode.get_current_program
      |> Message.encode()
    Serial.send_data(pid, msg)
  end

  def get_power_mode(pid) do
    msg =
      Opcode.get_power_mode
      |> Message.encode()
    Serial.send_data(pid, msg)
  end

  def get_tag_protocol(pid) do
    msg =
      Opcode.get_tag_protocol
      |> Message.encode()
    Serial.send_data(pid, msg)
  end

  def get_antenna_port(pid) do
    msg =
      Opcode.get_antenna_port
      |> Message.encode()
    Serial.send_data(pid, msg)
  end

  def get_reader_stats(pid, flags) do
    msg =
      Opcode.get_reader_stats
      |> Message.encode(<<
        Reader.Stats.Option.get_per_port,
        flags
      >>)
    Serial.send_data(pid, msg)
  end

  def get_tag_id_buffer(pid, metadata_flags) do
    msg =
      Opcode.get_tag_id_buffer
      |> Message.encode(<<
        metadata_flags :: uint16,
        0x00
      >>)
    Serial.send_data(pid, msg)
  end

  def clear_tag_id_buffer(pid) do
    msg =
      Opcode.clear_tag_id_buffer
      |> Message.encode()
    Serial.send_data(pid, msg)
  end

  def set_power_mode(pid, mode) do
    case TM.Mercury.Reader.PowerMode.encode(mode) do
      {:ok, mode} ->
        msg =
          Opcode.set_power_mode
          |> Message.encode(
            mode
          )
        Serial.send_data(pid, msg)
      error -> error
    end
  end

  def set_tag_protocol(pid, protocol) do
    msg =
      Opcode.set_tag_protocol
      |> Message.encode(<<
        protocol :: uint16
      >>)
    Serial.send_data(pid, msg)
  end

  def set_antenna_port(pid, {tx, rx}) do
    msg =
      Opcode.set_antenna_port
      |> Message.encode(<<
        tx, rx
      >>)
    Serial.send_data(pid, msg)
  end
  def set_antenna_port(pid, ports) when is_list(ports) do
    ant = Enum.reduce(ports, <<>>, fn({rx, tx}, ant) ->
      ant <> <<rx, tx>>
    end)
    |> IO.inspect
    msg =
      Opcode.set_antenna_port
      |> Message.encode(<<
        2,
        ant :: binary
      >>)
      |> IO.inspect
    Serial.send_data(pid, msg)
  end
  def set_antenna_port(pid, port) when is_integer(port) do
    set_antenna_port(pid, {port, port})
  end

  def reset_reader_stats(pid, flags) do
    msg =
      Opcode.get_reader_stats
      |> Message.encode(<<
        Reader.Stats.Option.reset,
        flags
      >>)
    Serial.send_data(pid, msg)
  end

  ## Helpers
  defp defaults(opts) do
    Keyword.put_new(opts, :timeout, @timeout)
  end


end
