# FilmForge Film Filter Research

Research date: 2026-06-13

FilmForge should be a native macOS photo editor that imports existing photos, applies original camera/film-inspired recipes, lets the user tune a small set of controls, and exports JPG/PNG without altering the source file. The research conclusion is clear: build a reusable recipe-driven image engine first, then attach SwiftUI controls to that engine. Do not model profiles as one-off UI filters.

## Research Sources

- Apple Core Image overview: built-in filters can be chained into complex effects and can run through GPU-backed render paths. <https://developer.apple.com/documentation/coreimage>
- Apple Core Image Programming Guide: Core Image works with Core Graphics, Core Video, and Image I/O image data, using GPU or CPU rendering paths behind a high-level API. <https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html>
- Apple Core Image Filter Reference: confirms available built-in filters for blur, color adjustment, compositing, vignette, bloom, tone curve, color cube, and generator workflows. <https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/>
- Apple CIColorCube docs: Core Image supports color-cube LUT-style transforms. <https://developer.apple.com/documentation/coreimage/cicolorcube>
- Apple Image I/O docs: Image I/O reads/writes common image formats, supports color management, and exposes metadata. <https://developer.apple.com/documentation/imageio>
- Apple Open/Save Panels guide: macOS apps should use standard open and save panels for user-controlled file access. <https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/UsingtheOpenandSavePanels/UsingtheOpenandSavePanels.html>
- Apple Metal Core Image kernels reference: custom Core Image kernels can be written in Metal Shading Language when built-in filters are insufficient. <https://developer.apple.com/metal/MetalCIKLReference6.pdf>
- Apple WWDC 2020, Build Metal-based Core Image kernels with Xcode: explains integrating and loading Metal Core Image kernels. <https://developer.apple.com/videos/play/wwdc2020/10021/>
- GPUImage3: Swift/Metal GPU image processing library for Mac and iOS. <https://github.com/BradLarson/GPUImage3>
- The Darkroom, halation explanation: halation is glow/bleed from bright areas around darker edges caused by light reflecting through film layers. <https://thedarkroom.com/what-is-halation/>
- Darkroom, bloom and halation product notes: modern photo apps expose bloom and halation as separate controls, with halation usually warm/red-orange around high-contrast highlights. <https://darkroom.co/blog/2025-12-08-bloom-halation>
- Dehancer, halation notes: film halation appears as a red-orange halo near overexposed contrasting boundaries and bright light sources. <https://www.dehancer.com/learn/articles/halation-in-dehancer>
- Digital Photography School, chromatic aberration: CA is lens color fringing where wavelengths focus differently, often visible along high-contrast edges. <https://digital-photography-school.com/chromatic-aberration-what-is-it-and-how-to-avoid-it/>

## How Vintage Camera And Film Apps Create Looks

Most convincing vintage looks are layered. A good profile usually combines global color/tone behavior, local light behavior, texture, optical defects, and presentation artifacts. A single saturation/contrast filter produces a generic effect; a recipe produces something that feels like a camera.

### LUTs And Color Transforms

LUTs map input colors to output colors. In film apps they are often used for the base color identity: shifted primaries, altered neutrals, muted blues, greener shadows, warmer skin tones, or slide-film saturation. On Apple platforms, `CIColorCube` and `CIColorCubeWithColorSpace` are the natural path for 3D LUT-style transforms. For FilmForge v1, hardcoded external `.cube` import is not required, but the engine should include a `LUTStage` or `ColorCubeStage` protocol slot so LUTs can be added later.

MVP approach:

- Use Core Image color controls, matrix transforms, hue/saturation controls, and optional generated color cubes.
- Represent color transform settings as data inside `FilmRecipe`.
- Keep all color transforms outside SwiftUI view code.

### Tone Curves, RGB Curves, And Contrast Shaping

Film looks rely heavily on curves. Useful patterns include:

