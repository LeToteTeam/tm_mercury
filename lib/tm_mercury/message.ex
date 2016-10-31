defmodule TM.Mercury.Message do
  use Bitwise

  @crctable [
    0x0000, 0x1021, 0x2042, 0x3063,
    0x4084, 0x50a5, 0x60c6, 0x70e7,
    0x8108, 0x9129, 0xa14a, 0xb16b,
    0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
  ]

  def encode(opcode, data \\ <<>>) do
    len = <<byte_size(data) :: 8-unsigned-integer>>
    opcode = <<opcode :: 8-unsigned-integer>>
    header = <<0xFF>> <> len <> opcode
    crc = <<encode_crc(len <> opcode <> data) :: 16-unsigned-integer>>
    header <> data <> crc
  end

  defp encode_crc(_, _ \\ 0xFFFF)
  defp encode_crc(<<>>, crc), do: crc
  defp encode_crc(<<chunk :: 8-unsigned-integer, tail :: binary>>, crc) do

    <<crc1 :: 16-unsigned-integer>> = <<((crc <<< 4) ||| (chunk >>> 4)) :: 16-unsigned-integer>>
    <<crc2 :: 16-unsigned-integer>> = <<Enum.at(@crctable, (crc >>> 12)) :: 16-unsigned-integer>>
    crc = crc1 ^^^ crc2

    <<crc1 :: 16-unsigned-integer>> = <<((crc <<< 4) ||| (chunk &&& 0xf)) :: 16-unsigned-integer>>
    <<crc2 :: 16-unsigned-integer>> = <<Enum.at(@crctable, (crc >>> 12)) :: 16-unsigned-integer>>
    crc = crc1 ^^^ crc2
    encode_crc(tail, crc)
  end

end
