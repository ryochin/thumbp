defmodule ThumbpTest do
  use ExUnit.Case

  @width 180
  @height 120

  setup_all do
    {:ok, content: File.read!("./test/assets/images/sample.jpg")}
  end

  test "creates a thumbnail", state do
    assert {:ok, _thumbnail} = Thumbp.create(state[:content], @width, @height)
  end

  test "creates a thumbnail with quality", state do
    assert {:ok, _thumbnail} = Thumbp.create(state[:content], @width, @height, quality: 50)
  end

  test "creates a thumbnail with target size", state do
    assert {:ok, _thumbnail} = Thumbp.create(state[:content], @width, @height, target_size: 5_000)
  end

  test "returns an error with empty body" do
    assert {:error, "The image format could not be determined"} =
             Thumbp.create(<<0>>, @width, @height)
  end

  test "returns an error with negative width", state do
    assert {:error, "width must be > 0"} = Thumbp.create(state[:content], -1, @height)
  end

  test "returns an error with negative height", state do
    assert {:error, "height must be > 0"} = Thumbp.create(state[:content], @width, -1)
  end

  test "returns an error with negative quality", state do
    assert {:error, "quality must be >= 0"} =
             Thumbp.create(state[:content], @width, @height, quality: -1)
  end

  test "returns an error with invalid quality", state do
    assert {:error, "quality must be <= 100"} =
             Thumbp.create(state[:content], @width, @height, quality: 200)
  end

  test "returns an error with negative target_size", state do
    assert {:error, "target_size must be > 0"} =
             Thumbp.create(state[:content], @width, @height, target_size: 0)
  end
end