- Lifted blacks for faded print or instant looks.
- Soft highlight rolloff for color negative profiles.
- Steeper midtone contrast for slide or black-and-white profiles.
- Per-channel RGB curves for warm highlights, cool shadows, green-tinted night shadows, or red toy-camera casts.

Core Image includes `CIToneCurve`, `CIColorControls`, `CIExposureAdjust`, `CIGammaAdjust`, and related color filters. `CIToneCurve` can cover many MVP recipes with five control points. Per-channel curves may need either chained color-matrix techniques, `CIColorPolynomial`, a generated LUT, or later a custom kernel.

MVP approach:

- Use `CIToneCurve` for luminance-style contrast.
- Use `CIColorControls`/`CIExposureAdjust` for user exposure and contrast.
- Use `CIColorMatrix` or generated color cube for RGB color bias.
- Defer sophisticated per-channel curve editing until after the engine abstraction exists.

### CMYK-Style Subtractive Adjustments

Many film/photo apps mimic subtractive print behavior even if they do not expose CMYK. This means colors are not just shifted with RGB gains; yellow, cyan, and magenta relationships are altered in a way that changes skin, foliage, sky, and neutral paper tone separately. Core Image does not need to run in CMYK for the MVP. Similar behavior can be approximated with selective HSL adjustments, color matrices, and LUT/color-cube transforms.

MVP approach:

- Model this as a `SelectiveColorStage`, even if v1 implements it with approximate hue masks or LUTs.
- Use profile-level settings such as `shadowTint`, `highlightTint`, `skinWarmth`, `greenShift`, and `blueShift`.

### HSL Selective Adjustments

Selective hue, saturation, and luminance controls create profile personality:

- Slide film: deeper greens/blues, restrained reds, higher saturation.
- Faded print: lower saturation, warmer yellows, muted blues.
- CCD: cyan/blue bias, clipped highlights, harsh channel response.
- Disposable: uneven saturation, flash-like warmth, rough reds.

Core Image has hue and vibrance-style filters, but selective HSL usually needs masks or a custom kernel/LUT. Generated LUTs are a practical bridge.

MVP approach:

- Use simple profile-wide saturation and vibrance controls first.
- Add a generated color cube for selective hue behavior when the profile needs stronger identity.

### Highlight Rolloff And Lifted Blacks

Film-like tone often comes from compressing highlights and shaping shadows. Color negative profiles should avoid brittle digital clipping; slide, CCD, and disposable profiles may intentionally clip or crush more. Lifted blacks make prints and instant photos feel aged or paper-like.

MVP approach:

- Use tone curve points to define black lift and highlight shoulder.
- Add a profile flag for `highlightBehavior`: `softShoulder`, `cleanClip`, `flashClip`, or `bloomProtected`.

### White Balance And Tint Shifts

Temperature and tint controls should be global user controls layered over the profile base. The profile can also define default warmth/coolness:

- Warm Negative: warm highlights and skin.
- Rainy CCD: cool temperature and slight green/cyan bias.
- Night Kiosk: green shadows and sodium-like warm highlights.

MVP approach:

- Use Core Image temperature/tint style filters where available, or a color matrix fallback.
- Apply user temperature/tint after the base recipe but before grain and optical effects.

### Film Grain

Convincing grain is not a flat noise layer. It should vary by profile, scale with output size, and ideally respond to luminance. Grain can be monochrome or color; fine or coarse; stronger in shadows/midtones or cleaner in highlights depending on the recipe. Digital CCD noise should feel different from film grain: more chroma noise, blockier sharpness, and less organic rolloff.

Core Image includes random/noise generator filters and compositing filters. A custom grain stage can generate noise once per preview size, crop it to the image extent, adjust contrast/scale, then blend based on luminance masks.

MVP approach:

- Generate procedural noise with Core Image.
- Blur/scale the noise to control grain size.
- Use blend/compositing filters at low opacity.
- Add a luminance mask so grain does not look like a uniform screen overlay.
- Use full-resolution procedural generation during export.

### Halation

