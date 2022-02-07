defmodule CacheMoney.Mixfile do
  use Mix.Project

  @source_url "https://github.com/sgtpepper43/cache_money"
  @version "0.6.1"

  def project do
    [
      app: :cache_money,
      version: @version,
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "Cache Money",
      docs: docs(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :transitive,
        ignore_warnings: ".dialyzer.ignore-warnings"
      ]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:redix, "~> 1.1", optional: true}
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
