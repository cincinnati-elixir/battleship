defmodule Battleship.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev]},
      {:credo, "~> 0.9.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: :dev}
    ]
  end
end
