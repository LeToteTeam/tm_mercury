defmodule TM.Mercury.Error do
  alias TM.Mercury.Message
  use TM.Mercury.Utils.Enum, [
    # invalid number of arguments
    msg_wrong_number_of_data:                0x100,
    # command opcode not recognized.
    invalid_opcode:                          0x101,
    # command opcode recognized, but is not supported.
    unimplemented_opcode:                    0x102,
    # requested power setting is above the allowed maximum.
    msg_power_too_high:                      0x103,
    # requested frequency is outside the allowed range.
    msg_invalid_freq_received:               0x104,
    # parameter value is outside the allowed range.
    msg_invalid_parameter_value:             0x105,
    # requested power setting is below the allowed minimum.
    msg_power_too_low:                       0x106,
    # command not supported.
    unimplemented_feature:                   0x109,
    # requested serial speed is not supported.
    invalid_baud_rate:                       0x10a,
    # region is not supported.
    invalid_region:                          0x10b,
    #  license key code in invalid
    invalid_license_key:                     0x10c,
    # firmware is corrupt: checksum doesn't match content.
    bl_invalid_image_crc:                    0x200,
    # serial protocol status code for this exception.
    bl_invalid_app_end_addr:                 0x201,
    # internal reader error.  contact support.
    flash_bad_erase_password:                0x300,
    # internal reader error.  contact support.
    flash_bad_write_password:                0x301,
    # internal reader error.  contact support.
    flash_undefined_sector:                  0x302,
    # internal reader error.  contact support.
    flash_illegal_sector:                    0x303,
    # internal reader error.  contact support.
    flash_write_to_non_erased_area:          0x304,
    # internal reader error.  contact support.
    flash_write_to_illegal_sector:           0x305,
    # internal reader error.  contact support.
    flash_verify_failed:                     0x306,
    # reader was asked to find tags, but none were detected.
    no_tags_found:                           0x400,
    # rfid protocol has not been configured.
    no_protocol_defined:                     0x401,
    # requested rfid protocol is not recognized.
    invalid_protocol_specified:              0x402,
    # for write-then-lock commands, tag was successfully written, but lock failed.
    write_passed_lock_failed:                0x403,
    # tag data was requested, but could not be read.
    protocol_no_data_read:                   0x404,
    # reader not fully initialized and hasn't yet turned on its radio.  have you set region?
    afe_not_on:                              0x405,
    # write to tag failed.
    protocol_write_failed:                   0x406,
    # command is not supported in the current rfid protocol.
    not_implemented_for_this_protocol:       0x407,
    # data does not conform to protocol standards.
    protocol_invalid_write_data:             0x408,
    # requested data address is outside the valid range.
    protocol_invalid_address:                0x409,
    # unknown error during rfid operation.
    general_tag_error:                       0x40a,
    # read tag data was asked for more data than it supports.
    data_too_large:                          0x40b,
    # incorrect password was provided to kill tag.
    protocol_invalid_kill_password:          0x40c,
    # kill failed for unknown reason.
    protocol_kill_failed:                    0x40e,
    # internal reader error.  contact support.
    protocol_bit_decoding_failed:            0x40f,
    # internal reader error.  contact support.
    protocol_invalid_epc:                    0x410,
    # internal reader error.  contact support.
    protocol_invalid_num_data:               0x411,
    # internal reader error.  contact support.
    gen2_protocol_other_error:               0x420,
    # internal reader error.  contact support.
    gen2_protocol_memory_overrun_bad_pc:     0x423,
    # internal reader error.  contact support.
    gen2_prococol_memory_locked:             0x424,
    # authentication failed with specified key.
    gen2_protocol_v2_authen_failed:				0x425,
    #  untrace opearation failed.
    gen2_protocol_v2_untrace_failed:				0x426,
    # internal reader error.  contact support.
    gen2_protocol_insufficient_power:        0x42b,
    # internal reader error.  contact support.
    gen2_protocol_non_specific_error:        0x42f,
    # internal reader error.  contact support.
    gen2_protocol_unknown_error:             0x430,
    # a command was received to set a frequency outside the specified range.
    ahal_invalid_freq:                       0x500,
    # with lbt enabled an attempt was made to set the frequency to an occupied channel.
    ahal_channel_occupied:                   0x501,
    # checking antenna status while cw is on is not allowed.
    ahal_transmitter_on:                     0x502,
    #  antenna not detected during pre-transmit safety test.
    antenna_not_connected:                   0x503,
    # reader temperature outside safe range.
    temperature_exceed_limits:               0x504,
    #  excess power detected at transmitter port, usually due to antenna tuning mismatch.
    high_return_loss:                        0x505,
    invalid_antenna_config:                  0x507,
    # asked for more tags than were available in the buffer.
    tag_id_buffer_not_enough_tags_available: 0x600,
    # too many tags are in buffer.  remove some with get tag id buffer or clear tag id buffer.
    tag_id_buffer_full:                      0x601,
    # internal error -- reader is trying to insert a duplicate tag record.  contact support.
    tag_id_buffer_repeated_tag_id:           0x602,
    # asked for tags than a single transaction can handle.
    tag_id_buffer_num_tag_too_large:         0x603,
    # blocked response to get additional data from host.
    tag_id_buffer_auth_request:              0x604,
    # internal reader error.  contact support.
    system_unknown_error:                    0x7f00,
    # internal reader error.  contact support.
    tm_assert_failed:                        0x7f01,
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

  def exception(error) do
    status =
      case Enum.find(list(), fn({k, _v}) -> k == error end) do
        {k, _v} -> k
        _ -> :unknown_status_code
      end

    %TM.Mercury.Error{message: error, status: status}
  end
end
