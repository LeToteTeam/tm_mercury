defmodule TM.Mercury.Protocol.Command do

  import TM.Mercury.Utils.Binary

  alias TM.Mercury.{Message, Reader}
  alias TM.Mercury.Protocol.{Opcode, Region}
  alias TM.Mercury.Reader.{Config, Stats, PowerMode}
  alias TM.Mercury.Tag.Protocol, as: TagProtocol

  def build(%Reader{} = rdr, [op_name|args]) do
    with {:ok, code} <- Opcode.encode(op_name),
      do: build_command(rdr, {op_name, code}, args)
  end

  defp build_command(_rdr, {:set_baud_rate, code}, [rate]) do
    {:ok, Message.encode(code, <<rate :: uint32>>)}
  end

  defp build_command(_rdr, {:get_reader_optional_params, code}, [key]) when is_atom(key) do
    with {:ok, encoded_key} <- Config.encode(key),
      do: {:ok, Message.encode(code, <<0x01, encoded_key>>)}
  end

  defp build_command(rdr, {:set_reader_optional_params, code}, [key, value]) when is_atom(key) do
    with {:ok, encoded_key} <- Config.encode(key),
         {:ok, encoded_value} <- encode_param(rdr, key, value),
      do: {:ok, Message.encode(code, <<0x01, encoded_key, encoded_value :: binary>>)}
  end

  defp build_command(_rdr, {:version, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:get_region, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(rdr, {:set_region, _code} = op, [region]) when is_atom(region) do
    with {:ok, region_code} <- Region.encode(region),
      do: build_command(rdr, op, [region_code])
  end
  defp build_command(_rdr, {:set_region, code}, [region]) when is_integer(region) do
    {:ok, Message.encode(code, <<region>>)}
  end

  # TODO: Collapse all these functions returning {:ok, Message.encode(code)} into a default catch-all handler
  # for simple commands that don't have any additional encoding requirements

  defp build_command(_rdr, {:get_temperature, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:get_current_program, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:get_power_mode, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:get_read_tx_power, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:set_read_tx_power, code}, [level]) do
    {:ok, Message.encode(code, <<level :: uint16>>)}
  end

  defp build_command(_rdr, {:get_tag_protocol, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:get_antenna_port, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:get_tag_id_buffer, code}, [flags]) do
    {:ok, Message.encode(code, <<flags :: uint16, 0x00>>)}
  end

  defp build_command(_rdr, {:clear_tag_id_buffer, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:set_power_mode, code}, [mode]) do
    with {:ok, encoded_mode} <- PowerMode.encode(mode),
      do: {:ok, Message.encode(code, <<encoded_mode>>)}
  end

  defp build_command(rdr, {:set_tag_protocol, _code} = op, [protocol]) when is_atom(protocol) do
    with {:ok, protocol_code} <- TagProtocol.encode(protocol),
      do: build_command(rdr, op, [protocol_code])
  end
  defp build_command(_rdr, {:set_tag_protocol, code}, [protocol]) when is_integer(protocol) do
    {:ok, Message.encode(code, <<protocol :: uint16>>)}
  end

  defp build_command(_rdr, {:set_antenna_port, code}, [{tx, rx}]) do
    {:ok, Message.encode(code, <<tx, rx>>)}
  end
  defp build_command(rdr, {:set_antenna_port, _code} = op, [port]) when is_integer(port) do
    build_command(rdr, op, [{port, port}])
  end
  defp build_command(_rdr, {:set_antenna_port, code}, [ports]) when is_list(ports) do
    ant = Enum.reduce(ports, <<>>, fn({tx, rx}, ant) ->
      ant <> <<tx, rx>>
    end)
    {:ok, Message.encode(code, <<2, ant :: binary>>)}
  end

  defp build_command(_rdr, {:get_reader_stats, code}, [option, flags]) do
    with {:ok, encoded_option} <- Stats.Option.encode(option),
         {:ok, encoded_flags}        <- Stats.Flag.encode(flags),
      do: {:ok, Message.encode(code, <<encoded_option, encoded_flags>>)}
  end

  defp build_command(rdr, {:reset_reader_stats, code}, [flags]) do
    build_command(rdr, {:get_reader_stats, code}, [:reset, flags])
  end

  defp build_command(_rdr, {:boot_bootloader, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:boot_firmware, code}, []) do
    {:ok, Message.encode(code)}
  end

  defp build_command(_rdr, {:read_tag_id_multiple, code}, [search_flags, timeout]) do
    search_mask = enum_flags_mask(search_flags, TM.Mercury.SearchFlag)
    {:ok, Message.encode(code, <<0x00, search_mask::16, timeout::16>>)}
  end

  defp build_command(_rdr, op, opts) do
    {:error, {:invalid_command, op, opts}}
  end

  defp encode_param(_rdr, :antenna_control_gpio, value),
    do: {:ok, <<value>>}

  defp encode_param(_rdr, :trigger_read_gpio, value),
    do: {:ok, <<value>>}

  defp encode_param(_rdr, :unique_by_antenna, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :unique_by_data, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :unique_by_protocol, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :extended_epc, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :safety_antenna_check, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :safety_temperature_check, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :record_highest_rssi, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :rssi_in_dbm, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :self_jammer_cancellation, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :enable_read_filter, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :send_crc, value),
    do: {:ok, <<to_integer(value)>>}

  defp encode_param(_rdr, :read_filter_timeout, value),
    do: {:ok, <<value :: 32-signed>>}

  defp encode_param(rdr, :transmit_power_save, value) do
    case rdr.model do
      :micro ->
        # Open loop power calibration
        <<(if value do 2 else 1 end)>>
      _ ->
        # Closed loop power calibration
        <<to_integer(value)>>
    end
  end

  defp encode_param(_rdr, key, _value),
    do: {:error, {:param_key_not_found, key}}
end
