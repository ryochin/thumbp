defmodule ThumbpTest do
  use ExUnit.Case
  import Bitwise

  @width 180
  @height 120

  setup_all do
    {:ok,
     jpeg: File.read!("./test/assets/images/sample.jpg"),
     png: File.read!("./test/assets/images/sample.png"),
     portrait: File.read!("./test/assets/images/portrait.jpg")}
  end

  # -- basic creation --

  test "creates a thumbnail", %{jpeg: jpeg} do
    assert {:ok, _thumbnail} = Thumbp.create(jpeg, @width, @height)
  end

  test "creates a thumbnail with quality", %{jpeg: jpeg} do
    assert {:ok, _thumbnail} = Thumbp.create(jpeg, @width, @height, quality: 50)
  end

  test "creates a thumbnail with target size", %{jpeg: jpeg} do
    assert {:ok, _thumbnail} = Thumbp.create(jpeg, @width, @height, target_size: 5_000)
  end

  test "creates a thumbnail with effort", %{jpeg: jpeg} do
    assert {:ok, _thumbnail} = Thumbp.create(jpeg, @width, @height, effort: 5)
  end

  test "creates a thumbnail with quality and effort", %{jpeg: jpeg} do
    assert {:ok, _thumbnail} = Thumbp.create(jpeg, @width, @height, quality: 50, effort: 5)
  end

  # -- output format --

  test "output is valid WebP", %{jpeg: jpeg} do
    {:ok, thumbnail} = Thumbp.create(jpeg, @width, @height)
    assert <<"RIFF", _size::little-32, "WEBP", _rest::binary>> = thumbnail
  end

  # -- input formats --

  test "creates a thumbnail from PNG input", %{png: png} do
    {:ok, thumbnail} = Thumbp.create(png, 320, 240)
    assert {320, 240} == webp_dimensions(thumbnail)
  end

  # -- scale (landscape: 1280x960, aspect ratio 4:3) --

  test "scales landscape image to exact ratio match", %{jpeg: jpeg} do
    {:ok, thumbnail} = Thumbp.create(jpeg, 320, 240)
    assert {320, 240} == webp_dimensions(thumbnail)
  end

  test "scales landscape image preserving aspect ratio", %{jpeg: jpeg} do
    # landscape uses requested width; height = 0.75 * 160 = 120
    {:ok, thumbnail} = Thumbp.create(jpeg, 160, 160)
    assert {160, 120} == webp_dimensions(thumbnail)
  end

  test "scales landscape image to small thumbnail", %{jpeg: jpeg} do
    # height = 0.75 * 64 = 48
    {:ok, thumbnail} = Thumbp.create(jpeg, 64, 64)
    assert {64, 48} == webp_dimensions(thumbnail)
  end

  # -- scale (portrait: 720x960, aspect ratio 3:4) --

  test "scales portrait image preserving aspect ratio", %{portrait: portrait} do
    # portrait uses requested height; width = 0.75 * 240 = 180
    {:ok, thumbnail} = Thumbp.create(portrait, 320, 240)
    assert {180, 240} == webp_dimensions(thumbnail)
  end

  test "scales portrait image to square target", %{portrait: portrait} do
    # portrait uses requested height; width = 0.75 * 160 = 120
    {:ok, thumbnail} = Thumbp.create(portrait, 160, 160)
    assert {120, 160} == webp_dimensions(thumbnail)
  end

  # -- quality affects output size --

  test "lower quality produces smaller output", %{jpeg: jpeg} do
    {:ok, low} = Thumbp.create(jpeg, 320, 240, quality: 10)
    {:ok, high} = Thumbp.create(jpeg, 320, 240, quality: 90)
    assert byte_size(low) < byte_size(high)
  end

  # -- target size --

  test "target_size produces output within reasonable range", %{jpeg: jpeg} do
    target = 4_096
    {:ok, thumbnail} = Thumbp.create(jpeg, 320, 240, target_size: target)
    actual = byte_size(thumbnail)
    # libwebp target_size is best-effort; wide margin to avoid flaky CI
    assert actual < target * 3, "output #{actual} bytes far exceeds target #{target}"
  end

  # -- effort affects output size --

  test "effort boundary values produce valid WebP", %{jpeg: jpeg} do
    {:ok, fast} = Thumbp.create(jpeg, 320, 240, effort: 0)
    {:ok, slow} = Thumbp.create(jpeg, 320, 240, effort: 6)
    # size ordering is not guaranteed by libwebp; just verify valid output
    assert <<"RIFF", _::little-32, "WEBP", _::binary>> = fast
    assert <<"RIFF", _::little-32, "WEBP", _::binary>> = slow
  end

  # -- validation errors --

  test "returns an error with quality & target size", %{jpeg: jpeg} do
    assert {:error, "quality and target_size options are exclusive"} =
             Thumbp.create(jpeg, @width, @height, quality: 50, target_size: 5_000)
  end

  test "returns an error with unknown options", %{jpeg: jpeg} do
    assert {:error, "unknown options"} =
             Thumbp.create(jpeg, @width, @height, foo: 50, bar: 5_000)
  end

  test "returns an error with nil body" do
    assert {:error, "body must be a binary"} = Thumbp.create(nil, @width, @height)
  end

  test "returns an error with empty body" do
    assert {:error, "body must not be empty"} = Thumbp.create("", @width, @height)
  end

  test "returns an error with invalid image bytes" do
    assert {:error, "The image format could not be determined"} =
             Thumbp.create(<<0>>, @width, @height)
  end

  test "returns an error with negative width", %{jpeg: jpeg} do
    assert {:error, "width must be > 0"} = Thumbp.create(jpeg, -1, @height)
  end

  test "returns an error with negative height", %{jpeg: jpeg} do
    assert {:error, "height must be > 0"} = Thumbp.create(jpeg, @width, -1)
  end

  test "returns an error with non-numeric quality", %{jpeg: jpeg} do
    assert {:error, "quality must be a number"} =
             Thumbp.create(jpeg, @width, @height, quality: "50")
  end

  test "returns an error with negative quality", %{jpeg: jpeg} do
    assert {:error, "quality must be >= 0"} =
             Thumbp.create(jpeg, @width, @height, quality: -1)
  end

  test "returns an error with invalid quality", %{jpeg: jpeg} do
    assert {:error, "quality must be <= 100"} =
             Thumbp.create(jpeg, @width, @height, quality: 200)
  end

  test "returns an error with negative target_size", %{jpeg: jpeg} do
    assert {:error, "target_size must be > 0"} =
             Thumbp.create(jpeg, @width, @height, target_size: 0)
  end

  test "returns an error with negative effort", %{jpeg: jpeg} do
    assert {:error, "effort must be >= 0"} =
             Thumbp.create(jpeg, @width, @height, effort: -1)
  end

  test "returns an error with invalid effort", %{jpeg: jpeg} do
    assert {:error, "effort must be <= 6"} =
             Thumbp.create(jpeg, @width, @height, effort: 7)
  end

  # -- helpers --

  # VP8 lossy
  defp webp_dimensions(
         <<"RIFF", _size::little-32, "WEBP", "VP8 ", _chunk_size::little-32,
           _frame_tag::binary-size(3), 0x9D, 0x01, 0x2A, width_code::little-16,
           height_code::little-16, _rest::binary>>
       ) do
    {width_code &&& 0x3FFF, height_code &&& 0x3FFF}
  end

  # VP8L lossless
  defp webp_dimensions(
         <<"RIFF", _size::little-32, "WEBP", "VP8L", _chunk_size::little-32, 0x2F,
           bits::little-32, _rest::binary>>
       ) do
    {(bits &&& 0x3FFF) + 1, (bits >>> 14 &&& 0x3FFF) + 1}
  end

  # VP8X extended
  defp webp_dimensions(
         <<"RIFF", _size::little-32, "WEBP", "VP8X", _chunk_size::little-32,
           _flags::binary-size(4), width_minus1::little-24, height_minus1::little-24,
           _rest::binary>>
       ) do
    {width_minus1 + 1, height_minus1 + 1}
  end

  defp webp_dimensions(
         <<"RIFF", _size::little-32, "WEBP", chunk_type::binary-size(4), _rest::binary>>
       ) do
    flunk("unsupported WebP chunk type: #{inspect(chunk_type)}")
  end

  defp webp_dimensions(other) do
    flunk(
      "not a valid WebP binary (first 16 bytes: #{inspect(binary_part(other, 0, min(16, byte_size(other))))})"
    )
  end
end
