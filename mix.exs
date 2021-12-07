defmodule CacheMoney.Mixfile do
  use Mix.Project

  @source_url "https://github.com/sgtpepper43/cache_money"
  @version "0.5.3"

  def project do
    [
      app: :cache_money,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: "ETS or Redis based caching for Elixir",
      licenses: ["MIT"],
      maintainers: ["Trevor Fenn<sgtpepper43@gmail.com>"],
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/cache_money",
      formatters: ["html"],
      groups_for_modules: [
        Adapters: [
          CacheMoney.Adapter,
          CacheMoney.Adapters.ETS,
          CacheMoney.Adapters.Redis
        ]
      ]
    ]
  end
end
