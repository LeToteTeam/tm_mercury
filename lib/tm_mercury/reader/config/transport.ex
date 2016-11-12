defmodule TM.Mercury.Reader.Config.Transport do
  use TM.Mercury.Utils.Enum, [
    serial:   0x0000,
    usb:      0x0003,
    unknown:  0x0004,
  ]
end
