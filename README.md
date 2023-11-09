⚡ Thumbp: Ultra-Fast WebP Thumbnail Generator for Elixir
========================================================

Thumbp is a highly efficient thumbnail creation library for Elixir, designed to output with the [WebP](https://developers.google.com/speed/webp) image format for optimal speed and performance.

Prerequisites
-------------

**Note:** This library requires the [Rust](https://www.rust-lang.org/) Toolchain for compilation.

Follow the instructions at [www.rust-lang.org/tools/install](https://www.rust-lang.org/tools/install) to install Rust.

Verify the installation by checking the `cargo` command version:

```sh
cargo --version
# Should output something like: cargo 1.68.1 (115f34552 2023-02-26)
```

That's all. No need for ImageMagick, FFmpeg, libvips, or any other external libraries.

Installation
------------

The package can be installed by adding `thumbp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:thumbp, "~> 0.1.0", github: "ryochin/thumbp"}
  ]
end
```

Then, run `mix deps.get`.

Usage
-----

Read an image file and create a thumbnail:

```elixir
iex> content = File.read!("./test/assets/images/sample.jpg")
iex> Thumbp.create(content, 320, 240)
{:ok, <<82, 73, 70, 70, 195, 152, 14, 0, 0, 87, 69, ...>>}
```

The `width` and `height` parameters represent the potential maximum sizes, so they do not precisely define the actual dimensions of the image. This implies that the aspect ratio of the image will remain unchanged.

Adjust the quality with an optional parameter ranging from 0 to 100 (default is 75):

```elixir
iex> Thumbp.create(content, 160, 120, quality: 50)
```

You can also define a target size, although which may increase the processing time by approximately 20-80%.

```elixir
iex> Thumbp.create(content, 160, 120, target_size: 4_096)    # set to 4KB
```

**Note:** The `quality` and `target_size` options are exclusive.

Benchmark
---------

* Input: 1280x960 JPEG (85% quality), 171.5KB
* Output: 320x240 WebP (50% quality), ~2.2KB

```sh
mix run benchmark/benchmark.exs
```

```text
Name                      ips        average  deviation         median         99th %
thumbp                  67.46       14.82 ms    ±10.06%       14.50 ms       22.86 ms
image (libvips)         19.41       51.52 ms    ±14.68%       50.01 ms       77.67 ms

Comparison:
thumbp                  67.46
image (libvips)         19.41 - 3.48x slower +36.70 ms
```
