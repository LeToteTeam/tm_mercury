defmodule TM.Mercury.ReadAsyncTask do
  require Logger
  alias TM.Mercury.Reader

  def start_link(reader_pid, callback, plan) do
    loop(%{status: :running,
           reader: reader_pid,
           cb: callback,
           plan: plan,
           tag_count: 0})
  end

  defp loop(state) do
    receive do
      :suspend ->
        loop(%{state | status: :suspended})
      :resume ->
        loop(%{state | status: :running})
      {:stop, from} ->
        send(from, :stopped)
        {:shutdown, :stopped}
      after
        100 -> loop(dispatch(state))
    end
  end

  defp dispatch(%{status: :running, reader: rdr, cb: cb, plan: plan} = state) do
    try do
      case Reader.read_sync(rdr, plan) do
        {:ok, tags} when length(tags) == 0 -> state
        {:ok, tags} when length(tags) > 0 ->
          send(cb, {:tm_mercury, :tags, tags})
          :ok = Reader.clear_tag_id_buffer(rdr)
          state
        {:error, :timeout} ->
          Logger.warn("Suspending asynchronous reads due to timeout")
          %{state | status: :suspended}
      end
    catch
      :exit, reason ->
        Logger.warn("Suspending asynchronous reads due to exit reason: #{inspect reason}")
        %{state | status: :suspended}
    end
  end

  # noop while suspended
  defp dispatch(%{status: :suspended} = state), do: state
end