Halation is warm red/orange glow near bright, high-contrast boundaries. It should not be the same as bloom. Bloom is a general soft glow from bright regions; halation is warmer, edge-sensitive, and more localized around bright/dark transitions.

MVP approach:

- Create a highlight mask using threshold/contrast shaping.
- Optionally combine with an edge mask.
- Blur the mask.
- Tint red/orange.
- Blend back subtly with screen/soft-light style compositing.
- Keep the slider range conservative.

### Bloom

Bloom simulates light spreading from bright areas through lenses/sensors/emulsion. It is useful for night lights, instant highlights, and compact-camera flash. Core Image has `CIBloom`, but a custom multi-radius bloom can look better later.

MVP approach:

- Start with `CIBloom` or a masked gaussian blur plus screen blend.
- Profile settings should include threshold, radius, intensity, and warmth.
- Apply bloom before final grain so texture remains coherent.

### Vignette

Vignette is radial darkening or color shift toward the edges. Disposable, toy lens, and compact profiles can use heavier vignette; slide/negative profiles should be subtle.

MVP approach:

- Use `CIVignette` or `CIVignetteEffect`.
- Expose user vignette amount while retaining profile-defined radius/softness.

### Chromatic Aberration

Chromatic aberration is color fringing caused by wavelengths focusing differently, usually visible on high-contrast edges. In a stylized app it should be subtle and often stronger near the edges than the center.

MVP approach:

- For v1, approximate with tiny red/cyan channel offsets or transformed duplicate layers masked toward image edges.
- Keep disabled or very subtle except in `Rainy CCD`, `Toy Lens Red`, and `Mini DV Still`.
- A proper per-channel edge-aware implementation can be a custom Metal/Core Image kernel later.

### Lens Softness And Toy Camera Distortion

Lens softness can be global or edge-biased. Toy cameras often have blurred corners, distorted geometry, color casts, and vignetting. Core Image can do gaussian blur and radial masks; distortion filters can be added sparingly.

MVP approach:

- Global softness: small blur blended back with the original.
- Edge softness: blur duplicate image and blend it using radial edge mask.
- Toy distortion: defer heavy geometry distortion until the core recipe engine is stable.

### Dust, Scratches, Borders, Date Stamps, Light Leaks

These are presentation artifacts. They should be optional overlay stages, not baked into color profiles. Assets must be original. Procedural overlays are preferable for v1 because they avoid licensing issues and keep the app self-contained.

MVP approach:

- Dust: sparse random white/dark specks from thresholded noise.
- Scratches: procedural thin vertical/diagonal lines with low opacity.
- Borders: generated rectangles/rounded instant frames in Core Image or Swift drawing.
- Light leaks: gradient/noise masks tinted warm, profile-controlled.
- Date stamps: later-stage text overlay, off by default.

### Instant Film Frames

Instant profiles need image treatment and frame treatment. The white border should be generated independently so the user can toggle it without changing the underlying image recipe.

MVP approach:

- `BorderStage` adds canvas padding and background color.
- Recipe defines bottom-heavy instant border dimensions.
- Export respects border toggle.

### CCD / Old Digital Looks

Old digital compact-camera looks are not film looks. They tend to include limited dynamic range, clipped highlights, cool/cyan white balance, sharpening halos, chroma noise, low resolution or compression-like behavior, and occasional chromatic fringing.

MVP approach:

- Tone curve with hard highlight clipping.
- Cooler white balance and green/cyan shadow bias.
- Chroma noise rather than monochrome grain.
- Optional mild downsample/upsample preview/export stage for `Mini DV Still`.

## Camera Profile Model

Each profile should be a layered recipe. This avoids hardcoded filters stapled to a window and makes profiles testable, reusable, exportable, and tunable.

Suggested core types:

