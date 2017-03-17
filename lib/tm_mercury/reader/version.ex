defmodule TM.Mercury.Reader.Version do
  alias __MODULE__
  defstruct [:bootloader, :firmware, :firmware_date, :hardware, :model, :supported_protocols, :software]

  # TODO: Move these to an inspect protocol somewhere
  def format_version(%Version{} = version) do
    formatted = Map.from_struct(version)
    |> Enum.map(fn({k, v}) -> {k, format_version_field({k, v})} end)
    |> Enum.concat([software: format_software_field(version)])

    struct(__MODULE__, formatted)
  end

  defp format_version_field({:firmware_date, value}) do
    Enum.map(:binary.bin_to_list(value), &(Integer.to_string(&1, 16)))
    |> Enum.join()
  end

  defp format_version_field({_key, value}) when is_binary(value) and byte_size(value) == 4 do
    Enum.map(:binary.bin_to_list(value), &(Integer.to_string(&1, 16)))
    |> Enum.join(".")
  end
  defp format_version_field({_key, value}), do: value

  defp format_software_field(reader),
    do: "#{format_version_field({:firmware, reader.firmware})}-#{format_version_field({:firmware_date, reader.firmware_date})}-BL#{format_version_field({:bootloader, reader.bootloader})}"
end
