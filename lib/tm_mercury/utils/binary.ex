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
end
