defmodule Thumbp do
  @moduledoc """
  A Lightweight & Fast WebP Thumbnail Image Generator
  """

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :thumbp,
    crate: "thumbp",
    base_url: "https://github.com/ryochin/thumbp/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_PRECOMPILATION_EXAMPLE_BUILD") in ["1", "true"],
    version: version

  @type body :: binary
  @type width :: pos_integer
  @type height :: pos_integer

  @known_opts [:quality, :target_size]

  @doc """
  Create a thumbnail image

  ## Examples

      iex> content = File.read!("./test/assets/images/sample.jpg")
      iex> Thumbp.create(content, 320, 240)
      {:ok, <<82, 73, 70, 70, 102, 12, 0, 0, 87, 69, 66, 80, ...>>}
  """
  @spec create(body, width, height) :: {:ok, binary} | {:error, String.t()}
  def create(body, width, height), do: create(body, width, height, [])

  @doc """
  Create a thumbnail image with options

  ## Options

  - `quality` - The quality ranges from 0 to 100, defaulting to 75.
  - `target_size` - Target size in bytes. Increases processing time by approximately 20-80%.
    When both `quality` and `target_size` are given, `target_size` takes precedence.
  ## Examples

      iex> content = File.read!("./test/assets/images/sample.jpg")
      iex> Thumbp.create(content, 320, 240, quality: 50)
      iex> Thumbp.create(content, 320, 240, target_size: 12_000)
  """
  @spec create(body, width, height, keyword) :: {:ok, binary} | {:error, String.t()}
  def create(body, width, height, opts) when is_list(opts) do
    quality = Keyword.get(opts, :quality)
    target_size = Keyword.get(opts, :target_size)

    with :ok <- validate(body, width, height, quality, target_size, opts) do
      _create(body, width, height, quality && quality / 1, target_size)
    end
  end

  @spec validate(body, width, height, number | nil, pos_integer | nil, keyword) ::
          :ok | {:error, String.t()}
  defp validate(body, width, height, quality, target_size, opts) do
    cond do
      Keyword.keys(opts) -- @known_opts != [] -> {:error, "unknown options"}
      is_nil(body) -> {:error, "body is empty"}
      width <= 0 -> {:error, "width must be > 0"}
      height <= 0 -> {:error, "height must be > 0"}
      not is_nil(quality) and not is_number(quality) -> {:error, "quality must be a number"}
      not is_nil(quality) and quality < 0 -> {:error, "quality must be >= 0"}
      not is_nil(quality) and quality > 100 -> {:error, "quality must be <= 100"}
      not is_nil(target_size) and target_size <= 0 -> {:error, "target_size must be > 0"}
      not is_nil(quality) and not is_nil(target_size) -> {:error, "quality and target_size options are exclusive"}
      true -> :ok
    end
  end

  # NIF function definition
  defp _create(_body, _width, _height, _quality, _target_size),
    do: :erlang.nif_error(:nif_not_loaded)
end
