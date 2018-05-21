defmodule TM.Mercury.Transport do
  require Logger

  use Connection

  alias TM.Mercury.Message

  @defaults [
    speed: 115_200,
    active: true,
    timeout: 5000,
    framing: {TM.Mercury.Message.Framing, []},
    rx_framing_timeout: 500
  ]

  def send_data(conn, data) do
    case Connection.call(conn, {:send, data}) do
      :ok -> :ok
      {:ok, msg} -> {:ok, msg.data}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Change the baud rate on the underlying UART connection.
  Note: this might not be supported by Nerves.UART yet, but it still accepts the call.
  """
  def set_speed(conn, speed) do
    Connection.call(conn, {:set_speed, speed})
  end

  def open(conn) do
    Connection.call(conn, :open)
  end

  def close(conn) do
    Connection.call(conn, :close)
  end

  def reopen(conn) do
    _ = close(conn)
    Process.sleep(200)
    open(conn)
  end

  # Connection API

  def init({device, owner, opts}) do
    opts = Keyword.merge(@defaults, opts)
    {:ok, uart} = Nerves.UART.start_link()

    s = %{
      device: device,
      opts: opts,
      uart: uart,
      owner: owner,
      connection: :disconnected,
      callback: nil
    }

    {:connect, :init, s}
  end

  def connect(info, %{uart: uart, device: device, opts: opts} = s) do
    Logger.info("Connecting to RFID reader at #{device}")

    case info do
      {_, from} -> Connection.reply(from, :ok)
      _ -> :noop
    end

    case Nerves.UART.open(uart, device, opts) do
      :ok ->
        send(s.owner, :connected)
        {:ok, %{s | connection: :connected}}

      {:error, _} ->
        {:backoff, 1000, s}
    end
  end

  def disconnect(info, %{uart: pid, device: device} = s) do
    Logger.info("Disconnecting from RFID reader at #{device}")
    _ = Nerves.UART.drain(pid)
    :ok = Nerves.UART.close(pid)

    s = %{s | connection: :disconnected}

    send(s.owner, :disconnected)

    case info do
      {:close, from} ->
        # Close and expect caller to re-open later
        Connection.reply(from, :ok)
        {:noconnect, s}

      {:error, :closed} ->
        Logger.error("RFID UART connection closed")
        {:connect, :reconnect, s}

      {:error, reason} ->
        Logger.error("RFID UART error: #{inspect(reason)}")
        {:connect, :reconnect, s}
    end
  end

  def handle_call(_, _, %{uart: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:set_speed, speed}, _, %{uart: pid, opts: opts} = s) do
    :ok = Nerves.UART.configure(pid, speed: speed)
    new_state = %{s | opts: Keyword.put(opts, :speed, speed)}
    {:reply, :ok, new_state}
  end

  def handle_call({:send, data}, from, %{uart: pid} = s) do
    case Nerves.UART.write(pid, data) do
      :ok ->
        {:noreply, %{s | callback: from}}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:open, from, s) do
    {:connect, {:open, from}, s}
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  def handle_info({:nerves_uart, _, data}, %{connection: :connected} = s) do
    case recv(data) do
      {:reply, msg} ->
        GenServer.reply(s.callback, msg)
        {:noreply, s}

      {:disconnect, error} ->
        {:disconnect, error, s}
    end
  end

  def handle_info(_, s) do
    {:noreply, s}
  end

  defp recv(%{status: 0, length: 0}) do
    {:reply, :ok}
  end

  defp recv(%{status: 0} = msg) do
    {:reply, {:ok, Message.decode(msg)}}
  end

  defp recv(%{status: status}) do
    reason =
      case TM.Mercury.Error.decode(status) do
        {:ok, reason} -> reason
        _ -> status
      end

    {:reply, {:error, reason}}
  end

  defp recv({:error, :timeout} = timeout) do
    {:reply, timeout}
  end

  defp recv({:error, _} = error) do
    {:disconnect, error}
  end
end
