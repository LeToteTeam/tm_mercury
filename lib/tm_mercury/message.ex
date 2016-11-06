defmodule TM.Mercury.Message do
  alias TM.Mercury.Protocol.Opcode
  import TM.Mercury.Utils.Binary

  alias __MODULE__

  defstruct [length: nil, opcode: nil, status: nil, data: nil, crc: nil]

  def encode(opcode, data \\ <<>>) do
    <<opcode, data :: binary>>
  end

  def decode(%Message{opcode: opcode} = msg) when is_integer(opcode) do
    Map.put(msg, :opcode, Opcode.parse!(opcode))
    |> IO.inspect
    |> decode
  end

  def decode(%Message{opcode: :version} = msg) do
    <<bootloader_vsn1 :: uint8,
      bootloader_vsn2 :: uint8,
      bootloader_vsn3 :: uint8,
      bootloader_vsn4 :: uint8,
      hardware_date :: uint32,
      firmware_date :: uint32,
      firmware_vsn :: uint32,
      protocols :: binary(4)>> = msg.data

    data = %{
      bootloader_version: {bootloader_vsn1, bootloader_vsn2, bootloader_vsn3, bootloader_vsn4},
      hardware_date: hardware_date,
      firmware_date: firmware_date,
      firmware_version: firmware_vsn,
      protocols: protocols
    }
    Map.put(msg, :data, data)
  end

  def decode(%Message{opcode: :get_power_mode} = msg) do
    <<mode :: uint8>> = msg.data
    mode
  end

  def decode(%Message{opcode: :get_region} = msg) do
    IO.inspect msg
    <<region :: uint8>> = msg.data
    data = TM.Mercury.Protocol.Region.parse!(region)
    Map.put(msg, :data, data)
  end

  def decode(msg), do: msg
end
