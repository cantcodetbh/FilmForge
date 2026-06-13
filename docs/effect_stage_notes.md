# Effect Stage Notes

These notes describe how each effect should behave as FilmForge grows.

## LUT Stage

Current implementation:

- Generated internal 3D LUT from camera/film recipe.
- `.cube` parser for external 3D LUT files.
- Applied with `CIColorCubeWithColorSpace`.
- Mixed by profile strength and user intensity.

Future improvement:

- Tetrahedral interpolation in Metal for imported LUTs.
- 1D tone LUTs before 3D colour LUTs.
- Preview LUT cache keyed by profile recipe hash.

## Filmic Response

Current implementation:

- Custom CI color kernel.
- Adds toe/shoulder style response after LUT and split-tone stages.
- Uses tone curve endpoints, fade, bloom, and intensity to shape response.

Future improvement:

- Replace deprecated Core Image kernel language with Metal Core Image kernels.
- Add separate negative, print film, slide, instant, and CCD response kernels.

## Grain

Current implementation:

- Custom CI color kernel when available.
- Luminance-dependent.
- Profile scale controls clumping size.
- Mono or color grain.
- Shadow/highlight response from film recipe.
- Stable preview seed and randomized export seed.
- Core Image random overlay fallback remains.

Future improvement:

- Metal grain stage using blue-noise or scanned grain textures.
- Per-channel silver/dye-cloud simulation.
- Sensor-style chroma noise for CCD profiles.

## Halation

Current implementation:

- Separate from bloom.
- Isolates strong highlights.
- Multiplies highlight mask by edge response.
- Blurs mask.
- Applies warm red/orange screen blend.
- Avoids whole-image glow.

Future improvement:

- Metal pass that samples behind high-contrast highlight edges.
- Lens/film-specific halation radius and colour density.

## Bloom

Current implementation:

- Separate from halation.
- Thresholds bright areas.
- Uses multi-radius blur.
- Screen-blends subtly with weighted radii.

Future improvement:

- MPS/Metal multi-scale pyramid for large exports.
- Distinct night/digital bloom mode for CCD and compact camera profiles.

## Lens And Body

Current implementation:

- Profile-owned aspect/crop output before effects.
- Downsample/re-upsample for toy/low-fi capture.
- General softness.
- Edge-only softness mask.
- Mild barrel-style distortion for cheap/toy optics.
- Edge-weighted chromatic aberration.
- Optional fisheye accessory for authored toy/disposable modes.
- Vignette.
- Dust and scratches.
- Optional flash falloff.
- Optional disposable-style date stamp.
- Optional posterized/palette output for toy digital modes.
- Borders for instant, print, thin, and half-frame styles.

Future improvement:

- Better optical distortion model.
- Disposable flash falloff.
- Light leaks.
- Date stamp.
- Per-format crop masks.
- Scan gate/border texture assets.

## Non-Destructive Workflow

Current behavior:

- Original is retained.
- Preview is rendered separately.
- Full-res export reruns the pipeline.
- Profile changes do not mutate the image.
- Camera/mode output is primary.
- Lab adjustments are hidden by default and can reset to profile defaults.

Future behavior:

- Save/load project sessions.
- Split-view compare.
- Export cancellation/progress.
- Background batch export.
