# TmMercury

A pure Elixir implementation of the ThingMagic Mercury SDK.
This SDK is for interfacing the the ThingMagic M6E Micro Module using
UART.

## Examples

```
iex(1)> {:ok, conn} = TM.Mercury.Reader.start_link device: "/dev/cu.usbmodem1411", speed: 115200
{:ok, #PID<0.175.0>}
iex(2)> TM.Mercury.Reader.get_version(conn)
{:ok,
 %TM.Mercury.Reader.Version{bootloader: <<18, 18, 19, 0>>,
  firmware: <<1, 7, 3, 37>>, firmware_date: <<32, 21, 18, 33>>,
  hardware: <<32, 0, 0, 1>>, model: :micro, software: nil,
  supported_protocols: [:iso180006b, :gen2, :iso180006b_ucode, :ipx64,
   :ipx256]}}
```
