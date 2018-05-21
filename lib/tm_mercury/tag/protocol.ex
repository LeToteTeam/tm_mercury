defmodule TM.Mercury.Tag.Protocol do
  use TM.Mercury.Utils.Enum,
    none: 0x00,
    iso180006b: 0x03,
    gen2: 0x05,
    iso180006b_ucode: 0x06,
    ipx64: 0x07,
    ipx256: 0x08,
    ata: 0x1D
end
