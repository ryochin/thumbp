defmodule Thumbp.Benchmark do
  @moduledoc false

  @width 320
  @height 240
  @quality 60
  @effort 3

  def run do
    content = File.read!("./test/assets/images/sample.jpg")

    Benchee.run(
      %{
        "thumbp" => fn -> thumbp(content) end,
        "image (libvips)" => fn -> image(content) end
      }
    )
  end

  def thumbp(content) do
    {:ok, _} = Thumbp.create(content, @width, @height, quality: @quality, effort: @effort)
  end

  def image(content) do
    {:ok, image} = Image.open(content)
    {:ok, image} = image |> Image.thumbnail("#{@width}x#{@height}")
    {:ok, _} = image |> Image.write(:memory, image_opts())
  end

  defp image_opts,
    do: [
      strip_metadata: true,
      quality: @quality,
      effort: @effort,
      suffix: ".webp"
    ]
end

Thumbp.Benchmark.run
