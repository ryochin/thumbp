use rustler::types::tuple::make_tuple;
use rustler::{Binary, Encoder, Env, NifResult, OwnedBinary, Term};

use image::{imageops, DynamicImage, ImageBuffer, Rgb};
use libwebp_sys::WebPImageHint;
use webp::{Encoder as WebPEncoder, PixelLayout, WebPConfig, WebPMemory};

const DEFAULT_QUALITY: f32 = 60.0;

mod atoms {
    rustler::atoms! {
        ok
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn _create<'a>(
    env: Env<'a>,
    body: Binary<'a>,
    width: u32,
    height: u32,
    quality: Option<f32>,
    target_size: Option<u32>,
    effort: Option<u32>,
) -> NifResult<Term<'a>> {
    let config = webp_config(quality, target_size, effort)?;
    let bytes = body.as_slice();

    // JPEG fast path: use DCT-domain scale decoding so we only ever materialize the
    // pixels we actually need (down to 1/64 of the source area for 1/8 scale).
    let webp = match try_encode_jpeg_scaled(bytes, width, height, &config)? {
        Some(mem) => mem,
        None => encode_via_image_crate(bytes, width, height, &config)?,
    };

    binary_to_term(env, &webp)
}

fn try_encode_jpeg_scaled(
    bytes: &[u8],
    requested_width: u32,
    requested_height: u32,
    config: &WebPConfig,
) -> NifResult<Option<WebPMemory>> {
    if !is_jpeg(bytes) {
        return Ok(None);
    }
    if requested_width == 0
        || requested_height == 0
        || requested_width > u16::MAX as u32
        || requested_height > u16::MAX as u32
    {
        return Ok(None);
    }

    let mut decoder = jpeg_decoder::Decoder::new(std::io::Cursor::new(bytes));
    if decoder.read_info().is_err() {
        return Ok(None);
    }
    let src_info = match decoder.info() {
        Some(i) => i,
        None => return Ok(None),
    };
    if src_info.pixel_format != jpeg_decoder::PixelFormat::RGB24 {
        // L8 (grayscale) and CMYK32 are left to the generic `image` crate fallback.
        return Ok(None);
    }

    // Past this point the input is a recognized RGB JPEG -- we commit to the fast
    // path and propagate failures as errors instead of silently falling back.

    let (target_width, target_height) = calc_dimension_from(
        src_info.width as u32,
        src_info.height as u32,
        requested_width,
        requested_height,
    );

    // `jpeg-decoder::Decoder::scale` picks the smallest supported scale factor
    // (1, 1/2, 1/4, 1/8) that still yields an image at least as large as the
    // requested size. For a 1280x960 source downsized to 320x240 this lands
    // exactly on 1/4 scale and skips 15/16 of the IDCT work.
    decoder
        .scale(target_width as u16, target_height as u16)
        .map_err(|e| err_str(format!("JPEG scale failed: {e}")))?;

    let pixels = decoder
        .decode()
        .map_err(|e| err_str(format!("JPEG decode failed: {e}")))?;

    let decoded = decoder
        .info()
        .ok_or_else(|| err_str("JPEG info unavailable after decode".to_string()))?;
    let decoded_width = decoded.width as u32;
    let decoded_height = decoded.height as u32;

    let buf: ImageBuffer<Rgb<u8>, Vec<u8>> =
        ImageBuffer::from_raw(decoded_width, decoded_height, pixels)
            .ok_or_else(|| err_str("JPEG pixel buffer size mismatch".to_string()))?;

    let thumb_raw = if decoded_width == target_width && decoded_height == target_height {
        // DCT scale already landed on the exact target size; skip the resize step.
        buf.into_raw()
    } else {
        imageops::thumbnail(&buf, target_width, target_height).into_raw()
    };

    let mem = WebPEncoder::new(&thumb_raw, PixelLayout::Rgb, target_width, target_height)
        .encode_advanced(config)
        .map_err(|e| err_str(format!("{:?}", e)))?;
    Ok(Some(mem))
}

/// Fallback path via the `image` crate. Handles non-JPEG inputs (PNG, WebP, ...)
/// as well as JPEG variants the fast path rejects (CMYK, grayscale, oversized).
fn encode_via_image_crate(
    bytes: &[u8],
    requested_width: u32,
    requested_height: u32,
    config: &WebPConfig,
) -> NifResult<WebPMemory> {
    let image: DynamicImage = image::load_from_memory(bytes).map_err(|e| err_str(e.to_string()))?;

    let (target_width, target_height) = calc_dimension_from(
        image.width(),
        image.height(),
        requested_width,
        requested_height,
    );

    let (thumb_raw, pixel_layout) = match image {
        DynamicImage::ImageRgb8(buf) => {
            let thumb = imageops::thumbnail(&buf, target_width, target_height);
            (thumb.into_raw(), PixelLayout::Rgb)
        }
        other => {
            let rgba = other.into_rgba8();
            let thumb = imageops::thumbnail(&rgba, target_width, target_height);
            (thumb.into_raw(), PixelLayout::Rgba)
        }
    };

    let mem = WebPEncoder::new(&thumb_raw, pixel_layout, target_width, target_height)
        .encode_advanced(config)
        .map_err(|e| err_str(format!("{:?}", e)))?;
    Ok(mem)
}

fn binary_to_term<'a>(env: Env<'a>, webp: &WebPMemory) -> NifResult<Term<'a>> {
    let bytes: &[u8] = webp;
    let mut binary: OwnedBinary = OwnedBinary::new(bytes.len())
        .ok_or_else(|| err_str("failed to allocate binary".to_string()))?;

    binary.as_mut_slice().copy_from_slice(bytes);

    let ok = atoms::ok().encode(env);

    Ok(make_tuple(env, &[ok, binary.release(env).encode(env)]))
}

fn is_jpeg(bytes: &[u8]) -> bool {
    bytes.len() >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF
}

fn err_str(error: String) -> rustler::Error {
    rustler::Error::Term(Box::new(error))
}

fn webp_config(
    quality: Option<f32>,
    target_size: Option<u32>,
    effort: Option<u32>,
) -> NifResult<WebPConfig> {
    let mut config: WebPConfig =
        WebPConfig::new().map_err(|_| err_str("failed to create WebP config".to_string()))?;

    config.method = effort.map_or(3, |e| e as i32);
    config.image_hint = WebPImageHint::WEBP_HINT_PHOTO;
    config.sns_strength = 70;
    config.filter_sharpness = 2;
    config.filter_strength = 25;

    if let Some(size) = target_size {
        config.target_size = size as i32;
        config.pass = 5; // max iteration count
    } else if let Some(quality) = quality {
        config.quality = quality;
    } else {
        config.quality = DEFAULT_QUALITY;
    }

    Ok(config)
}

fn calc_dimension_from(src_width: u32, src_height: u32, width: u32, height: u32) -> (u32, u32) {
    if src_width >= src_height {
        // landscape
        let ratio = src_height as f32 / src_width as f32;
        let height = (ratio * width as f32).round() as u32;

        (width, height)
    } else {
        // portrait
        let ratio = src_width as f32 / src_height as f32;
        let width = (ratio * height as f32).round() as u32;

        (width, height)
    }
}

rustler::init!("Elixir.Thumbp");
