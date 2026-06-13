# Profile Recipe Format

FilmForge profiles are composed from a camera recipe plus a film recipe.

## Main Types

`CameraProfile`

- Identity and display text.
- Capture format: `135`, `120`, half-frame, instant, toy, disposable, CCD.
- Camera/body recipe.

`FilmStock`

- Identity and display text.
- Film family: color negative, slide, black and white, instant, digital sensor.
- Film recipe.
- Recipe behavior:
  - `composeWithCamera` for generic reusable reference stocks.
  - `completeProfile` for authored camera-specific film/mode profiles.

`FilmProfile`

- The selected camera + camera-owned film/mode profile actually rendered by the engine.
- Produced by `ProfileCatalog.makeProfile(camera:film:)`.

`FilmRecipe`

- `color`
- `luts`
- `tone`
- `grain`
- `bloom`
- `halation`
- `vignette`
- `lens`
- `aberration`
- `dust`
- `border`

## Colour Recipe

`ColorRecipe` includes:

- Exposure, brightness, contrast, saturation.
- Temperature and tint.
- Per-channel red/green/blue bias.
- Shadow and highlight colour response.
- CMY-style subtractive shifts.
- Monochrome flag.

These fields drive both ordinary Core Image stages and generated LUT creation.

## LUT Recipe

`LUTRecipe` supports:

- `generatedProfile`: internally generated 3D LUT from the composed camera/film recipe.
- `cubeFile(path)`: file-backed `.cube` LUT loading.
- Dimension.
- Strength.

The active `LUTStage` can apply multiple LUT recipes in sequence. Current stock profiles use generated internal LUTs, which allows camera and film values to feed a genuine color transform stage instead of only slider filters.

Reference:

- [Apple CIColorCube](https://developer.apple.com/documentation/coreimage/cicolorcube)

## Camera-Owned Modes

The product model now prefers camera-owned modes over global film stock overlays. `ProfileCatalog.compatibleFilms(for:)` first asks for authored modes for the selected camera. Those authored modes are complete profile recipes and are not recomposed generically at render time.

Examples:

- `Lomo LC-A / X-Pro Slide` is tuned as a Lomo-specific cross-process look, not just Velvia pasted onto a Lomo body.
- `Polaroid SX-70 / Expired SX-70` is tuned as SX-70 chemistry and frame behavior.
- `Game Boy Camera / DMG Green` is a camera media mode, not a film stock.
- `FXN R / Amber Cafe` is an app-camera inspired digital mode.
- Fisheye options exist only on camera identities where that lens behavior feels plausible: Lomo/toy/disposable style profiles.

## Fallback Composition Rules

`RecipeComposer.combine` remains as a helper for building authored modes and for any future generic stock fallback. It merges camera and film values:

- Multiplicative values such as contrast, saturation, and RGB bias are multiplied.
- Additive values such as temperature, tint, CMY shifts, halation, bloom, grain, dust, and vignette are added or maxed depending on meaning.
- Monochrome survives if either side requests it.
- The camera border wins unless the camera has no border.
- The composed helper output receives a generated LUT recipe.

## Future Recipe Fields

The current format is intentionally ready for:

- Per-stage default slider ranges.
- Thumbnail generation parameters.
- Date stamp layout.
- Instant chemistry defects.
- Film borders and scan masks.
- True Metal stage identifiers.
- External LUT bundles.
- Profile versioning.
