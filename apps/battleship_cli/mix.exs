defmodule Battleship.CLI.MixProject do
  use Mix.Project

  def project do
    [
      app: :battleship_cli,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
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
      {:battleship, in_umbrella: true},
      {:dye, "~> 0.4.1"}
    ]
  end
end
