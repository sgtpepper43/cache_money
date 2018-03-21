defmodule CacheMoney.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cache_money,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "ETS or Redis based caching for Elixir",
      package: [
        licenses: ["MIT"],
        maintainers: ["Trevor Fenn<sgtpepper43@gmail.com>"],
        links: %{"GitHub" => "https://github.com/sgtpepper43/cache_money"},
        files: ["lib", "mix.exs", "README*", "LICENSE*"]
      ]
    ]
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
