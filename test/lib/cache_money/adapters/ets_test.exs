defmodule CacheMoney.Adapters.ETSTest do
  use ExUnit.Case
  alias CacheMoney.Adapters.ETS

  describe "a single ets cache" do
    setup do
      {:ok, pid} =
        CacheMoney.start_link(%{
          adapter: ETS,
          cache: :"cache-#{Enum.random(0..1_000_000)}",
          purge_frequency: 50
        })

      %{pid: pid}
    end

    test "stores and returns a value", %{pid: pid} do
      CacheMoney.set(pid, "test", 1)
      assert CacheMoney.get(pid, "test") == {:ok, 1}
    end

    test "returns nil if nothing is set", %{pid: pid} do
      assert CacheMoney.get(pid, "test") == {:ok, nil}
    end

    test "can handle elixir maps", %{pid: pid} do
      value = %{test: true}
      CacheMoney.set(pid, "test", value)
      assert CacheMoney.get(pid, "test") == {:ok, value}
    end

    test "gets things lazily", %{pid: pid} do
      assert CacheMoney.get_lazy(pid, "test", fn -> "lazy" end) == {:ok, "lazy"}
    end

    test "saves the result of the lazy get", %{pid: pid} do
      assert CacheMoney.get_lazy(pid, "test", fn -> "lazy" end) == {:ok, "lazy"}
      assert CacheMoney.get(pid, "test") == {:ok, "lazy"}
    end

    test "overwrites old values", %{pid: pid} do
      CacheMoney.set(pid, "test", 1)
      assert CacheMoney.get(pid, "test") == {:ok, 1}

      CacheMoney.set(pid, "test", 2)
      assert CacheMoney.get(pid, "test") == {:ok, 2}
    end

    test "expires appropriately", %{pid: pid} do
      CacheMoney.set(pid, "test", 1, -50)
      CacheMoney.set(pid, "test2", 2, 10_000)
      assert CacheMoney.get(pid, "test") == {:ok, 1}
      assert CacheMoney.get(pid, "test2") == {:ok, 2}
      :timer.sleep(100)
      assert CacheMoney.get(pid, "test") == {:ok, nil}
      assert CacheMoney.get(pid, "test2") == {:ok, 2}
    end

    test "deletes values", %{pid: pid} do
      CacheMoney.set(pid, "test", 1)
      CacheMoney.delete(pid, "test")
      assert CacheMoney.get(pid, "test") == {:ok, nil}
    end
  end

  describe "multiple ets caches" do
    setup do
      {:ok, pid1} =
        CacheMoney.start_link(%{
          adapter: ETS,
          table: :"cache-#{Enum.random(0..1_000_000)}",
          purge_frequency: 50
        })

      {:ok, pid2} =
        CacheMoney.start_link(%{
          adapter: ETS,
          table: :"cache-#{Enum.random(0..1_000_000)}",
          purge_frequency: 50
        })

      %{pid1: pid1, pid2: pid2}
    end

    test "stores and returns a value", %{pid1: pid1, pid2: pid2} do
      CacheMoney.set(pid1, "test", 1)
      CacheMoney.set(pid2, "test", 2)
      assert CacheMoney.get(pid1, "test") == {:ok, 1}
      assert CacheMoney.get(pid2, "test") == {:ok, 2}
    end

    test "returns nil if nothing is set", %{pid1: pid1, pid2: pid2} do
      CacheMoney.set(pid2, "test", 2)
      assert CacheMoney.get(pid1, "test") == {:ok, nil}
      assert CacheMoney.get(pid2, "test") == {:ok, 2}
    end

    test "deletes values", %{pid1: pid1, pid2: pid2} do
      CacheMoney.set(pid1, "test", 1)
      CacheMoney.set(pid2, "test", 2)
      CacheMoney.delete(pid1, "test")
      assert CacheMoney.get(pid1, "test") == {:ok, nil}
      assert CacheMoney.get(pid2, "test") == {:ok, 2}
    end
  end
end
