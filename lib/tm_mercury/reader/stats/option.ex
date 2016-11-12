defmodule TM.Mercury.Reader.Stats.Option do
  use TM.Mercury.Utils.Enum, [
    # Get statistics specified by the statistics flag
    get:          0x00,

    # reset the specified statistic
    reset:        0x01,

    # get the per-port statistics specified by the statistics flag
    get_per_port: 0x02
  ]
end
