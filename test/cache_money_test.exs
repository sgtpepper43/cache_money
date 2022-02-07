defmodule CacheMoneyTest do
  use ExUnit.Case, async: true
  doctest CacheMoney

  alias CacheMoney.Adapters.Sandbox

  setup_all do
    CacheMoney.start_link(CacheTest, %{adapter: Sandbox})
    CacheMoney.start_link(CacheTest1, %{adapter: Sandbox})
    CacheMoney.start_link(CacheTest2, %{adapter: Sandbox})

    :ok
  end

  describe "a single cache" do
    setup do
      :ok = Sandbox.checkout(CacheTest)
      on_exit(fn -> Sandbox.checkin(CacheTest) end)
    end

    test "stores and returns a value" do
      CacheMoney.set(CacheTest, "test", 1)
      assert CacheMoney.get(CacheTest, "test") == {:ok, 1}
    end

    test "returns nil if nothing is set" do
      assert CacheMoney.get(CacheTest, "test") == {:ok, nil}
    end

    test "can handle elixir maps" do
      value = %{test: true}
      CacheMoney.set(CacheTest, "test", value)
      assert CacheMoney.get(CacheTest, "test") == {:ok, value}
    end

    test "gets things lazily" do
      assert CacheMoney.get_lazy(CacheTest, "test", fn -> "lazy" end) == {:ok, "lazy"}
    end

    test "saves the result of the lazy get" do
      assert CacheMoney.get_lazy(CacheTest, "test", fn -> "lazy" end) == {:ok, "lazy"}
      assert CacheMoney.get(CacheTest, "test") == {:ok, "lazy"}
    end

    test "saves the lazy get if it returns an ok tuple" do
      assert CacheMoney.get_lazy(CacheTest, "test", fn -> {:ok, "lazy"} end) == {:ok, "lazy"}
      assert CacheMoney.get(CacheTest, "test") == {:ok, "lazy"}
    end

    test "does not save the lazy get if it returns an error tuple" do
      assert CacheMoney.get_lazy(CacheTest, "test", fn -> {:error, "error"} end) ==
               {:error, "error"}

      assert CacheMoney.get(CacheTest, "test") == {:ok, nil}
    end

    test "overwrites old values" do
      CacheMoney.set(CacheTest, "test", 1)
      assert CacheMoney.get(CacheTest, "test") == {:ok, 1}

      CacheMoney.set(CacheTest, "test", 2)
      assert CacheMoney.get(CacheTest, "test") == {:ok, 2}
    end

    test "expires appropriately" do
      CacheMoney.set(CacheTest, "test", 1, -50)
      CacheMoney.set(CacheTest, "test2", 2, 10_000)
      assert CacheMoney.get(CacheTest, "test") == {:ok, 1}
      assert CacheMoney.get(CacheTest, "test2") == {:ok, 2}
      :timer.sleep(100)
      Sandbox.flush(CacheTest)
      assert CacheMoney.get(CacheTest, "test") == {:ok, nil}
      assert CacheMoney.get(CacheTest, "test2") == {:ok, 2}
    end

    test "deletes values" do
      CacheMoney.set(CacheTest, "test", 1)
      CacheMoney.delete(CacheTest, "test")
      assert CacheMoney.get(CacheTest, "test") == {:ok, nil}
    end
  end

  describe "multiple caches" do
    setup do
      :ok = Sandbox.checkout(CacheTest1)
      :ok = Sandbox.checkout(CacheTest2)

      on_exit(fn ->
        Sandbox.checkin(CacheTest1)
        Sandbox.checkin(CacheTest2)
      end)
    end

    test "stores and returns a value" do
      CacheMoney.set(CacheTest1, "test", 1)
      CacheMoney.set(CacheTest2, "test", 2)
      assert CacheMoney.get(CacheTest1, "test") == {:ok, 1}
      assert CacheMoney.get(CacheTest2, "test") == {:ok, 2}
    end

    test "returns nil if nothing is set" do
      CacheMoney.set(CacheTest2, "test", 2)
      assert CacheMoney.get(CacheTest1, "test") == {:ok, nil}
      assert CacheMoney.get(CacheTest2, "test") == {:ok, 2}
    end

    test "deletes values" do
      CacheMoney.set(CacheTest1, "test", 1)
      CacheMoney.set(CacheTest2, "test", 2)
      CacheMoney.delete(CacheTest1, "test")
      assert CacheMoney.get(CacheTest1, "test") == {:ok, nil}
      assert CacheMoney.get(CacheTest2, "test") == {:ok, 2}
    end
  end
end
