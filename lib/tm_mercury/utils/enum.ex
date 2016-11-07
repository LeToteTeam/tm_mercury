defmodule TM.Mercury.Utils.Enum do
  defmacro __using__(list) do
    quote bind_quoted: [list: list] do
      @list list
      @keys Keyword.keys(list)

      def list do
        @list
      end

      for {k, v} <- @list do
        def unquote(k)() do
          unquote(v)
        end
      end

      def parse!(value) do
        {:ok, key} = parse(value)
        key
      end
      def parse(value) do
        case Enum.find(@list, fn({_k, v}) -> v == value end) do
          {k, _v} -> {:ok, k}
          _ -> {:error, :no_key}
        end
      end
    end
  end
end
