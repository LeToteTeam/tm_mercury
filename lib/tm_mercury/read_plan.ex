defmodule TM.Mercury.ReadPlan do
  alias TM.Mercury.Reader

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

  def prepare(pid, rp) do
    # First verify the Protocol
    case Reader.get_tag_protocol(pid) do
      {:ok, tag_protocol} ->
        if tag_protocol != rp.tag_protocol do
          protocol = TM.Mercury.Tag.Protocol.encode!(rp.tag_protocol)
          :ok = Reader.set_tag_protocol(pid, protocol)
        end
      {:error, error} ->
        raise TM.Mercury.Error, error
    end

    # Next check the antenna port settings
    ant =
      case rp.antennas do
        {rp_tx, rp_rx} -> {rp_tx, rp_rx}
        ant when is_list(ant) -> ant
        ant when is_integer(ant)-> {ant, ant}
      end
    Reader.set_antenna_port(pid, ant)

    # case Reader.get_antenna_port(pid) do
    #   {:ok, {tx, rx}} ->
    #     {rp_tx, rp_rx} =

    #     if tx != rp_tx or rx != rp_rx do
    #       :ok =
    #     end
    #   {:error, error} ->
    #     raise TM.Mercury.Error, error
    # end

    # Make sure the read filter is enabled
    case Reader.get_config_param(pid, :enable_read_filter) do
      {:ok, true} -> :noop
      {:ok, false} ->
        Reader.set_config_param(rp, :enable_read_filter, true)
      {:error, error} ->
        raise TM.Mercury.Error, error
    end

    # Check to see that the read filter timeout is 0
    case Reader.get_config_param(pid, :read_filter_timeout) do
      {:ok, 0}  -> :noop
      {:ok, _} ->
        Reader.set_config_param(rp, :read_filter_timeout, 0)
      {:error, error} ->
        raise TM.Mercury.Error, error
    end
    :ok
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
