defmodule TM.Mercury.Utils do

  def to_hex_list(x) when is_list(x) do
    Enum.map x, &( Base.encode16(<<&1>>))
  end

  def to_hex_list(x) when is_binary(x)  do
    :erlang.binary_to_list(x)
      |> to_hex_list
  end

  def to_hex_string(x) when is_binary(x) do
    to_hex_list(x)
      |> to_hex_string
  end

  def to_hex_string(x) when is_list(x) do
    Enum.join x, " "
  end

end
