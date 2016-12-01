defmodule TM.Mercury.Message do
  alias TM.Mercury.Protocol.Opcode
  import TM.Mercury.Utils.Binary

  alias __MODULE__

  defstruct [length: nil, opcode: nil, status: nil, data: nil, crc: nil]

  def encode(opcode, data \\ <<>>) do
    <<opcode, data :: binary>>
  end

  def decode(%Message{opcode: opcode} = msg) when is_integer(opcode) do
    Map.put(msg, :opcode, Opcode.decode!(opcode))
    |> decode
  end

  def decode(%Message{opcode: :version} = msg) do
    <<bootloader_vsn1 :: uint8,
      bootloader_vsn2 :: uint8,
      bootloader_vsn3 :: uint8,
      bootloader_vsn4 :: uint8,
      hardware_date :: uint32,
      firmware_date :: uint32,
      firmware_vsn :: uint32,
      protocols :: binary(4)>> = msg.data

    data = %{
      bootloader_version: {bootloader_vsn1, bootloader_vsn2, bootloader_vsn3, bootloader_vsn4},
      hardware_date: hardware_date,
      firmware_date: firmware_date,
      firmware_version: firmware_vsn,
      protocols: protocols
    }
    Map.put(msg, :data, data)
  end

  def decode(%Message{opcode: :get_power_mode} = msg) do
    <<mode :: uint8>> = msg.data
    mode = TM.Mercury.Reader.PowerMode.decode!(mode)
    Map.put(msg, :data, mode)
  end

  def decode(%Message{opcode: :get_region} = msg) do
    <<region :: uint8>> = msg.data
    data = TM.Mercury.Protocol.Region.decode!(region)
    Map.put(msg, :data, data)
  end

  def decode(%Message{opcode: :get_reader_optional_params} = msg) do
    <<_, config_param, value :: binary>> = msg.data
    data =
      TM.Mercury.Reader.Config.decode!(config_param)
      |> TM.Mercury.Reader.Config.decode_data(value)
    Map.put(msg, :data, data)
  end

  def decode(%Message{opcode: :get_tag_protocol} = msg) do
    <<tag_protocol :: uint16 >> = msg.data
    Map.put(msg, :data, TM.Mercury.Tag.Protocol.decode!(tag_protocol))
  end

  def decode(%Message{opcode: :get_antenna_port} = msg) do
    <<tx :: uint8, rx :: uint8 >> = msg.data
    Map.put(msg, :data, {tx, rx})
  end

  def decode(%Message{opcode: :read_tag_id_multiple} = msg) do
    <<metadata_flags :: uint16, _, count, tail :: binary>> = msg.data
    if byte_size(tail) > 0 do
      IO.puts "Byte Size > 0"
      IO.puts "Count: #{inspect count}"
      {_, results} =
        Enum.reduce(1..count, {tail, []}, fn(_, {tail, result}) ->
          {tail, res} = TM.Mercury.Tag.parse(tail, metadata_flags)
          {tail, [res | result]}
        end)
      Map.put(msg, :data, results)
    else
      Map.put(msg, :data, count)
    end
  end

  def decode(%Message{opcode: :get_tag_id_buffer} = msg) do
    <<metadata_flags :: uint16, _, count, tail :: binary>> = msg.data
    {_, results} =
      Enum.reduce(1..count, {tail, []}, fn(_, {tail, result}) ->
        {tail, res} = TM.Mercury.Tag.parse(tail, metadata_flags)
        {tail, [res | result]}
      end)
    Map.put(msg, :data, results)
  end

  def decode(%{opcode: :multi_protocol_tag_op} = msg) do
    IO.puts "Background Read Message: #{inspect msg}"
    msg
  end

  def decode(msg), do: msg
end
