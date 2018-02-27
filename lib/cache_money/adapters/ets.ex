defmodule CacheMoney.Adapters.ETS do
  @moduledoc """
  Redis Adapter for Cache Money
  """

  use GenServer

  @behaviour CacheMoney.Adapter

  # 10 years
  @max_cache_expiry :timer.hours(24 * 365 * 10)

  @impl true
  def start_link(config) do
    {:ok, pid} = GenServer.start_link(__MODULE__, config)
    send(pid, :purge)
    Map.put(config, :ets_pid, pid)
  end

  @impl true
  def get(config, key), do: GenServer.call(config.ets_pid, {:get, key})

  @impl true
  def set(config, key, value, expiry \\ @max_cache_expiry),
    do: GenServer.call(config.ets_pid, {:set, key, value, expiry})

  @impl true
  def delete(config, key), do: GenServer.call(config.ets_pid, {:delete, key})

  @impl true
  def handle_call({:get, id}, _, %{table: table} = state) do
    value =
      case :ets.lookup(table, id) do
        [{^id, {_, value}}] -> value
        _ -> nil
      end

    {:reply, {:ok, value}, state}
  end

  @impl true
  def handle_call({:set, id, value, expiry}, _, %{table: table} = state) do
    true = :ets.insert(table, {id, {System.monotonic_time(:seconds) + expiry, value}})
    {:reply, {:ok, value}, state}
  end

  @impl true
  def handle_call({:delete, id}, _, %{table: table} = state) do
    :ets.delete(table, id)
    {:reply, {:ok, :ok}, state}
  end

  @impl true
  def handle_info(:purge, %{purge_frequency: purge_frequency, table: table} = state) do
    now = System.monotonic_time(:seconds)
    match_spec = [{{:"$1", {:"$2", :_}}, [{:<, :"$2", {:const, now}}], [true]}]
    :ets.select_delete(table, match_spec)
    Process.send_after(self(), :purge, purge_frequency)
    {:noreply, state}
  end

  @impl true
  def init(config) do
    table = Map.get(config, :table, __MODULE__)
    purge_frequency = Map.get(config, :purge_frequency, :timer.minutes(5))
    :ets.new(table, [:named_table, :set, :private])
    {:ok, Map.merge(config, %{table: table, purge_frequency: purge_frequency})}
  end
end
