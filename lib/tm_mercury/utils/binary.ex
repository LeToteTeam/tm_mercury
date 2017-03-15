defmodule TM.Mercury.Utils.Binary do
  @moduledoc false
  use Bitwise

  defmacro uint8 do
    quote do: unsigned-8
  end

  defmacro uint16 do
    quote do: unsigned-16
  end

  defmacro uint32 do
    quote do: unsigned-32
  end

  defmacro binary(size) do
    quote do: binary-size(unquote(size))
  end

  defmacro binary(size, unit) do
    quote do: binary-size(unquote(size))-unit(unquote(unit))
  end

  def bytes_for_bits(bits) do
    ((bits - 1) >>> 3) + 1
  end

  def enum_flags_mask(list, enum_module) do
    Enum.map(list, fn(x) -> apply(enum_module, :"encode!", [x]) end)
    |> Enum.reduce(0, fn(x, acc) -> bor(x, acc) end)
  end

  def to_integer(true), do: 1
  def to_integer(false), do: 0

  def decode_boolean(<<1>>), do: true
  def decode_boolean(<<0>>), do: false
  def decode_uint32(<<value :: uint32>>), do: value
end
