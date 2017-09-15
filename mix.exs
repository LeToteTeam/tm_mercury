defmodule TM.Mercury.Mixfile do
  use Mix.Project

  def project do
    [app: :tm_mercury,
     version: "0.4.0-dev",
     elixir: "~> 1.5.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger, :connection, :nerves_uart]]
  end

  defp deps do
    [{:connection, "~> 1.0.0"},
     {:nerves_uart, "~> 0.1"},
     {:ex_doc, "~> 0.16.4", only: :dev, runtime: false}]
  end

  defp description do
    """
    A pure Elixir implementation of the ThingMagic Mercury SDK
    """
  end

  defp package do
    [maintainers: ["Justin Schneck", "Jeff Smith"],
     licenses: ["Apache 2.0"],
     links: %{"Github" => "https://github.com/letoteteam/tm_mercury"}]
  end
end