```swift
struct FilmProfile: Identifiable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let recipe: FilmRecipe
    let defaultAdjustments: UserAdjustments
    let availableControls: Set<AdjustmentControl>
}

struct FilmRecipe: Hashable {
    var color: ColorRecipe
    var toneCurve: ToneCurveRecipe
    var saturation: SaturationRecipe
    var grain: GrainRecipe
    var halation: HalationRecipe
    var bloom: BloomRecipe
    var vignette: VignetteRecipe
    var lens: LensRecipe
    var aberration: AberrationRecipe?
    var dust: DustRecipe?
    var border: BorderRecipe?
    var crop: CropRecipe?
}
```

Pipeline stage examples:

- `ColorStage`
- `ToneCurveStage`
- `SelectiveColorStage`
- `BloomStage`
- `HalationStage`
- `VignetteStage`
- `LensSoftnessStage`
- `ChromaticAberrationStage`
- `GrainStage`
- `DustStage`
- `BorderStage`
- `ExportStage`

Important modeling rule: user controls should modulate recipe values, not replace the recipe. For example, the grain slider scales the recipe grain amount and may also scale grain size for specific profiles. The bloom slider scales recipe bloom intensity while preserving profile threshold/radius defaults.

## Initial Original Profile Direction

The first 12 profiles can be data-defined recipes:

| Profile | Base Identity | Notable Stages |
| --- | --- | --- |
| Pocket 35 | Warm compact 35mm | mild S-curve, warm highlights, fine grain, slight vignette |
| Corner Shop Disposable | Flashy disposable | punchy contrast, warm flash bias, rough grain, stronger vignette |
| Rainy CCD | Early 2000s compact digital | cool/cyan cast, clipped highlights, chromatic edge, chroma noise |
| Summer Slide | Slide-film inspired | high saturation, deeper contrast, rich greens/blues, clean fine grain |
| Soft Instant | Instant photo | creamy highlights, lifted blacks, warm tint, white border |
| Half Frame Diary | Travel half-frame | muted colors, slight softness, optional crop/border |
| Toy Lens Red | Toy camera | red cast, heavy vignette, edge blur, uneven saturation |
| Faded Family Album | Aged print | low contrast, warm paper tone, dust/scratches, lifted blacks |
| Night Kiosk | Low-light street compact | green shadows, warm highlights, glow around lights, heavier noise |
| Warm Negative | Consumer color negative | soft shoulder, warm skin, natural grain, moderate saturation |
| Mini DV Still | Y2K video still | lower-res feel, sharp digital edges, chroma noise, clipped channels |
| Black Coffee Mono | Warm black-and-white | monochrome conversion, contrast curve, grain, lifted paper fade |

These are original names and should not reference real camera/film trademarks in code, UI, or docs except as general research concepts.

## Technical Approaches For macOS

### SwiftUI + Core Image

Best MVP choice. SwiftUI can own app state and layout; Core Image can own image operations. Core Image has the right primitives for most v1 stages: color adjustment, tone curve, bloom, vignette, blur, compositing, noise generation, crop, affine transforms, and color cube transforms. It also integrates naturally with `CIImage`, `CGImage`, `NSImage`, and Image I/O.

Pros:

- Native macOS app feel.
- Fewer dependencies.
- Good enough GPU acceleration for still-image preview/export.
- Built-in filter graph fits a staged pipeline.
- Easier to ship and maintain.

Cons:

- Some selective color and chromatic aberration effects are awkward without custom kernels.
- SwiftUI image rendering can be inefficient if previews are not managed carefully.
- Need explicit preview-size rendering to avoid UI stalls.

### SwiftUI + Metal Custom Shaders

Useful later, not the first foundation. Metal is appropriate for custom per-pixel effects like selective HSL, high-quality grain, edge-aware halation, channel offsets, lens distortion, and performance-critical preview rendering.

Pros:

- Maximum control.
- Better for effects Core Image does not express cleanly.
- Can optimize hot paths.

Cons:

- Higher complexity.
- More Xcode/build plumbing.
- Easy to overbuild before profile behavior is proven.

Recommendation: reserve Metal for stage 2+ refinements behind the same `PipelineStage` protocol. Do not make the first version a Metal-first app.

### AppKit Import/Export Integration

