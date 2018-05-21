defmodule TM.Mercury.Tag.MetadataFlag do
  use TM.Mercury.Utils.Enum,
    none: 0x0000,
    read_count: 0x0001,
    rssi: 0x0002,
    antenna_id: 0x0004,
    frequency: 0x0008,
    timestamp: 0x0010,
    phase: 0x0020,
    protocol: 0x0040,
    data: 0x0080,
    gpio_status: 0x0100,
    all: 0x01FF
end
