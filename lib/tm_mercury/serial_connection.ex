defmodule TM.Mercury.SerialConnection do
  use Connection
  alias TM.Mercury.Message

  @flush_bytes String.duplicate(<<0xFF>>, 64)

  # Public API

  def start_link(device, opts, timeout \\ 5000) do
    Connection.start_link(__MODULE__, {device, opts, timeout})
  end

  def send(conn, data) do
    message = Message.encode(data)
    Connection.call(conn, {:send, message})
  end

  def recv(conn, timeout \\ 3000) do
    Connection.call(conn, {:recv, timeout})
  end

  def close(conn), do: Connection.call(conn, :close)

  # Connection API

  def init({device, opts, timeout}) do
    s = %{device: device, opts: opts, timeout: timeout, uart: nil}
    {:connect, :init, s}
  end

  def connect(_, %{uart: nil, device: device, opts: opts,
  timeout: _timeout} = s) do
    {:ok, pid} = Nerves.UART.start_link
    case Nerves.UART.open(pid, device, opts) do
      :ok -> {:ok, %{s | uart: pid}}
      {:error, _} -> {:backoff, 1000, s}
    end
  end

  def disconnect(info, %{uart: pid} = s) do
    :ok = Nerves.UART.close(pid)
    case info do
      {:close, from} ->
        Connection.reply(from, :ok)
      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])
      {:error, reason} ->
        :error_logger.format("Connection error: ~s~n", [reason])
    end
    {:connect, :reconnect, %{s | uart: nil}}
  end

  def handle_call(_, _, %{uart: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:send, data}, _, %{uart: pid} = s) do
    case Nerves.UART.write(pid, data) do
      :ok ->
        {:reply, :ok, s}
      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call({:recv, timeout}, _, %{uart: pid} = s) do
    case Nerves.UART.read(pid, timeout) do
      {:ok, _} = ok ->
        {:reply, ok, s}
      {:error, :timeout} = timeout ->
        {:reply, timeout, s}
      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end
end
