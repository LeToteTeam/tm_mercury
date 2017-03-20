defmodule TM.Mercury.ReaderTest do
  use ExUnit.Case, async: false
  doctest TM.Mercury.Reader

  alias TM.Mercury.{Reader, ReadPlan}

  setup_all do
    {:ok, pid} = Reader.start_link(device: "/dev/ttyACM0", speed: 115200)
    {:ok, %{pid: pid}}
  end

  test "Reader returns a tag synchronously using current reader settings", context do
    {:ok, [tag|_]} = Reader.read_sync(context.pid)
    assert tag[:protocol] == :gen2
  end

  test "Reader returns a tag synchronously using a custom read plan", context do
    rp = %ReadPlan{antennas: 1, tag_protocol: :gen2}
    {:ok, [tag|_]} = Reader.read_sync(context.pid, rp)
    assert tag[:protocol] == rp.tag_protocol
  end

  test "Reader returns a tag asynchronously using current reader settings", context do
    Reader.read_async_start(context.pid, self())
    assert_receive {:tm_mercury, :tags, _}, 1000
    Reader.read_async_stop(context.pid)
  end
end

