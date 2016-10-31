defmodule TM.Mercury.Mixfile do
  use Mix.Project

  def project do
    [app: :tm_mercury,
     version: "0.1.0",
     elixir: "~> 1.3 or ~> 1.4-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:connection, "~> 1.0.0"},
     {:nerves_uart, "~> 0.1"}]
  end
end
