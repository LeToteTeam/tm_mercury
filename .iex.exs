IEx.configure(inspect: [limit: :infinity])

alias TM.Mercury.Utils
alias TM.Mercury.Protocol.{Command, Opcode, Parameter, Region}
alias TM.Mercury.{Reader, Reader.Config, ReadPlan, SimpleReadPlan, StopTriggerReadPlan, Tag, Tag.Protocol, Transport}

defmodule Helpers do
  require Logger

  def dump_erl(beam_file_path) do
    {:ok , {_, [{:abstract_code, {_, ast}}]}} = :beam_lib.chunks(to_charlist(beam_file_path), [:abstract_code])
    IO.puts :erl_prettypr.format(:erl_syntax.form_list(ast))
  end

  def print_tags_sync({:ok, tags}) do
    now = DateTime.utc_now |> to_string
    Enum.each(tags, fn t -> IO.puts "#{now} #{format_epc(t)} #{t[:rssi]}" end)
  end

  def print_tags_sync({:tm_mercury, :tags, tags}) do
    print_tags_sync({:ok, tags})
  end

  def format_epc(tag) do
    Utils.to_hex_string(tag[:epc]) |> String.replace(" ", "")
  end

  def start_async_test(device \\ "/dev/ttyACM0") do
    Logger.configure(level: :info)
    {:ok, reader} = Reader.start_link(device: device)
    {:ok, listener} = Task.start_link(&print_tags_async/0)
    Reader.read_async_start(reader, listener)
    reader
  end

  def print_tags_async do
    receive do
      msg ->
        print_tags_sync(msg)
    end
    print_tags_async()
  end
end
