# Changelog

## v0.2.0 (2026-04-13)

### Added

- JPEG DCT-domain scale decoding via `jpeg-decoder` crate. Decodes at 1/2, 1/4, or 1/8 resolution to skip up to 63/64 of the IDCT work. When the DCT scale matches the exact target size, the resize step is skipped entirely.
- `effort` option (0-6) to control WebP encoding speed/size tradeoff.

### Changed

- Avoided unnecessary RGBA channel promotion for RGB inputs (e.g. JPEG) during resize and WebP encoding.
- Refactored option handling in `create/4` from pattern-match enumeration to keyword list extraction with centralized validation.
- Updated CI workflow: runner images, action versions, pinned Rust toolchain, added NIF 2.17.

### Fixed

- Fixed documentation to reflect actual default quality of 60 (was incorrectly documented as 75).

## v0.1.5 (2024-12-15)

### Fixed

- Fixed typespec for `create/4`.
- Updated for dialyzer compatibility.

## v0.1.4 (2024-11-27)

### Changed

- Changed `config.method` to address quality issues, especially for smaller images.
- Reduced extra function calls in `create/4`.
- Set Rust version to 1.82.0.
- Upgraded hex packages and crates.

## v0.1.3 (2024-01-01)

### Changed

- Changed the native function to return a tuple directly.
- Upgraded hex packages.

## v0.1.2 (2023-12-01)

### Changed

- Downgraded Linux build base of precompiled binaries back to Ubuntu 20.04.
- Upgraded hex packages.

## v0.1.1 (2023-11-28)

### Added

- Introduced `rustler_precompiled` package for precompiled NIF binaries.

## v0.1.0 (2023-11-28)

### Added

- Initial release with WebP thumbnail generation via Rust NIF.
