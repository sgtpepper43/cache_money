defmodule CacheMoney.Adapter do
  @moduledoc """
  This module specifies the adapter API that an adapter is required to implement.
  """
  @type t :: module

  @type config :: map
  @type key :: any
  @type value :: any
  @type expiry :: non_neg_integer

  @callback start_link(config) :: config

  @callback get(config, key) :: {:ok, value} | {:error, any}

  @callback set(config, key, value) :: {:ok, value} | {:error, any}

  @callback set(config, key, value, expiry) :: {:ok, value} | {:error, any}

  @callback delete(config, key) :: {:ok, value} | {:error, any}
end
