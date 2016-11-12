defmodule TM.Mercury.Message.Framing do
  use Bitwise
  alias TM.Mercury.Message
  import TM.Mercury.Utils.Binary

  @behaviour Nerves.UART.Framing

  @crctable [
    0x0000, 0x1021, 0x2042, 0x3063,
    0x4084, 0x50a5, 0x60c6, 0x70e7,
    0x8108, 0x9129, 0xa14a, 0xb16b,
    0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
  ]

  @max_packet_size 256

  def init(_args) do
    {:ok, %{
      buffer: "",
      current_message: nil
    }}
  end

  def add_framing(data, state) do
    len = byte_size(data) - 1
    packet = <<len :: uint8, data :: binary>>
    message = <<0xFF>> <> packet <> crc(packet)
    IO.inspect message
    {:ok, message, state}
  end

  def remove_framing(data, %{buffer: buffer} = state) do
    {buffer, current_message, messages} = process_data(buffer <> data, nil, [])
    state = %{state | buffer: buffer, current_message: current_message}
    rc = if buffer_empty?(state), do: :ok, else: :in_frame
    {rc, messages, state}
  end

  def frame_timeout(state) do
    partial = {:partial, state.buffer}
    {:ok, [partial], %{state | buffer: ""}}
  end

  def flush(direction, state) when direction == :receive or direction == :both do
    %{state | buffer: ""}
  end
  def flush(_direction, state) do
    state
  end

  def buffer_empty?(%{buffer: ""}),  do: true
  def buffer_empty?(%{buffer: _}),    do: false


  defp process_data("", nil, messages) do
    {"", nil, messages}
  end
  defp process_data(data, %{length: len} = message, messages)
    when byte_size(data) < len do
    {data, message, messages}
  end
  defp process_data(<<0xFF, len :: uint8, tail :: binary>>, nil, messages) do
    message = %Message{length: len}
    process_data(tail, message, messages)
  end

  defp process_data(data, %{length: len} = message, messages) do
    case data do
      <<opcode, status :: uint16, data :: binary(len),
        crc :: binary(2), tail :: binary>> ->
          packet = <<len, opcode, status :: uint16, data :: binary>>
        calculated_crc = crc(packet)
        if crc != calculated_crc do
          # TODO Decide if you should raise or not
          IO.inspect "INVALID CRC"
        end
        IO.inspect <<0xFF, len, opcode, status :: uint16, data :: binary(len),
          crc :: binary(2)>>
        message = %{message | opcode: opcode, status: status, data: data, crc: crc}
        process_data(tail, nil, [message | messages])
      data ->
        {data, message, messages}
    end
  end

  def crc(_, _ \\ 0xFFFF)
  def crc(<<>>, crc), do: <<crc :: uint16>>
  def crc(<<chunk :: 8-unsigned-integer, tail :: binary>>, crc) do

    <<crc1 :: uint16>> = <<((crc <<< 4) ||| (chunk >>> 4)) :: uint16>>
    <<crc2 :: uint16>> = <<Enum.at(@crctable, (crc >>> 12)) :: uint16>>
    crc = crc1 ^^^ crc2

    <<crc1 :: uint16>> = <<((crc <<< 4) ||| (chunk &&& 0xf)) :: uint16>>
    <<crc2 :: uint16>> = <<Enum.at(@crctable, (crc >>> 12)) :: uint16>>
    crc = crc1 ^^^ crc2
    crc(tail, crc)
  end
end
