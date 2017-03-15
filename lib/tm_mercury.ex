defmodule TM.Mercury do
  alias TM.Mercury.ReadPlan

  @spec enumerate() ::
    map | {:error, term}
  defdelegate enumerate(),
    to: Nerves.UART

  @doc """
  Start a process and open a connection
  with the reader over UART connected via TTL / USB

  params:
    * opts
      * `:device` - The device file for the reader serial connection
      * `:speed` - The port speed, example: speed: 115200
  """
  @spec start_link(opts :: list) ::
    {:ok, pid} | {:error, term}
  defdelegate start_link(opts),
    to: TM.Mercury.Reader

  @spec reconnect(pid) ::
    {:ok, pid} | {:error, term}
  defdelegate reconnect(pid),
    to: TM.Mercury.Reader

  @spec get_param(pid, key :: atom) ::
    {:ok, term} | {:error, term}
  defdelegate get_param(pid, key),
    to: TM.Mercury.Reader

  @spec set_param(pid, key :: atom, val :: any) ::
    {:ok, term} | {:error, term}
  defdelegate set_param(pid, key, val),
    to: TM.Mercury.Reader

  @spec read_sync(pid, ReadPlan.t) ::
    {:ok, term} | {:error, term}
  defdelegate read_sync(pid, read_plan),
    to: TM.Mercury.Reader

  @spec read_sync(pid) ::
    {:ok, term} | {:error, term}
  defdelegate read_sync(pid),
    to: TM.Mercury.Reader

  #@spec read_async_start(pid, ReadPlan.t) ::
  #  {:ok, term} | {:error, term}
  #defdelegate read_async_start(pid, read_plan),
  #  to: TM.Mercury.Reader

  #@spec read_async_stop(pid) ::
  #  {:ok, term} | {:error, term}
  #defdelegate read_async_stop(pid),
  #  to: TM.Mercury.Reader
end
