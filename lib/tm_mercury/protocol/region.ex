defmodule TM.Mercury.Protocol.Region do
  use TM.Mercury.Utils.Enum,
    # Unspecified region
    none: 0x00,
    # North America
    na: 0x01,
    # European Union
    eu: 0x02,
    # Korea
    kr: 0x03,
    # India
    in: 0x04,
    # Japan
    jp: 0x05,
    # People's Republic of China
    prc: 0x06,
    # European Union 2
    eu2: 0x07,
    # European Union 3
    eu3: 0x08,
    # Korea 2
    kr2: 0x09,
    # People's Republic of China(840MHZ)
    prc2: 0x0A,
    # Australia
    au: 0x0B,
    # New Zealand !!EXPERIMENTAL!!
    nz: 0x0C,
    # Reduced FCC region
    na2: 0x0D,
    # 5MHZ FCC band
    na3: 0x0E,
    # Open
    open: 0xFF
end
