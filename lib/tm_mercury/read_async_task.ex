defmodule TM.Mercury.ReadAsyncTask do
  require Logger
  alias TM.Mercury.Reader

  def start_link(reader, read_plan, listener) do
    loop(%{status: :running,
           read_plan: read_plan,
           reader: reader,
           listener: listener})
  end

  defp loop(state) do
    receive do
      {:stop, from} ->
        send(from, :stopped)
        {:shutdown, :stopped}
      :suspend ->
        loop(%{state | status: :suspended})
      :resume ->
        loop(%{state | status: :running})
      after
        100 -> loop(dispatch(state))
    end
  end

  defp dispatch(%{status: :running} = state) do
    try do
      case Reader.read_sync(state.reader, state.read_plan) do
        {:ok, tags} when length(tags) == 0 -> state
        {:ok, tags} when length(tags) > 0 ->
          send(state.listener, {:tm_mercury, :tags, tags})
          :ok = Reader.clear_tag_id_buffer(state.reader)
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
