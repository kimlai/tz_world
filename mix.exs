defmodule TzWorld.Mixfile do
  use Mix.Project

  @source_url "https://github.com/kimlai/tz_world"
  @version "0.7.0"

  def project do
    [
      app: :tz_world,
      name: "TzWord",
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      source_url: @source_url,
      description: description(),
      package: package(),
      dialyzer: [
        plt_add_apps: ~w(mix inets jason)a
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :public_key, :inets]
    ]
  end

  defp deps do
    [
      {:geo, "~> 1.0 or ~> 2.0 or ~> 3.3"},
      {:jason, "~> 1.0"},
      {:castore, "~> 0.1", optional: true},
      {:certifi, "~> 2.5", optional: true},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false, optional: true},
      {:benchee, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Resolve timezone names from a location.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: links(),
      maintainers: ["Kim Laï Trinh", "Kip Cole"],
      files: [
        "lib",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  @priv "priv"

  def aliases do
    [
      "compile.app": [
        fn _ -> File.mkdir_p!(@priv) end,
        "compile.app"
      ]
    ]
  end

  def links do
    %{
      "GitHub" => @source_url,
      "Readme" => "#{@source_url}/blob/v#{@version}/README.md",
      "Changelog" => "#{@source_url}/blob/v#{@version}/CHANGELOG.md"
    }
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      skip_undefined_reference_warnings_on: ["changelog"]
    ]
  end
end
