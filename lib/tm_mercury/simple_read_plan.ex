defmodule TM.Mercury.SimpleReadPlan do
  @moduledoc """
  Read plan consisting of antennas, tag protocol, filter, and weight.
  """
  defstruct antennas: {1, 1},
            protocol: :gen2,
            filter: "",
            tag_op: nil,
            fast_search: false,
            weight: 1000,
            autonomous_read: false

  @type t :: %__MODULE__{
          antennas: number | {number, number},
          protocol: atom,
          filter: binary,
          tag_op: atom,
          fast_search: boolean,
          weight: non_neg_integer,
          autonomous_read: boolean
        }

  def new do
    %__MODULE__{}
  end
end
