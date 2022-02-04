defmodule CacheMoney.Adapters.Redis do
  @moduledoc """
  Redis Adapter for Cache Money
  """

  @behaviour CacheMoney.Adapter

  @type config :: %{
          redix_conn: Redix.connection(),
          redix_url: String.t()
        }

  @type command_response ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}

  @impl CacheMoney.Adapter
  def start_link(config) do
    {:ok, pid} = Redix.start_link(config.redix_url)
    Map.put(config, :redix_conn, pid)
  end

  @impl CacheMoney.Adapter
  def get(config, key), do: command(config, ["GET", key])

  @impl CacheMoney.Adapter
  def set(config, key, value), do: command(config, ["SET", key, value])

  @impl CacheMoney.Adapter
  def set(config, key, value, expiry),
    do: command(config, ["SETEX", key, convert_expiry(expiry), value])

  @impl CacheMoney.Adapter
  def delete(config, key), do: command(config, ["DEL", key])

  @spec command(config(), Redix.command()) :: command_response()
  defp command(config, command), do: Redix.command(config.redix_conn, command)

  defp convert_expiry(expiry) when expiry < 1000, do: 1
  defp convert_expiry(expiry), do: div(expiry, 1000)
end
