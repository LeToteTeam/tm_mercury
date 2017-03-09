defmodule TM.Mercury do
  alias TM.Mercury.ReadPlan

  # @spec start_link() ::
  #   {:ok, pid} | {:error, term}
  defdelegate enumerate(),
    to: Nerves.UART

  @doc """
  Start a process and open a connection
  with the reader over UART connected via TTL / USB

  params:
    * dev - The device file for the reader serial connection
    * opts
      * `:speed` - The port speed, example: speed: 115200
  """
  @spec start_link(dev :: binary, opts :: list) ::
    {:ok, pid} | {:error, term}
  defdelegate start_link(device, opts),
    to: TM.Mercury.Reader

  @doc """
  Disconnect the reader.  The connection will be restarted.
  """
  @spec disconnect(pid) ::
    {:ok, pid} | {:error, term}
  defdelegate disconnect(pid),
    to: TM.Mercury.Reader

  @spec get_config_param(pid, key :: String.t) ::
    {:ok, term} | {:error, term}
  defdelegate get_config_param(pid, key),
    to: TM.Mercury.Reader

  @spec set_config_param(pid, key :: String.t, val :: any) ::
    {:ok, term} | {:error, term}
  defdelegate set_config_param(pid, key, val),
    to: TM.Mercury.Reader

  @spec read_sync(pid, ReadPlan.t) ::
    {:ok, term} | {:error, term}
  defdelegate read_sync(pid, read_plan),
    to: TM.Mercury.Reader

  @spec read_sync(pid, ReadPlan.t, timeout :: pos_integer) ::
    {:ok, term} | {:error, term}
  defdelegate read_sync(pid, read_plan, timeout),
    to: TM.Mercury.Reader

  @spec read_async_start(pid, ReadPlan.t) ::
    {:ok, term} | {:error, term}
  defdelegate read_async_start(pid, read_plan),
    to: TM.Mercury.Reader

  @spec read_async_stop(pid) ::
    {:ok, term} | {:error, term}
  defdelegate read_async_stop(pid),
    to: TM.Mercury.Reader
end
