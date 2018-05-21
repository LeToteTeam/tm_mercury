defmodule TM.Mercury.Tag do
  use Bitwise
  import TM.Mercury.Utils.Binary
  alias __MODULE__

  def parse(data, flags) do
    metadata_flags = TM.Mercury.Tag.MetadataFlag.list()

    {data, []}
    |> parse_read_count(flags &&& metadata_flags[:read_count])
    |> parse_rssi(flags &&& metadata_flags[:rssi])
    |> parse_antenna_id(flags &&& metadata_flags[:antenna_id])
    |> parse_frequency(flags &&& metadata_flags[:frequency])
    |> parse_timestamp(flags &&& metadata_flags[:timestamp])
    |> parse_phase(flags &&& metadata_flags[:phase])
    |> parse_protocol(flags &&& metadata_flags[:protocol])
    |> parse_data(flags &&& metadata_flags[:data])
    |> parse_gpio(flags &&& metadata_flags[:gpio_status])
    |> Tag.Type.parse()
  end

  def parse_read_count(ret, 0), do: ret

  def parse_read_count({<<read_count, tail::binary>>, result}, _) do
    {tail, Keyword.put(result, :read_count, read_count)}
  end

  def parse_rssi(data, 0), do: data

  def parse_rssi({<<rssi::8-signed, tail::binary>>, result}, _) do
    {tail, Keyword.put(result, :rssi, rssi)}
  end

  def parse_antenna_id(data, 0), do: data

  def parse_antenna_id({<<tx::4, rx::4, tail::binary>>, result}, _) do
    {tail, Keyword.put(result, :antenna_id, [tx, rx])}
  end

  def parse_frequency(data, 0), do: data

  def parse_frequency({<<freq::24, tail::binary>>, result}, _) do
    {tail, Keyword.put(result, :frequency, freq)}
  end

  def parse_timestamp(data, 0), do: data

  def parse_timestamp({<<ts::uint32, tail::binary>>, result}, _) do
    {tail, Keyword.put(result, :timestamp, ts)}
  end

  def parse_phase(data, 0), do: data

  def parse_phase({<<phase::uint16, tail::binary>>, result}, _) do
    {tail, Keyword.put(result, :phase, phase)}
  end

  def parse_protocol(data, 0), do: data

  def parse_protocol({<<protocol, tail::binary>>, result}, _) do
    protocol = TM.Mercury.Tag.Protocol.decode!(protocol)
    {tail, Keyword.put(result, :protocol, protocol)}
  end

  def parse_data(data, 0), do: data

  def parse_data({<<bit_len::uint16, tail::binary>>, result}, _) do
    byte_len = bytes_for_bits(bit_len)

    if byte_len > 0 do
      <<data::binary-unit(8)-size(byte_len), tail::binary>> = tail
      {tail, Keyword.put(result, :data, data)}
    else
      {tail, result}
    end
  end

  def parse_gpio(data, 0), do: data

  def parse_gpio({<<gpio, tail::binary>>, result}, _) do
    {tail, Keyword.put(result, :gpio, gpio)}
  end
end
