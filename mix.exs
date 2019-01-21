defmodule TM.Mercury.Mixfile do
  use Mix.Project

  def project do
    [ 
      app: :tm_mercury,
      version: "0.5.2",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:connection, "~> 1.0.0"},
      {:circuits_uart, "~> 1.3"},
      {:dialyxir, "~> 1.0.0-rc", only: :dev, runtime: false},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A pure Elixir implementation of the ThingMagic Mercury SDK
    """
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/letoteteam/tm_mercury"}
    ]
  end
end
