defmodule Battleship.Mixfile do
  use Mix.Project

  def project do
    [app: :battleship,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_paths: ["lib", "players"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Battleship, []}]
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
    [
      {:dye, "~> 0.4.1"},
      {:dialyxir, "~> 0.3.5", only: [:dev]},
      {:ex_doc, "~> 0.12", only: :dev}
    ]
  end
end
