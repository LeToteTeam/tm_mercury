defmodule TM.Mercury.Protocol.Parameter do
  alias TM.Mercury.Protocol.Opcode
  alias TM.Mercury.Message

  def get(:region_id) do
    Message.encode(Opcode.get_region())
  end

  def get(_param) do
    {:error, :undefined_param}
  end

  def set(:read_plan, _value) do
  end

  def set(:region_id, region) when is_atom(region) do
    region_id = apply(TM.Mercury.Protocol.Region, region, [])
    set(:region_id, region_id)
  end

  def set(:region_id, region_id) do
    Message.encode(Opcode.set_region(), <<region_id>>)
  end

  def set(_param, _val) do
    {:error, :undefined_param}
  end
end
