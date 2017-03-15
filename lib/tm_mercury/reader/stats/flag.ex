defmodule TM.Mercury.Reader.Stats.Flag do
  use Bitwise
  use TM.Mercury.Utils.Enum, [
  # Total time the port has been transmitting, in milliseconds. Resettable
  rf_on_time:         (1<<<0),
  # detected noise floor with transmitter off. recomputed when requested, not resettable.
  noise_floor:        (1<<<1),
  # detected noise floor with transmitter on. recomputed when requested, not resettable.
  noise_floor_tx_on:  (1<<<3),
  # All of the above
  all:                0xF
  ]
end
