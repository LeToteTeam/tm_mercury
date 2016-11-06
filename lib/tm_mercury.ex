defmodule TM.Mercury do
  defdelegate start_link(device, opts),         to: TM.Mercury.Reader
  defdelegate stop(reader),                     to: TM.Mercury.Reader

  defdelegate get_param(reader, param),         to: TM.Mercury.Reader
  defdelegate set_param(reader, param, value),  to: TM.Mercury.Reader

  defdelegate read_sync(reader),                to: TM.Mercury.Reader
  defdelegate read_async_start(reader),         to: TM.Mercury.Reader
  defdelegate read_async_stop(reader),          to: TM.Mercury.Reader
end
