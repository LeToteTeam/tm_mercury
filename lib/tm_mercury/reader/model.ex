defmodule TM.Mercury.Reader.Model do
  use TM.Mercury.Utils.Enum, [
    m5e:         0x00,
    m5e_compact: 0x01,
    m5e_i:       0x02,
    m4e:         0x03,
    m6e:         0x18,
    m6e_prc:     0x19,
    micro:       0x20,
    m6e_nano:    0x30,
    unknown:     0xFF,
  ]
end

