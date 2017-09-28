defmodule TzWorld.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tz_world,
      name: "TzWord",
      version: "0.1.0",
      elixir: "~> 1.3",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      source_url: "https://github.com/kimlai/tz_world",
      description: description(),
      package: package(),
      docs: [
        extras: ["README.md": [title: "README"]],
        main: "readme",
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ecto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.1"},
      {:geo, "~> 2.0"},
      {:geo_postgis, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.12"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
    ]
  end

  defp description do
    """
    Resolve timezones from a location efficiently using PostGIS and Ecto.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/kimlai/tz_world"},
      maintainers: ["Kim Laï Trinh"],
    ]
  end
end
