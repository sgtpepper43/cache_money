defmodule CacheMoney do
  @moduledoc """
  Handles caching values under different cache names, can expire keys
  """

  use GenServer

  @typedoc """
  The name of the cache, used for namespacing multiple caches on the same adapter.
  Can be either a binary or an atom, but will always be converted to a binary.
  """
  @type cache_name :: binary | atom

  @typedoc """
  The key a value will be set under. Can be either a binary or an atom, but will
  always be converted to a binary.
  """
  @type key :: binary | atom

  @typedoc """
  The value to be saved in the cache. Can be any value going _in_ to the cache,
  but depending on the adapter used, may not be the same value going out. For
  example, `CacheMoney.Adapters.ETS` can save any elixir term, including `pid`s.
  `CacheMoney.Adapters.Redis`, however, can only save items as strings.
  """
  @type value :: term

  @doc """
  Starts a `CacheMoney` process linked to the current process.

  ## Arguments

  * cache - the name of the cache. Multiple caches using the same adapter will
    all be in the same spot, but will be namespaced by the given cache name.
  * conifg - contains various configuration options for the cache, depending on
    the adapter. `:adapter` is required to be set, and must be set to a module that
    implements `CacheMoney.Adapter`, such as `CacheMoney.Adapters.Redis` or
    `CacheMoney.Adapters.ETS`. Different adapters will also specify other required
    options to be passed to them through the `config` argument
  * opts - see `GenServer.start_link/3`. Options are passed straight through to the
    underlying `GenServer`
  """
  @spec start_link(cache_name, %{}, Keyword.t()) :: pid()
  def start_link(cache, config = %{}, opts \\ []) do
    config =
      config
      |> Map.put_new(:cache, cache)
      |> config.adapter.start_link()

    opts = Keyword.put_new(opts, :name, cache)

    GenServer.start_link(__MODULE__, config, opts)
  end

  @doc """
  Gets the value out of the cache using the `key`.

  If the value does not exist in the cache `nil` will be returned.
  """
  @spec get(pid, key) :: {:ok, value} | {:error, term}
  def get(pid, key), do: GenServer.call(pid, {:get, key})

  @doc """
  Gets the value out of the cache using the `key`. Lazily fetches the data, inserts
  it into the cache, and returns it if it does not exist. Optional `expiry` is in
  milliseconds.
  """
  @spec set(pid, key, (() -> value), integer) :: {:ok, value} | {:error, any}
  def get_lazy(pid, key, fun, expiry \\ nil),
    do: GenServer.call(pid, {:get_lazy, key, fun, expiry})

  @doc """
  Sets `key` in the cache to `value`
  """
  @spec set(pid, key, value) :: {:ok, value} | {:error, any}
  def set(pid, key, value), do: GenServer.call(pid, {:set, key, value})

  @doc """
  Sets `key` in the cache to `value`, which expires after `expiry` milliseconds
  """
  @spec set(pid, key, value, integer) :: {:ok, value} | {:error, any}
  def set(pid, key, value, expiry), do: GenServer.call(pid, {:set, key, value, expiry})

  @doc """
  Deletes the `key` from the cache
  """
  @spec delete(pid, key) :: {:ok, value} | {:error, term}
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

  def handle_call({:get_lazy, key, fun, expiry}, _from, config) do
    key = get_key(config.cache, key)

    case config.adapter.get(config, key) do
      {:ok, nil} ->
        value = get_and_save_lazy_value(key, fun.(), expiry, config)
        {:reply, value, config}

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

  defp get_and_save_lazy_value(key, {:ok, value}, nil, config) do
    config.adapter.set(config, key, value)
    {:ok, value}
  end

  defp get_and_save_lazy_value(key, {:ok, value}, expiry, config) do
    config.adapter.set(config, key, value, expiry)
    {:ok, value}
  end

  defp get_and_save_lazy_value(_key, {:error, error}, _, _config), do: {:error, error}

  defp get_and_save_lazy_value(key, value, nil, config) do
    config.adapter.set(config, key, value)
    {:ok, value}
  end

  defp get_and_save_lazy_value(key, value, expiry, config) do
    config.adapter.set(config, key, value, expiry)
    {:ok, value}
  end

  defp get_key(cache, key) do
    "#{cache}-#{key}"
  end
end
