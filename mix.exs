defmodule Thumbp.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :thumbp,
      version: @version,
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "ThumbP",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev},
      {:benchee, "~> 1.5", only: :dev},
      {:image, "~> 0.65", only: :dev},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:rustler_precompiled, "~> 0.9"},
      {:rustler, "~> 0.37", optional: true}
    ]
  end

  defp description do
    "A Lightweight & Fast WebP Thumbnail Image Generator"
  end

  defp package do
    [
      maintainers: ["Ryo Okamoto"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ryochin/thumbp"},
      files: ~w(mix.exs README.md benchmark lib native test LICENSE checksum-*.exs .formatter.exs)
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: "https://github.com/ryochin/thumbp"
    ]
  end
end
