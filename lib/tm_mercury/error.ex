defmodule TM.Mercury.Error do
  alias TM.Mercury.Message
  use TM.Mercury.Utils.Enum, [
    invalid_region: 0x10b
  ]

  defexception [status: nil, message: ""]

  def exception(%Message{status: status}) do
    message =
      case Enum.find(list(), fn({_k, v}) -> v == status end) do
        {k, _v} -> k
        _ -> :unhandled_exception
      end
    %TM.Mercury.Error{message: to_string(message), status: status}
  end
end
