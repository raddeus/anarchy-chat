defmodule WebsocketPlayground.MixProject do
  use Mix.Project

  def project do
    [
      app: :websocket_playground,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {WebsocketPlayground.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.9"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:cors_plug, "~> 2.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:eternal, "~> 1.2"},
    ]
  end
end
