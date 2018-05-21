defmodule TM.Mercury.Reader.PowerMode do
  use TM.Mercury.Utils.Enum,
    full: 0,
    min_save: 1,
    med_save: 2,
    max_save: 3,
    sleep: 4
end
