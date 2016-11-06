defmodule TM.Mercury.Connection do
  use Connection

  alias TM.Mercury.Message

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

  def send(conn, data) do
    with :ok <- Connection.call(conn, {:send, data}),
         {:ok, %Message{} = msg} <- Connection.call(conn, {:recv, 5000}) do
      {:ok, msg.data}
    else
      {:error, error} -> {:error, error}
    end
  end

  # Connection API

  def init({device, opts}) do
    timeout = opts[:timeout]
    s = %{device: device, opts: opts, timeout: timeout, uart: nil}
    {:connect, :init, s}
  end

  def connect(_, %{uart: nil, device: device, opts: opts,
  timeout: _timeout} = s) do
    {:ok, pid} = Nerves.UART.start_link
    opts =
      opts
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
      {:ok, data} ->
        {:reply, {:ok, Message.decode(data)}, s}
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
