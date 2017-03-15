defmodule TM.Mercury.Utils do

  def to_hex_list(x) when is_list(x) do
    Enum.map x, &( Base.encode16(<<&1>>))
  end

  def to_hex_list(x) when is_binary(x)  do
    :erlang.binary_to_list(x)
      |> to_hex_list
  end

  def to_hex_string(x) when is_binary(x) do
    to_hex_list(x)
      |> to_hex_string
  end

  def to_hex_string(x) when is_list(x) do
    Enum.join x, " "
  end

  # TODO: Move these to an inspect protocol somewhere
  def format_reader_version(version) do
    Enum.map(version, fn({k, v}) -> {k, format_version(v)} end)
    |> Enum.concat([software: format_software(version)])
  end

  defp format_version(version) when is_binary(version) and byte_size(version) == 4 do
    Enum.map(:binary.bin_to_list(version), &(Integer.to_string(&1, 16)))
    |> Enum.join(".")
  end
  defp format_version(version), do: version

  defp format_software(reader),
    do: "#{format_version(reader.firmware)}-#{format_version(reader.firmware_date)}-BL#{format_version(reader.bootloader)}"
end
