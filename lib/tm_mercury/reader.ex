defmodule TM.Mercury.Reader do
  @timeout 5000

  alias TM.Mercury.Protocol.{Parameter, Opcode}
  alias TM.Mercury.Connection, as: Serial

  # Basic Commands

  def start_link(device, opts) do
    opts = defaults(opts)
    Connection.start_link(Serial, {device, opts})
  end

  def stop(reader) do
    Connection.call(reader, :close)
  end

  def get_param(reader, param) do
    Serial.send(reader, Parameter.get(param))
  end

  def set_param(reader, param, value) do
    Serial.send(reader, Parameter.set(param, value))
  end

  def read_sync(_reader) do

  end

  def read_async_start(_reader) do

  end

  def read_async_stop(_reader) do

  end

  # Extended Commands

  def send(reader, command) do
    Serial.send(reader, command)
  end

  def version(reader) do
    Serial.send(reader, Opcode.version)
  end

  def get_current_program(reader) do
    Serial.send(reader, Opcode.get_current_program)
  end

  def get_power_mode(reader) do
    Serial.send(reader, Opcode.get_power_mode)
  end

  def get_reader_optional_params(reader) do
    Serial.send(reader, Opcode.get_reader_optional_params)
  end

  ## Helpers
  defp defaults(opts) do
    Keyword.put_new(opts, :timeout, @timeout)
  end
end
