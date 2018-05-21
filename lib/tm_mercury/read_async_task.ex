defmodule TM.Mercury.ReadAsyncTask do
  require Logger

  alias TM.Mercury.Reader
  alias TM.Mercury.Utils

  def start_link(reader, {on_ms, off_ms}, read_plan, listener, rate_limit) do
    loop(%{
      status: :running,
      reader: reader,
      on: on_ms,
      off: off_ms,
      read_plan: read_plan,
      listener: listener,
      rate_limit: rate_limit,
      limited_tags: %{}
    })
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
        Logger.warn("Suspending asynchronous reads due to exit reason: #{inspect(reason)}")
        %{state | status: :suspended}
    end
  end

  # noop while suspended
  defp dispatch(%{status: :suspended} = state), do: state

  defp handle_read_response({:ok, []}, state) do
    state
  end

  defp handle_read_response({:ok, tags}, state) do
    {tags, state} =
      cond do
        is_number(state.rate_limit) && state.rate_limit > 0 ->
          apply_rate_limit(tags, state)

        true ->
          {tags, state}
      end

    send(state.listener, {:tm_mercury, :tags, tags})
    :ok = Reader.clear_tag_id_buffer(state.reader)
    state
  end

  defp handle_read_response({:error, :timeout}, state) do
    Logger.warn("Suspending asynchronous reads due to timeout")
    %{state | status: :suspended}
  end

  defp handle_read_response(other, state) do
    Logger.warn("Unexpected response during async dispatch to read_sync: #{inspect(other)}")
    state
  end

  defp apply_rate_limit(tags, state) do
    now = System.monotonic_time(:seconds)
    rl = state.rate_limit

    # Clear out any tags we've seen that are older than the rl seconds.
    limited_tags =
      Enum.filter(state.limited_tags, fn {_id, ts} ->
        age = now - ts
        age < rl
      end)
      |> Map.new()

    # Filter incoming tags so we send only those that we haven't seen in more than rl seconds.
    tags_out =
      Enum.reject(tags, fn tag ->
        epc = Utils.format_epc_as_string(tag)
        Map.has_key?(limited_tags, epc)
      end)

    {tags_out,
     %{
       state
       | limited_tags:
           Enum.into(tags_out, limited_tags, fn tag ->
             {Utils.format_epc_as_string(tag), now}
           end)
     }}
  end
end
