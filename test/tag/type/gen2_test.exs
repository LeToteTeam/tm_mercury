defmodule TM.Mercury.Tag.Type.Gen2Test do
  use ExUnit.Case

  alias TM.Mercury.Tag.Type.Gen2

  test "EPC and CRC are decoded correctly for next tag with no tail" do
	  read = <<0, 128, 48, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 208, 178, 68>> 
    tail = <<>>

    assert Gen2.parse({read, []}) == {tail, [epc_crc: 45636, epc: <<193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 208>>]}
  end

  test "EPC and CRC are decoded correctly for next tag with tail containing 1 tag" do
    read = <<0, 128, 48, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 214, 210,
             130, 1, 195, 17, 14, 22, 114, 0, 0, 0, 69, 0, 151, 5, 0, 0,
             0, 0, 128, 48, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 208, 178, 68>>
    tail = <<1, 195, 17, 14, 22, 114, 0, 0, 0, 69, 0, 151, 5, 0, 0, 0, 0, 128,
             48, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 208, 178, 68>>

    assert Gen2.parse({read, []}) == {tail, [epc_crc: 53890, epc: <<193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 214>>]}
  end

  test "EPC and CRC are decoded correctly for next tag with tail containing 2 tags" do
    read = <<0, 128, 48, 0, 226, 0, 125, 48, 26, 168, 136, 113, 79,
             87, 162, 33, 11, 18, 1, 207, 17, 14, 22, 114, 0, 0, 0,
             50, 0, 101, 5, 0, 0, 0, 0, 128, 48, 0, 193, 0, 0, 0, 0,
             0, 0, 0, 0, 0, 0, 214, 210, 130, 1, 195, 17, 14, 22, 114,
             0, 0, 0, 69, 0, 151, 5, 0, 0, 0, 0, 128, 48, 0, 193, 0, 0,
             0, 0, 0, 0, 0, 0, 0, 0, 208, 178, 68>>
    tail = <<1, 207, 17, 14, 22, 114, 0, 0, 0, 50, 0, 101, 5, 0, 0, 0, 0, 128, 48, 0, 193,
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 214, 210, 130, 1, 195, 17, 14, 22, 114, 0, 0,
             0, 69, 0, 151, 5, 0, 0, 0, 0, 128, 48, 0, 193, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             208, 178, 68>>

    assert Gen2.parse({read, []}) == {tail, [epc_crc: 2834, epc: <<226, 0, 125, 48, 26, 168, 136, 113, 79, 87, 162, 33>>]}
  end
end
