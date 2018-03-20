defmodule TM.Mercury.ReadAsyncTask do
  require Logger
  alias TM.Mercury.Reader

  def start_link(reader, {on_ms, off_ms}, read_plan, listener) do
    loop(%{status: :running,
           reader: reader,
           on: on_ms,
           off: off_ms,
           read_plan: read_plan,
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
        state.off -> loop(dispatch(state))
    end
  end

  defp dispatch(%{status: :running} = state) do
    try do
      Reader.read_sync(state.reader, state.on, state.read_plan)
      |> handle_read_response(state)
    catch
      :exit, reason ->
        Logger.warn("Suspending asynchronous reads due to exit reason: #{inspect reason}")
        %{state | status: :suspended}
    end
  end

  # noop while suspended
  defp dispatch(%{status: :suspended} = state), do: state

  defp handle_read_response({:ok, []}, state) do
    state
  end

  defp handle_read_response({:ok, tags}, state) do
    send(state.listener, {:tm_mercury, :tags, tags})
    :ok = Reader.clear_tag_id_buffer(state.reader)
    state
  end

  defp handle_read_response({:error, :timeout}, state) do
    Logger.warn("Suspending asynchronous reads due to timeout")
    %{state | status: :suspended}
  end

  defp handle_read_response(other, state) do
    Logger.warn("Unexpected response during async dispatch to read_sync: #{inspect other}")
    state
  end
end
