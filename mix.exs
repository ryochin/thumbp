defmodule Thumbp.MixProject do
  use Mix.Project

  def project do
    [
      app: :thumbp,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev},
      {:image, "~> 0.38", only: :dev},
      {:rustler, "~> 0.30.0"}
    ]
  end
end
