defmodule TM.Mercury.StopTriggerReadPlan do
  @moduledoc """
  Read plan consisting of stop on tag count, antennas, tag protocol, filter, and weight.
  """
  defstruct [
    stop_on_tag_count: 0,
    antennas: {1,1},
    protocol: :gen2,
    filter: "",
    tag_op: nil,
    fast_search:  false,
    weight: 1000,
    autonomous_read: false
  ]

  @type t :: %__MODULE__{
    stop_on_tag_count: non_neg_integer,
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
