# FilmForge Architecture

FilmForge is a native macOS SwiftUI app with a Core Image-first processing engine. The important boundary is that SwiftUI owns interaction and presentation, while the film engine owns all image-processing decisions.

## Current App Shape

- `FilmForgeApp`: app entry point, window setup, and menu commands.
- `EditorViewModel`: editor state, import/export orchestration, selected profile, user adjustments, preview rendering.
- `EditorView`: three-panel interface with profile browser, center preview, and inspector controls.
- `ImageImportService`: AppKit open panel and image decoding.
- `ExportService`: AppKit save panel and Image I/O JPG/PNG writing.
- `PreviewRenderer`: shared `CIContext`, preview rendering, and full-resolution export rendering.
- `ImagePipeline`: reusable ordered list of Core Image stages.
- `ProfileCatalog`: camera profiles, film stock responses, and the recipe composer.

## Film Engine

The engine is built around recipe data and small pipeline stages:

```swift
protocol PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage
}
```

`CameraProfile` contains capture-device behavior: format, optics, vignette, sharpness, softness, sensor/flash behavior, borders, and digital downsample. `FilmStock` contains emulsion/sensor response: tone scale, color palette, saturation, grain, halation, bloom, and monochrome/slide/instant behavior. `ProfileCatalog.makeProfile(camera:film:)` composes those into a `FilmProfile` for rendering.

`FilmRecipe` contains recipe values for color, tone, grain, bloom, halation, vignette, lens behavior, aberration, dust, and borders. The UI never contains camera- or film-specific filter logic.

## Pipeline Order

1. Preview sizing
2. Profile downsample/old-digital treatment
3. Exposure, temperature, and tint
4. Base color transform
5. CMY-style split tone and color bias
6. Tone curve
7. Bloom
8. Halation
9. Lens softness/sharpening
10. Chromatic aberration
11. Vignette
12. Grain/noise
13. Dust
14. Border/frame

Preview and export use the same pipeline. Preview renders at a bounded long edge; export renders at full image resolution.

## Why Core Image First

Core Image gives the MVP a native, dependency-light, GPU-capable filter graph for still-image processing. It covers the current proof-of-concept effects well enough to demonstrate the product: color controls, tone curves, bloom, blurs, compositing, random noise, vignette, and Image I/O integration.

Metal should remain an implementation detail behind future stages for effects that need more precision: selective HSL, seeded grain, edge-aware halation, radial chromatic aberration, and toy-lens distortion.

## Known First-Build Tradeoffs

- Preview rendering currently uses the shared renderer directly after a short debounce. A dedicated render worker actor should be added as the next performance step.
- Grain and dust are procedural, but not yet seed-stable across repeated renders.
- Halation is highlight-mask based, not fully edge-aware.
- Chromatic aberration is a subtle channel-offset approximation.
- Borders are generated cleanly, but paper texture is not yet simulated.
