defmodule TM.Mercury.Tag.MetadataFlag do
  use Bitwise
  import TM.Mercury.Utils.Binary

  use TM.Mercury.Utils.Enum, [
    none:         0x0000,
    read_count:    0x0001,
    rssi:         0x0002,
    antenna_id:    0x0004,
    frequency:    0x0008,
    timestamp:    0x0010,
    phase:        0x0020,
    protocol:     0x0040,
    data:         0x0080,
    gpio_status:  0x0100
  ]

  def all() do
    [{_, h} | t] =
      list()
      |> Enum.reject(fn({_, v}) -> v == 0  end)
    Enum.reduce(t, h, fn({_, v}, acc) ->
      acc ||| v
    end)
  end

end
