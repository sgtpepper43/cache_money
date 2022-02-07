defmodule CacheMoney.Adapters.Sandbox do
  @moduledoc """
  Sandbox adapter for tests
  """

  @behaviour CacheMoney.Adapter

  use GenServer

  def checkout(cache) do
    GenServer.call(get_sandbox(cache), :checkout)
  end

  def checkin(cache) do
    GenServer.call(get_sandbox(cache), :checkin)
  end

  def flush(cache) do
    GenServer.call(get_sandbox(cache), :flush)
  end

  @impl CacheMoney.Adapter
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: get_sandbox(config.cache))
    config
  end

  @impl CacheMoney.Adapter
  def get(config, key) do
    GenServer.call(get_sandbox(config.cache), {:get, config.caller, key})
  end

  @impl CacheMoney.Adapter
  def set(config, key, value, expiry \\ nil) do
    GenServer.call(get_sandbox(config.cache), {:set, config.caller, key, value, expiry})
  end

  @impl CacheMoney.Adapter
  def delete(config, key) do
    GenServer.call(get_sandbox(config.cache), {:delete, config.caller, key})
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(:checkout, {pid, _}, cache) do
    {:reply, :ok, Map.put(cache, pid, %{})}
  end

  @impl GenServer
  def handle_call(:checkin, {pid, _}, cache) do
    {:reply, :ok, Map.delete(cache, pid)}
  end

  @impl GenServer
  def handle_call(:flush, {pid, _}, cache) do
    now = System.monotonic_time(:millisecond)

    pid_cache =
      cache
      |> Map.get(pid)
      |> Enum.reject(fn {_key, {_value, expiry}} -> expiry < now end)
      |> Map.new()

    {:reply, :ok, Map.put(cache, pid, pid_cache)}
  end

  @impl GenServer
  def handle_call({:get, pid, key}, _, cache) do
    value =
      case get_in(cache, [pid, key]) do
        {value, _expiry} -> value
        nil -> nil
      end

    {:reply, {:ok, value}, cache}
  end

  @impl GenServer
  def handle_call({:set, pid, key, value, expiry}, _, cache) do
    expiry = if is_nil(expiry), do: expiry, else: System.monotonic_time(:millisecond) + expiry
    cache = put_in(cache, [pid, key], {value, expiry})
    {:reply, {:ok, value}, cache}
  end

  @impl GenServer
  def handle_call({:delete, pid, key}, _, cache) do
    {:reply, {:ok, :ok}, Map.update!(cache, pid, &Map.delete(&1, key))}
  end

  defp get_sandbox(cache), do: :"#{cache}.Sandbox"
end
