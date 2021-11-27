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
      extra_applications: [:logger, :xmerl]
    ]
  end

  defp deps do
    [
      {:http_client, github: "robot-enemy/http_client"},

      # {:elixir_feed_parser, "~> 2.1"},
      {:elixir_feed_parser, github: "delameko/elixir-feed-parser"},

      # Testing
      {:mox, "~> 1.0", only: :test},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
