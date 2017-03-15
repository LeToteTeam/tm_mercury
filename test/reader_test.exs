defmodule TM.Mercury.ReaderTest do
  use ExUnit.Case, async: false
  doctest TM.Mercury.Reader

  alias TM.Mercury.{Reader, ReadPlan}

  setup_all do
    {:ok, pid} = Reader.start_link(device: "/dev/ttyACM0", speed: 115200)
    {:ok, %{pid: pid}}
  end

  test "Reader returns a tag synchronously", context do
    rp = %ReadPlan{antennas: 1, tag_protocol: :gen2}
    {:ok, [tag|_]} = Reader.read_sync(context.pid, rp)
    assert tag[:protocol] == :gen2
  end

  test "Reader returns a tag asynchronously", context do
    rp = %ReadPlan{antennas: 1, tag_protocol: :gen2}
    Reader.read_async_start(context.pid, rp, self())
    assert_receive {:tm_mercury, :message, %TM.Mercury.Message{}}
    Reader.read_async_stop(context.pid)
  end
end

