⚡ Thumbp: A Lightweight & Fast WebP Thumbnail Image Generator
==============================================================

[![Hex.pm](https://img.shields.io/hexpm/v/thumbp.svg)](https://hex.pm/packages/thumbp)
[![Hexdocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/thumbp/)
[![Hex.pm](https://img.shields.io/hexpm/dt/thumbp.svg)](https://hex.pm/packages/thumbp)
[![License](https://img.shields.io/hexpm/l/thumbp.svg)](https://github.com/ryochin/thumbp/blob/main/LICENSE)

Thumbp is a highly efficient thumbnail creation library for Elixir, designed to output with the [WebP](https://developers.google.com/speed/webp) image format for optimal speed and performance.

No need for ImageMagick, FFmpeg, libvips, or any other external libraries.

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

> [!Tip]
> The `quality` and `target_size` options are exclusive.

Installation
------------

The package can be installed by adding `thumbp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:thumbp, "~> 0.1.0"}
  ]
end
```

Then, run `mix deps.get`.

Benchmark
---------

* Input: [1280x960 JPEG](https://github.com/ryochin/thumbp/blob/main/test/assets/images/sample.jpg) (85% quality), 171.5KB
* Output: 320x240 WebP (50% quality), ~2.4KB

```sh
mix run benchmark/benchmark.exs
```

```text
Name                      ips        average  deviation         median         99th %
thumbp                 141.09        7.09 ms     ±1.82%        7.07 ms        7.54 ms
image (libvips)        113.41        8.82 ms     ±5.13%        8.66 ms       10.60 ms

Comparison:
thumbp                 141.09
image (libvips)        113.41 - 1.24x slower +1.73 ms
```

on Apple M4 (10) @ 4.46 GHz

Development
-----------

### Prerequisites

> [!NOTE]
> This library requires the [Rust](https://www.rust-lang.org/) Toolchain for compilation.

Follow the instructions at [www.rust-lang.org/tools/install](https://www.rust-lang.org/tools/install) to install Rust.

Verify the installation by checking the `cargo` command version:

```sh
cargo --version
# Should output something like: cargo 1.82.0 (8f40fc59f 2024-08-21)
```

Then, set the `RUSTLER_PRECOMPILATION_EXAMPLE_BUILD` environment variable to ensure that local sources are compiled instead of downloading a precompiled library file.

```sh
RUSTLER_PRECOMPILATION_EXAMPLE_BUILD=1 mix compile
```

License
-------

The MIT License