SwiftUI can use `.fileImporter`/`.fileExporter`, but AppKit `NSOpenPanel` and `NSSavePanel` are still practical for a Mac-first image tool. Drag-and-drop should be handled in SwiftUI/AppKit bridging.

Recommendation:

- Import via drag-and-drop plus open panel.
- Export via save panel.
- Keep file handling in `ImageImportService` and `ExportService`, not views.

### Image I/O

Image I/O should handle file decoding/encoding where possible, especially because the app needs JPG, PNG, and preferably HEIC import. It also gives access to metadata and color profiles.

Recommendation:

- Use Image I/O to load image sources and metadata.
- Preserve reasonable orientation/color handling.
- Export processed image as JPG/PNG through `CGImageDestination`.
- Do not overwrite originals.

### Core Image Custom CIFilter Pipelines

The engine can be implemented as a chain of small stages returning `CIImage`. This avoids one giant custom `CIFilter`. Later, frequently reused groups could become custom `CIFilter` subclasses or Metal kernels.

Recommendation:

- Use a plain Swift pipeline first:

```swift
protocol PipelineStage {
    func render(_ image: CIImage, context: RenderContext) throws -> CIImage
}
```

- Build stages from recipe data.
- Keep `CIContext` shared and long-lived.
- Render low-resolution previews and full-resolution exports through the same pipeline.

### LUT-Based Workflows

LUTs are useful for profile identity, but external LUT file management is not required for v1. Apple’s `CIColorCube` provides a native path when LUT support is needed.

Recommendation:

- Include a `ColorTransformRecipe` capable of `.matrix`, `.curves`, and later `.cube`.
- For v1, implement matrix/curves plus optional generated cube for selective looks.
- Add `.cube` import only after the app has stable profiles and tests.

### Procedural Grain

Procedural grain fits the local/no-assets requirement. The preview can generate lower-resolution grain; export can generate full-size grain with the same seed/profile settings.

Recommendation:

- Use seeded procedural noise where possible for deterministic previews/exports.
- Separate film grain from digital noise recipes.
- Apply grain late in the pipeline, after bloom/halation/vignette and before final border/text.

### GPUImage3

GPUImage3 is a credible Swift/Metal image-processing framework, but it is not the right MVP dependency. It is oriented around GPU pipelines for image/video, while FilmForge can get far with Apple-native Core Image for still-image editing. Adding GPUImage3 now would increase dependency and integration surface before there is evidence Core Image is insufficient.

Recommendation: do not use GPUImage3 for MVP. Revisit only if Core Image preview performance or custom effects become a bottleneck.

## Recommended MVP Architecture

Use native macOS SwiftUI with a Core Image-first processing engine.

High-level modules:

- `FilmForgeApp`: app entry point and window commands.
- `ImageDocumentState` or `EditorViewModel`: selected image, selected profile, user adjustments, render status.
- `ImageImportService`: open panel, drag/drop URL handling, orientation/color-safe import.
- `ImagePipeline`: builds and runs stages from `FilmProfile + UserAdjustments`.
- `PipelineStage` implementations: one effect per stage.
- `ProfileCatalog`: data-defined initial 12 profiles.
- `PreviewRenderer`: creates fast preview-size `CGImage`/`NSImage`, caches by image/profile/adjustment key.
- `ExportService`: full-resolution render and JPG/PNG writing through save panel/Image I/O.
- `ProfileCard`/`InspectorPanel`/`PreviewCanvas`: SwiftUI presentation only.

Pipeline order for MVP:

1. Normalize orientation and color space.
2. Optional crop/aspect stage.
3. Exposure/temperature/tint user corrections.
4. Base color transform.
5. Tone curve and contrast shaping.
6. Saturation/selective color approximation.
7. Bloom.
8. Halation.
9. Lens softness / edge blur.
10. Chromatic aberration.
11. Vignette.
12. Grain / digital noise.
13. Dust / scratches / light leak.
14. Border / frame.
15. Export color conversion and encoding.

Preview/export strategy:

