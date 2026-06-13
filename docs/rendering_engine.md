# FilmForge Rendering Engine

FilmForge is now structured as a reusable camera/film rendering engine with SwiftUI as the shell, not as a pile of view-owned filters.

## Runtime Shape

The current rendering path is:

1. `ImageImportService`
   - Loads the original through ImageIO/Core Image.
   - Keeps the original `CIImage`, pixel size, embedded/source color space, output color space, profile name, and metadata in `ColourManagedImage`.
   - Does not destructively modify the source image.

2. `EditorViewModel`
   - Owns non-destructive state: selected camera, selected film, user adjustments, preview/original toggle, export format.
   - Debounces preview rendering and sends immutable render requests to `RenderWorker`.

3. `RenderWorker`
   - Actor-isolated render boundary.
   - Caches previews by source image identity, profile id, adjustments, and preview size.
   - Keeps rendering off the main actor.

4. `PreviewRenderer`
   - Uses a shared `CIContext`.
   - Runs `RGBAh` as the working format.
   - Produces low-resolution previews and full-resolution export renders through the same `ImagePipeline`.

5. `ImagePipeline`
   - Runs ordered `PipelineStage` values.
   - Stages declare a backend:
     - `builtInCoreImage`
     - `customCoreImageKernel`
     - `metalShader`
     - `cpuFallback`
   - This gives Metal stages a first-class slot without changing profile recipes or SwiftUI.

## Current Stage Order

1. `PreviewSizingStage`
2. `DownsampleStage`
3. `ExposureTemperatureStage`
4. `LUTStage`
5. `BaseColorStage`
6. `SplitToneStage`
7. `FilmicResponseStage`
8. `ToneCurveStage`
9. `BloomStage`
10. `HalationStage`
11. `LensStage`
12. `ChromaticAberrationStage`
13. `VignetteStage`
14. `GrainStage`
15. `DustStage`
16. `BorderStage`

This is intentionally layered. A camera body can contribute lens softness, aberration, downsample, vignette, dust, and border behavior; a film stock contributes tone response, LUT color behavior, grain, halation, bloom, monochrome behavior, and print/instant framing.

## Backend Strategy

Core Image remains the graph and preview/export orchestration layer. It is good at color transforms, tone curves, masks, blurs, compositing, and image IO integration.

Custom CI kernels are now used for:

- Filmic toe/shoulder response.
- Luminance-dependent procedural grain.

Metal should be introduced where quality or performance justifies it:

- High-quality grain with blue-noise or precomputed tile textures.
- Halation with better highlight-edge sampling.
- Multi-scale bloom at large image sizes.
- Chromatic aberration and lens distortion in one pass.

Sources that guided this direction:

- [Apple CIContext](https://developer.apple.com/documentation/coreimage/cicontext)
- [Apple CIImageProcessorKernel](https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel)
- [Apple Metal Core Image kernels reference](https://developer.apple.com/metal/MetalCIKLReference6.pdf)
- [WWDC: Build Metal-based Core Image kernels](https://developer.apple.com/videos/play/wwdc2020/10021/)

## Quality Bar

Profiles should differ through recipe structure, not just contrast/saturation:

- Camera body: capture format, lens softness, edge behavior, aberration, vignette, sensor/cheap optic defects.
- Film stock: generated LUT, channel bias, toe/shoulder curve, grain size/response, halation, bloom, monochrome/slide/negative behavior.
- Export: full-res render, color-managed output, and no dependence on preview raster.

