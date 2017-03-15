defmodule TM.Mercury.ReadPlan do
  @doc """
  ReadPlan
  """
  defstruct [
    antennas: [],
    tag_protocol: nil,
    filter: "",
    tag_opts: [],
    fast_search:  false,
    weight: nil,
    autonomous_read: false
  ]

  @type t :: %__MODULE__{
    antennas: [(number | {number, number})],
    tag_protocol: binary,
    filter: binary,
    tag_opts: [binary],
    fast_search: boolean,
    weight: number,
    autonomous_read: boolean
  }

  def validate(%__MODULE__{} = rp) do
    [errors: []]
    |> validate_antennas(rp.antennas)
    |> validate_tag_protocol(rp.tag_protocol)
  end

  defp validate_antennas(rep, []) do
    add_error(rep, "antennas: cannot be empty")
  end
  defp validate_antennas(rep, _), do: rep

  defp validate_tag_protocol(rep, nil) do
    add_error(rep, "tag_protocol is undefined")
  end
  defp validate_tag_protocol(rep, _),    do: rep

  defp add_error(rep, message) do
    Keyword.put(rep, :errors, [message | rep.errors])
  end
end
