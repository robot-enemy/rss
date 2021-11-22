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
      {:http_client, github: "robot-enemy/http_client"},

      {:date_time_parser, "~> 1.1"},
      {:feeder_ex, "~> 1.1"},

      # Testing
      {:mox, "~> 1.0", only: :test},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
