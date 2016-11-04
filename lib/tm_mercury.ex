defmodule TM.Mercury do
  @timeout 5000

  alias TM.Mercury.{Protocol, Opcode}

  def start_link(device, opts) do
    opts = defaults(opts)
    Connection.start_link(Protocol, {device, opts})
  end

  def stop(conn) do
    Connection.call(conn, :close)
  end

  def version(conn) do
    Protocol.send(conn, Opcode.version)
  end

  def get_current_program(conn) do
    Protocol.send(conn, Opcode.get_current_program)
  end

  def get_power_mode(conn) do
    Protocol.send(conn, Opcode.get_power_mode)
  end

  def get_reader_optional_params(conn) do
    Protocol.send(conn, Opcode.get_reader_optional_params)
  end

  ## Helpers
  defp defaults(opts) do
    Keyword.put_new(opts, :timeout, @timeout)
  end
end
