defmodule TM.Mercury.Protocol.Region do
  use TM.Mercury.Utils.Enum, [
    none:   0x00,   # Unspecified region
    na:     0x01,   # North America
    eu:     0x02,   # European Union
    kr:     0x03,   # Korea
    in:     0x04,   # India
    jp:     0x05,   # Japan
    prc:    0x06,   # People's Republic of China
    eu2:    0x07,   # European Union 2
    eu3:    0x08,   # European Union 3
    kr2:    0x09,   # Korea 2
    prc2:   0x0A,   # People's Republic of China(840MHZ)
    au:     0x0B,   # Australia
    nz:     0x0C,   # New Zealand !!EXPERIMENTAL!!
    na2:    0x0D,   # Reduced FCC region
    na3:    0x0E,   # 5MHZ FCC band
    open:   0xFF,   # Open
  ]

end
