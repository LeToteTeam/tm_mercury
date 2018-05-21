defmodule TM.Mercury.Tag.Type do
  def parse({data, result}) do
    case result[:protocol] do
      :gen2 -> TM.Mercury.Tag.Type.Gen2.parse({data, result})
      protocol -> {:error, "Parsing not implemented for protocol: #{inspect(protocol)}"}
    end
  end
end
