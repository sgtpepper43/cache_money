defmodule CacheMoney do
  @moduledoc """
  Handles caching values under different cache names, can expire keys
  Keep in mind that while you can use atoms or strings for cache and key names,
  they will always be converted to strings.
  Also keep in mind that any data you put in the cache will come back out as a
  string, regardless of how it was inserted.
  """

  use GenServer

  @redix_conn :redix

  def start_link(config) do
    {:ok, pid} = Redix.start_link(config.redix_url)
    config = Map.put(config, :redix_conn, pid)
    GenServer.start_link(__MODULE__, config)
  end

  def get(pid, key), do: GenServer.call(pid, {:get, key})

  def get_lazy(pid, key, fun), do: GenServer.call(pid, {:get_lazy, key, fun})

  def set(pid, key, value), do: GenServer.call(pid, {:set, key, value})

  def set(pid, key, value, expiry), do: GenServer.call(pid, {:set, key, value, expiry})

  def delete(pid, key), do: GenServer.call(pid, {:delete, key})

  @impl true
  def handle_call({:get, key}, _from, config) do
    {:reply, command(config, ["GET", get_key(config.cache, key)]), config}
  end
  def handle_call({:get_lazy, key, fun}, _from, config) do
    key = get_key(config.cache, key)
    case command(config, ["GET", key]) do
      {:ok, nil} ->
        value = get_and_save_lazy_value(key, fun.(), config)
        {:reply, {:ok, value}, config}
      value -> {:reply, value, config}
    end
  end
  def handle_call({:set, key, value}, _from, config) do
    {:reply, command(config, ["SET", get_key(config.cache, key), value]), config}
  end
  def handle_call({:set, key, value, expiry}, _from, config) do
    {:reply, command(config, ["SETEX", get_key(config.cache, key), expiry, value]), config}
  end
  def handle_call({:delete, key}, _from, config) do
    {:reply, command(config, ["DEL", get_key(config.cache, key)]), config}
  end

  defp get_and_save_lazy_value(key, {value, expiry}, config) do
    command(config, ["SETEX", key, expiry, value])
    value
  end
  defp get_and_save_lazy_value(key, value, config) do
    command(config, ["SET", key, value])
    value
  end

  defp get_key(cache, key) do
    prefix =
      :cache_money
      |> Application.get_env(:prefix)
      |> case do
        nil -> ""
        prefix -> "#{prefix}-"
      end
    "#{prefix}#{cache}-#{key}"
  end

  defp command(config, command), do: Redix.command(config.redix_conn, command)
end
