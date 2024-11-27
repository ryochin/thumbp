use rustler::types::tuple::make_tuple;
use rustler::{Binary, NifResult, Env, Term, OwnedBinary, Encoder};

use image::DynamicImage::{self, ImageRgba8};
use image::{imageops, EncodableLayout};
use libwebp_sys::WebPImageHint;
use webp::{Encoder as WebPEncoder, WebPConfig};

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
) -> NifResult<Term<'a>> {
    let image: DynamicImage =
        image::load_from_memory(body.as_slice()).map_err(|e| err_str(e.to_string()))?;

    let (width, height) = calc_dimension(&image, width, height);

    let thumbnail: DynamicImage = ImageRgba8(imageops::thumbnail(&image, width, height));

    let encoder: WebPEncoder =
        WebPEncoder::from_image(&thumbnail).map_err(|e| err_str(e.to_string()))?;

    let webp = encoder
        .encode_advanced(&webp_config(quality, target_size)?)
        .map_err(|e| err_str(format!("{:?}", e)))?;

    let bytes: &[u8] = webp.as_bytes();

    let mut binary: OwnedBinary = OwnedBinary::new(bytes.len())
        .ok_or_else(|| err_str("failed to allocate binary".to_string()))?;

    binary.as_mut_slice().copy_from_slice(&bytes);

    let ok = atoms::ok().encode(env);

    Ok(make_tuple(env, &[ok, binary.release(env).encode(env)]))
}

fn err_str(error: String) -> rustler::Error {
    rustler::Error::Term(Box::new(error))
}

fn webp_config(quality: Option<f32>, target_size: Option<u32>) -> NifResult<WebPConfig> {
    let mut config: WebPConfig =
        WebPConfig::new().map_err(|_| err_str("failed to create WebP config".to_string()))?;

    config.method = 2;
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

fn calc_dimension(image: &DynamicImage, width: u32, height: u32) -> (u32, u32) {
    if image.width() >= image.height() {
        // landscape
        let ratio = image.height() as f32 / image.width() as f32;
        let height = (ratio * width as f32).round() as u32;

        (width, height)
    } else {
        // portrait
        let ratio = image.width() as f32 / image.height() as f32;
        let width = (ratio * height as f32).round() as u32;

        (width, height)
    }
}

rustler::init!("Elixir.Thumbp");
