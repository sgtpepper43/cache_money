defmodule CacheMoney do
  @moduledoc """
  Handles caching values under different cache names, can expire keys
  """

  use GenServer

  @default_timeout 5000

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

  @typedoc """
  Currently the only option available is an optional `timeout` that gets passed
  along with `GenServer.call`
  """
  @type options :: [timeout: integer]

  @type server :: Genserver.server()

  @doc """
  Starts a `CacheMoney` process linked to the current process.

  ## Arguments

  * cache - the name of the cache. Multiple caches using the same adapter will
    all be in the same spot, but will be namespaced by the given cache name.
  * conifg - contains various configuration options for the cache, depending on
    the adapter. `:adapter` is required to be set, and must be set to a module that
    implements `CacheMoney.Adapter`, such as `CacheMoney.Adapters.Redis` or
    `CacheMoney.Adapters.ETS`. Different adapters will also specify other required
    optionso be passed to them through the `config` argument
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
  @spec get(server, key, options()) :: {:ok, value} | {:error, term}
  def get(server, key, opts \\ []),
    do: GenServer.call(server, {:get, key}, opts[:timeout] || @default_timeout)

  @doc """
  Gets the value out of the cache using the `key`. Lazily fetches the data, inserts
  it into the cache, and returns it if it does not exist. Optional `expiry` is in
  seconds.
  """
  @spec set(server, key, (() -> value), integer, options()) :: {:ok, value} | {:error, any}
  def get_lazy(server, key, fun, expiry \\ nil, opts \\ []),
    do: GenServer.call(server, {:get_lazy, key, fun, expiry}, opts[:timeout] || @default_timeout)

  @doc """
  Sets `key` in the cache to `value`
  """
  @spec set(server, key, value) :: {:ok, value} | {:error, any}
  def set(server, key, value), do: GenServer.call(server, {:set, key, value})

  @doc """
  Sets `key` in the cache to `value`
  """
  @spec set(server, key, value, options()) :: {:ok, value} | {:error, any}
  def set(server, key, value, opts) when is_list(opts),
    do: GenServer.call(server, {:set, key, value}, opts[:timeout] || @default_timeout)

  @doc """
  Sets `key` in the cache to `value`, which expires after `expiry` seconds
  """
  @spec set(server, key, value, integer, options()) :: {:ok, value} | {:error, any}
  def set(server, key, value, expiry, opts \\ []),
    do: GenServer.call(server, {:set, key, value, expiry}, opts[:timeout] || @default_timeout)

  @doc """
  Deletes the `key` from the cache
  """
  @spec delete(server, key, options()) :: {:ok, value} | {:error, term}
  def delete(server, key, opts \\ []),
    do: GenServer.call(server, {:delete, key}, opts[:timeout] || @default_timeout)

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
