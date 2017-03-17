defmodule TM.Mercury do
  @spec enumerate() :: map | {:error, term}
  defdelegate enumerate(), to: Nerves.UART
end
