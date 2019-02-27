defmodule CacheMoney.Adapters.Redis do
  @moduledoc """
  Redis Adapter for Cache Money
  """

  @behaviour CacheMoney.Adapter

  @impl true
  def start_link(config) do
    {:ok, pid} = Redix.start_link(config.redix_url)
    Map.put(config, :redix_conn, pid)
  end

  @impl true
  def get(config, key), do: command(config, ["GET", key])

  @impl true
  def set(config, key, value), do: command(config, ["SET", key, value])

  @impl true
  def set(config, key, value, expiry), do: command(config, ["SETEX", key, convert_expiry(expiry), value])

  @impl true
  def delete(config, key), do: command(config, ["DEL", key])

  defp command(config, command), do: Redix.command(config.redix_conn, command)

  defp convert_expiry(expiry) when expiry < 1000, do: 1
  defp convert_expiry(expiry), do: div(expiry, 1000)
end
