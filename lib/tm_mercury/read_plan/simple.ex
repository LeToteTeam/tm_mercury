defmodule TM.Mercury.ReadPlan.Simple do
    defstruct [
      antennas: [],
      protocol: nil,
      filter: nil,
      tag_opts: [],
      fast_search:  false,
      weight: nil,
      autonomous_read: false
    ]
end
