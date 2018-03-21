defmodule CacheMoney do
  @moduledoc """
  Handles caching values under different cache names, can expire keys
  Keep in mind that while you can use atoms or strings for cache and key names,
  they will always be converted to strings.
  Also keep in mind that any data you put in the cache will come back out as a
  string, regardless of how it was inserted.
  """

  use GenServer

  def start_link(cache, config = %{}, opts \\ []) do
    config =
      config
      |> Map.put_new(:cache, cache)
      |> config.adapter.start_link()

    opts = Keyword.put_new(opts, :name, cache)

    GenServer.start_link(__MODULE__, config, opts)
  end

  def get(pid, key), do: GenServer.call(pid, {:get, key})

  def get_lazy(pid, key, fun), do: GenServer.call(pid, {:get_lazy, key, fun})

  def set(pid, key, value), do: GenServer.call(pid, {:set, key, value})
  def set(pid, key, value, expiry), do: GenServer.call(pid, {:set, key, value, expiry})

  def delete(pid, key), do: GenServer.call(pid, {:delete, key})

  @impl true
  def init(args) do
    {:ok, args}
  end

  @impl true
  def handle_call({:get, key}, _from, config) do
    key = get_key(config.cache, key)
    {:reply, config.adapter.get(config, key), config}
  end

  def handle_call({:get_lazy, key, fun}, _from, config) do
    key = get_key(config.cache, key)

    case config.adapter.get(config, key) do
      {:ok, nil} ->
        value = get_and_save_lazy_value(key, fun.(), config)
        {:reply, {:ok, value}, config}

      value ->
        {:reply, value, config}
    end
  end

  def handle_call({:set, key, value}, _from, config) do
    {:reply, config.adapter.set(config, get_key(config.cache, key), value), config}
  end

  def handle_call({:set, key, value, expiry}, _from, config) do
    {:reply, config.adapter.set(config, get_key(config.cache, key), value, expiry), config}
  end

  def handle_call({:delete, key}, _from, config) do
    {:reply, config.adapter.delete(config, get_key(config.cache, key)), config}
  end

  defp get_and_save_lazy_value(key, {value, expiry}, config) do
    config.adapter.set(config, key, value, expiry)
    value
  end

  defp get_and_save_lazy_value(key, value, config) do
    config.adapter.set(config, key, value)
    value
  end

  defp get_key(cache, key) do
    "#{cache}-#{key}"
  end
end
