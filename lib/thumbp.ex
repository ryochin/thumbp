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
  @type quality :: float | non_neg_integer | nil
  @type target_size :: pos_integer | nil

  @doc """
  Create a thumbnail image

  ## Examples

      iex> content = File.read!("./test/assets/images/sample.jpg")
      iex> Thumbp.create(content, 320, 240)
      {:ok, <<82, 73, 70, 70, 102, 12, 0, 0, 87, 69, 66, 80, ...>>}
  """
  @spec create(body, width, height) :: {:ok, binary} | {:error, String.t()}
  def create(body, width, height), do: create(body, width, height, nil, nil)

  @doc """
  Create a thumbnail image with options

  # Quality

  The quality ranges from 0 to 100, defaulting to 75.

  # Target size

  You can also specify a target size in bytes, although this will increase the processing time
  by approximately 20% to 80%.

  ## Examples

      iex> content = File.read!("./test/assets/images/sample.jpg")
      iex> Thumbp.create(content, 320, 240, quality: 50)
      iex> Thumbp.create(content, 320, 240, target_size: 12_000)
  """
  def create(body, width, height, quality: quality) when is_number(quality),
    do: create(body, width, height, quality / 1, nil)

  def create(body, width, height, target_size: target_size)
      when is_integer(target_size),
      do: create(body, width, height, nil, target_size)

  def create(_, _, _, quality: quality, target_size: target_size)
      when is_integer(quality) and is_integer(target_size),
      do: {:error, "quality and target_size options are exclusive"}

  @spec create(body, width, height, list) :: {:ok, binary} | {:error, String.t()}
  def create(_, _, _, opts) when is_list(opts), do: {:error, "unknown options"}

  defp create(body, _, _, _, _) when is_nil(body), do: {:error, "body is empty"}
  defp create(_, width, _, _, _) when width <= 0, do: {:error, "width must be > 0"}
  defp create(_, _, height, _, _) when height <= 0, do: {:error, "height must be > 0"}

  defp create(_, _, _, quality, _) when not is_nil(quality) and quality < 0,
    do: {:error, "quality must be >= 0"}

  defp create(_, _, _, quality, _) when not is_nil(quality) and quality > 100,
    do: {:error, "quality must be <= 100"}

  defp create(_, _, _, _, target_size) when not is_nil(target_size) and target_size <= 0,
    do: {:error, "target_size must be > 0"}

  @spec create(body, width, height, quality, target_size) ::
          {:ok, binary} | {:error, String.t()}
  defp create(body, width, height, quality, target_size),
    do: _create(body, width, height, quality, target_size)

  # NIF function definition
  @spec _create(body, width, height, quality, target_size) ::
          {:ok, binary} | {:error, String.t()}
  defp _create(_body, _width, _height, _quality, _target_size),
    do: :erlang.nif_error(:nif_not_loaded)
end
