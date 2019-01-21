defmodule TM.Mercury do
  @spec enumerate() :: map | {:error, term}
  defdelegate enumerate(), to: Circuits.UART
end
