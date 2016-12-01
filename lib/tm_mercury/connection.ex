defmodule TM.Mercury.Connection do
  use Connection

  alias TM.Mercury.Message

  @timeout 5000

  @flush_bytes String.duplicate(<<0xFF>>, 64)

  @gen2_singulation_option [
    select_disabled:         0x00,
    select_on_epc:           0x01,
    select_on_tid:           0x02,
    select_on_user_mem:      0x03,
    select_on_addressed_epc: 0x04,
    use_password:            0x05,
    inverse_select_bit:      0x08,
    flag_metadata:           0x10,
    extended_data_length:    0x20,
    secure_read_data:        0x40
  ]

  @tag_id_option [
    none:   0x00,
    rewind: 0x01
  ]

  @model_hardware_id [
    m5e:         0x00,
    m5e_compact: 0x01,
    m5e_i:       0x02,
    m4e:         0x03,
    m6e:         0x18,
    m6e_prc:     0x19,
    micro:       0x20,
    m6e_nano:    0x30,
    unknown:     0xFF,
  ]

  def send_data(conn, data, opts \\ []) do
    opts = defaults(opts)
    timeout = opts[:timeout]

    case Connection.call(conn, {:send, data}) do
      :ok ->
        case Connection.call(conn, {:recv, @timeout}) do
          :ok ->                      :ok
          {:ok, %Message{} = msg} ->  {:ok, msg.data}
          {:error, error} ->          {:error, error}
        end
      {:error, error} -> {:error, error}
    end
  end

  def start_async(conn, callback \\ nil) do
    callback = callback || self()
    Connection.call(conn, {:start_async, callback})
  end

  def stop_async(conn) do
    Connection.call(conn, :stop_async)
  end

  # Connection API

  def init({device, opts}) do
    timeout = opts[:timeout]
    s = %{
      device: device,
      opts: opts,
      timeout: timeout,
      uart: nil,
      status: :sync,
      callback: nil
    }
    {:connect, :init, s}
  end

  def connect(_, %{uart: nil, device: device, opts: opts,
  timeout: _timeout} = s) do
    {:ok, pid} = Nerves.UART.start_link
    opts =
      opts
      |> Keyword.put(:active, false)
      |> Keyword.put(:framing, {TM.Mercury.Message.Framing, []})
      |> Keyword.put(:rx_framing_timeout, 500)
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

  def handle_call(:stop_async, _, %{uart: pid} = s) do
    :ok = Nerves.UART.configure pid, active: false
    {:reply, :ok, %{s | status: :sync, callback: nil}}
  end

  def handle_call({:start_async, callback}, _, %{uart: pid} = s) do
    :ok = Nerves.UART.configure pid, active: true
    {:reply, :ok, %{s | status: :async, callback: callback}}
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
    recv(Nerves.UART.read(pid, timeout), s)
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  def handle_info({:nerves_uart, _, data}, %{status: :async} = s) do
    s =
      case recv({:ok, data}, s) do
        {:reply, {:error, :no_tags_found}, s} ->
          s
        {:reply, msg, s} ->
          send s.callback, {:tm_mercury, :message, data}
          s
        {:disconnect, error, s} ->
          send s.callback, {:tm_mercury, :error, error}
          s
      end

    {:noreply, s}
  end

  def handle_info(data, %{status: :sync} = s) do
    IO.puts "Handle Info: :sync"
    IO.inspect data
    {:noreply, s}
  end

  defp defaults(opts) do
    opts
    |> Keyword.put_new(:timeout, @timeout)
    |> Keyword.put_new(:mode, :sync)
  end

  defp recv({:ok, %{status: 0, length: 0} = msg}, s) do
    {:reply, :ok, s}
  end

  defp recv({:ok, %{status: 0} = msg}, s) do
      {:reply, {:ok, Message.decode(msg)}, s}
  end

  defp recv({:ok, %{status: status}}, s) do
    reason =
      case TM.Mercury.Error.decode(status) do
        {:ok, reason} -> reason
        _ -> status
      end
    {:reply, {:error, reason}, s}
  end

  defp recv({:error, :timeout} = timeout, s) do
    {:reply, timeout, s}
  end

  defp recv({:error, _} = error, s) do
    {:disconnect, error, error, s}
  end

end
