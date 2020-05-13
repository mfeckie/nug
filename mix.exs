defmodule Nug.MixProject do
  use Mix.Project

  def project do
    [
      app: :nug,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Nug.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "1.4.0", only: [:dev, :test], runtime: false},
      {:plug_cowboy, "2.2.1"},
      {:cowlib, "2.3.0", override: true},
      {:jason, "1.2.1"},
      {:tesla, "1.3.2"},
      {:mint, "1.0.0"},
      {:castore, "0.1.5"}
    ]
  end
end
