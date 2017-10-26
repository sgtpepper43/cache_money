defmodule CacheMoney.Mixfile do
  use Mix.Project

  def project do
    [app: :cache_money,
     version: "0.1.0",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:redix, "~> 0.6.0", optional: true}
    ]
  end
end
