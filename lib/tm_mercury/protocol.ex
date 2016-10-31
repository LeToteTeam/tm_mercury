defmodule TM.Mercury.Protocol do
  @gen2_singulation_option [
    select_disabled:         0x00,
    select_on_epc:           0x01,
    select_on_tid:           0x02,
    select_on_user_mem:      0x03,
    select_on_addressed_epc: 0x04,
    use_password:            0x05,
    inverse_select_bit:      0x08,
    flag_metadata:           0x10,
    extended_data_length:    0x20,
    secure_read_data:        0x40
  ]

  @tag_id_option [
    none:   0x00,
    rewind: 0x01
  ]

  @model_hardware_id [
    m5e:         0x00,
    m5e_compact: 0x01,
    m5e_i:       0x02,
    m4e:         0x03,
    m6e:         0x18,
    m6e_prc:     0x19,
    micro:       0x20,
    m6e_nano:    0x30,
    unknown:     0xFF,
  ]
end
