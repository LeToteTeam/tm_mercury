IEx.configure(inspect: [limit: :infinity])

alias TM.Mercury.Utils
alias TM.Mercury.Protocol.{Command, Opcode, Parameter, Region}
alias TM.Mercury.{Reader, Reader.Config, ReadPlan, Tag, Tag.Protocol, Transport}

defmodule Helpers do
  def dump_erl(beam_file_path) do
    {:ok , {_, [{:abstract_code, {_, ast}}]}} = :beam_lib.chunks(to_charlist(beam_file_path), [:abstract_code])
    IO.puts :erl_prettypr.format(:erl_syntax.form_list(ast))
  end
end
