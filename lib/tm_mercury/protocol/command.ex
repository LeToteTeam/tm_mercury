defmodule TM.Mercury.Protocol.Command do

  import TM.Mercury.Utils.Binary

  alias TM.Mercury.Message
  alias TM.Mercury.Protocol.{Opcode, Region}
  alias TM.Mercury.Reader.{Config, Stats, PowerMode}

  def build(op_name, opts \\ []) do
    with {:ok, code} <- Opcode.encode(op_name),
      do: build_command({op_name, code}, opts)
  end

  defp build_command({:set_baud_rate, code}, [rate: rate]) do
    {:ok, Message.encode(code, <<rate :: uint32>>)}
  end

  defp build_command({:get_reader_optional_params, code}, [param: param_name]) do
    with {:ok, param} <- Config.encode(param_name),
      do: {:ok, Message.encode(code, <<0x01, param>>)}
  end

  defp build_command({:version, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:get_region, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:set_region, _code} = op, [region: region]) when is_atom(region) do
    with {:ok, region_code} <- Region.encode(region),
      do: build_command(op, region: region_code)
  end
  defp build_command({:set_region, code}, [region: region]) when is_integer(region) do
    {:ok, Message.encode(code, <<region>>)}
  end

  defp build_command({:get_current_program, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:get_power_mode, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:get_tag_protocol, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:get_antenna_port, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:get_tag_id_buffer, code}, [metadata_flags: flags]) do
    {:ok, Message.encode(code, <<flags :: uint16, 0x00>>)}
  end

  defp build_command({:clear_tag_id_buffer, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:set_power_mode, code}, [mode: mode]) do
    with {:ok, mode} <- PowerMode.encode(mode),
      do: {:ok, Message.encode(code, mode)}
  end

  defp build_command({:set_tag_protocol, code}, [protocol: protocol]) do
    {:ok, Message.encode(code, <<protocol :: uint16>>)}
  end

  defp build_command({:set_antenna_port, code}, [ports: {tx, rx}]) do
    {:ok, Message.encode(code, <<tx, rx>>)}
  end
  defp build_command({:set_antenna_port, _code} = op, [ports: port]) when is_integer(port) do
    build_command(op, ports: {port, port})
  end
  defp build_command({:set_antenna_port, code}, [ports: ports]) when is_list(ports) do
    ant = Enum.reduce(ports, <<>>, fn({tx, rx}, ant) ->
      ant <> <<tx, rx>>
    end)
    {:ok, Message.encode(code, <<2, ant :: binary>>)}
  end

  @doc """
  Build the command for get_reader_stats opcode.
  The order of parameters in the keyword list is important.
  """
  defp build_command({:get_reader_stats, code}, [option: option, flags: flags]) do
    with {:ok, encoded_flags} <- Stats.Flag.encode(flags),
         {:ok, option}        <- Stats.Option.encode(option),
      do: {:ok, Message.encode(code, <<option, encoded_flags>>)}
  end

  defp build_command({:reset_reader_stats, code}, [flags: flags]) do
    build_command({:get_reader_stats, code}, flags: flags, option: :reset)
  end

  defp build_command({:boot_bootloader, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command({:boot_firmware, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(op, opts) do
    {:error, {:invalid_command, op, opts}}
  end
end
