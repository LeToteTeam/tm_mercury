defmodule TM.Mercury.Message do
  import TM.Mercury.Utils.Binary
  use Bitwise, operators_only: true

  alias __MODULE__
  alias TM.Mercury.Protocol.Opcode

  defstruct [length: nil, opcode: nil, status: nil, data: nil, crc: nil]

  def encode(opcode, data \\ <<>>) do
    <<opcode, data :: binary>>
  end

  def decode(%Message{opcode: opcode} = msg) when is_integer(opcode) do
    Map.put(msg, :opcode, Opcode.decode!(opcode))
    |> decode
  end

  def decode(%Message{opcode: :version} = msg) do
    <<bl :: 4-bytes,
      hw :: 4-bytes,
      fw_date :: 4-bytes,
      fw :: 4-bytes,
      protocols :: uint32>> = msg.data

    <<model, _tail :: binary>> = hw

    data = %{bootloader: bl,
      hardware: hw,
      firmware_date: fw_date,
      firmware: fw,
      model: TM.Mercury.Reader.Model.decode!(model),
      supported_protocols: decode_protocols(protocols)}

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

  def decode(%{opcode: :get_current_program} = msg) do
    <<program>> = msg.data
    app = case program &&& 0x03 do
      1 -> :bootloader
      2 -> :application
      _ -> {:error, :unknown_program}
    end
    Map.put(msg, :data, app)
  end

  def decode(msg), do: msg

  def decode_protocols(mask), do: decode_protocols(mask, 32, 0, [])
  def decode_protocols(mask, size, bit, acc) when bit < size do
    if (mask &&& (1 <<< bit)) === 0 do
      decode_protocols(mask, size, bit + 1, acc)
    else
      decode_protocols(mask, size, bit + 1, [bit + 1 | acc])
    end
  end
  def decode_protocols(_mask, size, bit, acc) when bit == size do
    Enum.map(acc, &(TM.Mercury.Tag.Protocol.decode!(&1)))
    |> Enum.reverse
  end

end