- Preview renders at bounded long edge, for example 1600 px or view-dependent.
- Export renders at original resolution.
- Cache preview output by source image identity, profile id, and normalized adjustment values.
- Re-render asynchronously when sliders change, with debouncing.
- Keep source image immutable.

## MVP Effect Implementation Notes

| Effect | MVP implementation | Later upgrade |
| --- | --- | --- |
| Tone curve | `CIToneCurve` profile points | generated LUT or custom per-channel curves |
| LUT | architecture slot, optional generated `CIColorCube` | `.cube` import/export and preview tools |
| Grain | Core Image noise, scale/blur, luminance-masked blend | custom seeded grain kernel |
| Halation | highlight mask, blur, warm tint, blend | edge-aware Metal/Core Image kernel |
| Bloom | `CIBloom` or masked blur blend | multi-radius bloom |
| Vignette | `CIVignette`/`CIVignetteEffect` | custom center/shape controls |
| Lens softness | blur duplicate blended globally or with radial mask | optical PSF/edge-aware blur |
| Chromatic aberration | subtle RGB/channel offset near edges | radial per-channel Metal kernel |
| Dust/scratches | procedural noise/line overlays | seeded artifact library with profiles |
| Borders | generated canvas/frame stage | paper texture and print-edge variation |
| CCD look | curve clipping, chroma noise, sharpening/downsample | compression artifacts and sensor pattern |

## Implementation Plan

### Stage 1: App Shell And Photo Import

- Create the Xcode macOS SwiftUI project.
- Build three-panel dark editor shell: profile/sidebar, center preview, right inspector.
- Add drag-and-drop and open-panel import for JPG/PNG/HEIC where supported.
- Decode image into immutable source state.
- Show original image preview.

### Stage 2: Preview Pipeline

- Add `FilmProfile`, `FilmRecipe`, `UserAdjustments`, `ImagePipeline`, and `PipelineStage`.
- Add shared `CIContext`.
- Add preview renderer with max-size rendering.
- Add before/after toggle.
- Add profile selection wired to pipeline.

### Stage 3: Initial Film Profiles

- Implement the 12 original profiles as data recipes.
- Ensure profiles differ meaningfully in tone, color, texture, and optical behavior.
- Keep profile names original and non-trademarked.

### Stage 4: Adjustable Controls

- Add inspector sliders/toggles:
  - intensity
  - exposure
  - temperature
  - tint
  - grain
  - bloom
  - halation
  - vignette
  - fade
  - sharpness/softness
  - dust amount
  - border on/off
- Controls scale recipe parameters rather than replacing them.
- Debounce preview rendering.

### Stage 5: Export

- Add `ExportService`.
- Render full-resolution image through the same pipeline.
- Export JPG and PNG through save panel.
- Preserve reasonable color/orientation output.
- Never overwrite original file automatically.

### Stage 6: Polish And Performance

- Add preview cache.
- Add split comparison slider if practical.
- Improve profile cards.
- Add progress/error states.
- Profile large-image performance.
- Add architecture/profile docs and README.

## Build Recommendation

The best MVP architecture is a native macOS SwiftUI app using Core Image first. Core Image should power the reusable film engine through composable stages. Metal should be introduced only for effects that prove hard or poor-quality in Core Image: selective HSL, high-quality grain, edge-aware halation, chromatic aberration, and toy-lens distortion.

The central decision is to make `FilmRecipe` the source of truth. SwiftUI should never contain profile-specific filter logic. The app should feel like a stylish Mac photo tool, but the engineering heart should be a reusable image-processing engine that can grow from simple built-in filters to custom kernels without changing the user-facing model.

## Open Decisions Before Implementation

- Minimum macOS deployment target.
- Whether the Xcode project should be created manually or with a generator such as XcodeGen.
- Whether previews should render into `NSImage` first or use a Metal-backed view for smoother zoom/pan.
- Whether v1 should include generated borders only or also procedural paper texture.
- How much HEIC export matters; brief only requires JPG/PNG export.

