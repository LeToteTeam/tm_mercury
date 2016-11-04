# TmMercury

A pure Elixir implementation of the ThingMagic Mercury SDK.
This SDK is for interfacing the the ThingMagic M6E Micro Module using
UART.

## Examples

```
iex(1)> {:ok, conn} = TM.Mercury.start_link "/dev/cu.usbmodem1411", speed: 115200, active: false
{:ok, #PID<0.175.0>}
iex(2)> TM.Mercury.version(conn)                                                 <<255, 0, 3, 29, 12>>
{:ok,
 %{bootloader_version: {18, 18, 19, 0}, firmware_date: 538251809,
   firmware_version: 17236773, hardware_date: 536870913,
   protocols: <<0, 0, 0, 244>>}}
```
