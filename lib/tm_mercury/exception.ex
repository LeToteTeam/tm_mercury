defmodule TM.Mercury.Exception do
  defexception [:message]

  def crc_error(crc, check) do
    %__MODULE__{message: """
      Invalid CRC
      Calculated: #{inspect check}
      Should be: #{inspect crc}
      """
    }
  end
end
