defmodule TM.Mercury.ReaderTest do
  use ExUnit.Case, async: false

  alias TM.Mercury.{Reader, ReadPlan}

  setup_all do
    {:ok, pid} = Reader.start_link(device: "/dev/ttyACM0", speed: 115200)
    {:ok, %{pid: pid}}
  end

  test "Reader returns a tag synchronously using current reader settings", context do
    {:ok, [tag|_]} = Reader.read_sync(context.pid)
    assert tag[:protocol] == :gen2
  end

  test "Reader returns a tag synchronously using a simple read plan", context do
    rp = %SimpleReadPlan{antennas: 1, tag_protocol: :gen2}
    {:ok, [tag|_]} = Reader.read_sync(context.pid, rp)
    assert tag[:protocol] == rp.tag_protocol
  end

  test "Reader returns a tag asynchronously using current reader settings", context do
    Reader.read_async_start(context.pid, self())
    assert_receive {:tm_mercury, :tags, _}, 1000
    Reader.read_async_stop(context.pid)
  end

  test "Reader returns a single tag read for a stop trigger read plan with tag count = 1", context do
    rp = %StopTriggerReadPlan{stop_count: 1, antennas: 1, tag_protocol: :gen2}
    {:ok, tags} = Reader.read_sync(context.pid, rp)
    assert length(tags) == 1
  end

  test "Reader returns a valid temperature", context do
    {:ok, temp_c} = Reader.get_temperature(context.pid)
    assert temp_c > 0
  end

  test "Reader changes power level", context do
    {:ok, initial_cdbm} = Reader.get_read_tx_power(context.pid)

    max_power_cdbm = 3000
    change_to_cdbm = case initial_cdbm do
      ^max_power_cdbm -> 2000
      _ -> min(initial_cdbm + 100, max_power_cdbm)
    end

    :ok = Reader.set_read_tx_power(context.pid, change_to_cdbm)
    {:ok, changed_cdbm} = Reader.get_read_tx_power(context.pid)

    # Set power level back before asserting, assuming the op is functioning correctly.
    Reader.set_read_tx_power(context.pid, initial_cdbm)

    assert changed_cdbm == change_to_cdbm
  end
end
