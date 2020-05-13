defmodule Nug.MixProject do
  use Mix.Project

  def project do
    [
      app: :nug,
      version: "0.2.3",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
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
      {:credo, "~> 1.4.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22.0", only: :dev, runtime: false},
      {:plug_cowboy, "~> 2.0"},
      {:cowlib, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:tesla, "~> 1.3"},
      {:mint, "~> 1.0"},
      {:castore, "~> 0.1.5"}
    ]
  end

  defp description do
    "A HTTP request proxy library for testing in Elixir"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mfeckie/nug"}
    ]
  end
end
