# Colour Pipeline

FilmForge now treats color management as infrastructure rather than an afterthought.

## Import

`ImageImportService` uses ImageIO to read source metadata and attempts to preserve the embedded/source `CGColorSpace`. The loaded image is wrapped in `ColourManagedImage`, which stores:

- Original URL.
- `CIImage`.
- Pixel size.
- Source color space.
- Working color space.
- Output color space.
- Profile name.
- Raw ImageIO metadata.

If an image lacks usable embedded color data, the app falls back to sRGB.

## Working Space

The preview/export renderer uses:

- Extended sRGB working color space where available.
- `CIFormat.RGBAh` working format.
- Explicit output color space at `createCGImage`.

This keeps intermediate operations in a higher precision path than 8-bit display output, reducing avoidable banding and clipped-looking gradients.

## Display And Export

Preview output is rendered to `RGBA8` for `NSImage` display, but from an `RGBAh` Core Image graph.

Export output currently writes JPG/PNG with:

- The processed full-resolution render.
- The chosen output color profile name.
- JPG quality at 0.92.

The important rule is that export never reuses the preview image. It reruns the pipeline at full source resolution.

## Scene vs Display Referred

The current pipeline is display-referred because imported consumer photos are already typically display-referred JPG/HEIC/PNG assets. Internally, FilmForge avoids doing everything in 8-bit display output by keeping CI intermediates in half-float. Future RAW support should introduce a scene-referred path before film rendering:

1. Decode RAW.
2. Camera input profile.
3. Linear scene space.
4. Exposure and white balance.
5. Film/camera emulation.
6. Display/output transform.

## Clipping And Banding Rules

- Prefer tone/LUT/channel transforms before destructive clamps.
- Keep halation and bloom separate so highlight glow does not flatten the whole image.
- Use generated LUTs and custom kernels in the working graph, then convert only at preview/export boundary.
- Avoid repeated `RGBA8` round trips.

References:

- [Apple ColorSync overview](https://developer.apple.com/library/archive/technotes/tn2313/_index.html)
- [Core Image workingColorSpace](https://developer.apple.com/documentation/coreimage/cicontextoption/workingcolorspace)
- [Core Image workingFormat](https://developer.apple.com/documentation/coreimage/cicontextoption/workingformat)
- [Core Image RGBAh](https://developer.apple.com/documentation/CoreImage/CIFormat/RGBAh)
- [ImageIO profile name](https://developer.apple.com/documentation/imageio/kcgimagepropertyprofilename)

