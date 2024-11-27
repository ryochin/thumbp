defmodule Thumbp.MixProject do
  use Mix.Project

  @version "0.1.3"

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
      {:ex_doc, "~> 0.35", only: :dev},
      {:benchee, "~> 1.3", only: :dev},
      {:image, "~> 0.54", only: :dev},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:rustler_precompiled, "~> 0.8"},
      {:rustler, "~> 0.30", optional: true}
    ]
  end

  defp description do
    "An ultra-fast WebP thumbnail image generator"
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
