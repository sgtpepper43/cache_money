defmodule CacheMoney.Mixfile do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :cache_money,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "ETS or Redis based caching for Elixir",
      package: [
        licenses: ["MIT"],
        maintainers: ["Trevor Fenn<sgtpepper43@gmail.com>"],
        links: %{"GitHub" => "https://github.com/sgtpepper43/cache_money"},
        files: ["lib", "mix.exs", "README*", "LICENSE*"]
      ],
      name: "Cache Money",
      docs: docs()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:redix, "~> 0.6.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [
      main: "CacheMoney",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/cache_money",
      source_url: "https://github.com/sgtpepper43/cache_money",
      groups_for_modules: [
        "Adapters": [
          CacheMoney.Adapter,
          CacheMoney.Adapters.ETS,
          CacheMoney.Adapters.Redis
        ]
      ]
    ]
  end
end
