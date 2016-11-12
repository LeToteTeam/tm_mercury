defmodule TM.Mercury.Reader.Config do
  use TM.Mercury.Utils.Enum, [
    #  Key tag buffer records off of antenna ID as well as EPC;
    #  i.e., keep separate records for the same EPC read on different antennas
    #  0: Disable -- Different antenna overwrites previous record.
    #  1: Enable -- Different Antenna creates a new record.
    unique_by_antenna:              0x00,

    # Run transmitter in lower-performance, power-saving mode.
    # 0: Disable -- Higher transmitter bias for improved reader sensitivity
    # 1: Enable -- Lower transmitter bias sacrifices sensitivity for power consumption
    transmit_power_save:            0x01,

    # Support 496-bit EPCs (vs normal max 96 bits)
    # 0: Disable (max max EPC length = 96)
    # 1: Enable 496-bit EPCs
    extended_epc:                   0x02,

    # Configure GPOs to drive antenna switch.
    # 0: No switch
    # 1: Switch on GPO1
    # 2: Switch on GPO2
    # 3: Switch on GPO1,GPO2
    antenna_control_gpio:           0x03,

    # Refuse to transmit if antenna is not detected
    safety_antenna_check:           0x04,

    # Refuse to transmit if overtemperature condition detected
    safety_temperature_check:       0x05,

    # If tag read duplicates an existing tag buffer record (key is the same),
    # update the record's timestamp if incoming read has higher RSSI reading.
    # 0: Keep timestamp of record's first read
    # 1: Keep timestamp of read with highest RSSI
    record_highest_rssi:            0x06,

    # Key tag buffer records off tag data as well as EPC;
    # i.e., keep separate records for the same EPC read with different data
    # 0: Disable -- Different data overwrites previous record.
    # 1: Enable -- Different data creates new record.
    unique_by_data:                 0x08,

    # Whether RSSI values are reported in dBm, as opposed to
    # arbitrary uncalibrated units.
    rssi_in_dbm:                    0x09,

    # Self jammer cancellation
    # User can enable/disable through level2 API
    self_jammer_cancellation:       0x0A,

    # Key tag buffer records off of protocol as well as EPC;
    # i.e., keep separate records for the same EPC read on different protocols
    # 0: Disable -- Different protocol overwrites previous record.
    # 1: Enable -- Different protocol creates a new record.
    unique_by_protocol:             0x0B,

    # Enable read filtering
    enable_read_filter:             0x0C,

    # Tag buffer entry timeout
    read_filter_timeout:            0x0D,

    # Transport (bus) type
    current_msg_transport:          0x0E,

    # Enable the CRC calculation
    send_crc:                       0x1B,

    # General category of finished reader into which module is integrated; e.g.,
    # 0: bare module
    # 1: In-vehicle Reader (e.g., Tool Link, Vega)
    # 2: USB Reader
    product_group_id:               0x12,

    # Product ID (Group ID 0x0002 ) information
    # 0x0001 :M5e-C USB reader
    # 0x0002 :Backback NA antenna
    # 0x0003 :Backback EU antenna
    product_id:                     0x13,

    # Configure GPIs to drive trigger read.
    # 0: No switch
    # 1: Switch on GPI1
    # 2: Switch on GPI2
    # 3: Switch on GPI3 (if supported)
    # 4: Switch on GOI4 (if supported)
    trigger_read_gpio:              0x1E,
  ]

  alias TM.Mercury.Reader.Config.Transport
  import TM.Mercury.Utils.Binary

  def decode_data(:current_msg_transport, <<transport>>) do
    Transport.decode!(transport)
  end

  def decode_data(:enable_read_filter, data),
    do: decode_boolean(data)

  def decode_data(:read_filter_timeout, data),
    do: decode_uint32(data)

  defp decode_boolean(<<1>>), do: true
  defp decode_boolean(<<0>>), do: false

  defp decode_uint32(<<value :: uint32>>), do: value
end
