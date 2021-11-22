defmodule RSS.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :rss,
      deps: deps(),
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0",
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:date_time_parser, "~> 1.0"},
      {:fast_rss, "~> 0.3.5"},
      {:http_client, path: "../http_client"},

      {:util, github: "robot-enemy/util"},

      # Testing
      {:mox, "~> 1.0", only: :test},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
