# CacheMoney

Simple caching for Elixir using ETS or Redis

## Installation

The package can be installed by adding `cache_money` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:cache_money, "~> 0.4.1"}]
end
```

## Basic Usage

Create your cache by calling `CacheMoney.start_link/3`:

```elixir
alias CacheMoney.Adapters.Redis

{:ok, cache} = CacheMoney.start_link(:my_cache, %{adapter: Redis})
```

The first argument is your cache name, in most implementations the cache name will simply be prepended to your keys in order to keep your caches separate.
The second argument is a map that contains an `:adapter`, which should be from `CacheMoney.Adapters`, or anything that implements the `CacheMoney.Adapter` behaviour. The rest of the values of this map are passed to the adapter, and are specified by the adapter.
The third argument is a keyword list of options that are passed to the underlying genserver, should you need to customize the genserver further.

Now you can put stuff in the cache, and retrieve it later!

```elixir
CacheMoney.set(cache, :foo, "bar")
CacheMoney.get(cache, :foo)
# "bar"
```

`set` also includes an `expiry` param, should you want the value in the cache to expire (expiry is in milliseconds, however some adapters can't handle an expiration less than one second (such as redis). In these cases, the expiry will be set to 1 second.)

```elixir
CacheMoney.set(cache, :foo, "bar", 10_000)
CacheMoney.get(cache, :foo)
# More than 10 seconds later
CacheMoney.get(cache, :foo)
# nil
```

`get_lazy/3` and `get_lazy/4` (with an expiry) are also available, which allows you to provide a function that will get the value. The value will be saved, and then returned.

```elixir
CacheMoney.get_lazy(cache, :foo, fn -> "expensive to get data" end)
# "expensive to get data"
CacheMoney.get_lazy(cache, :foo, fn -> "I don't get executed" end)
# "expensive to get data"
```
