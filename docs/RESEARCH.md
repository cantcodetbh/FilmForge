# FilmForge Research Notes

This file summarizes the requested research and maps it to the implementation in this repository. The current app is an original film-look photo processor; it uses the sources for technical direction, not for copied presets, proprietary profile recipes, UI, names, code, or assets.

## Platform And Rendering

1. Apple Core Image overview  
   Source: https://developer.apple.com/documentation/coreimage  
   Summary: Core Image represents image processing as lazy filter graphs over `CIImage`, with `CIContext` performing GPU/CPU rendering into requested formats and color spaces.  
   Implementation mapping: `FilmPipeline` composes independent Core Image stages, and `RenderContext` centralizes the working/output color spaces.  
   Not copied: Apple sample code or canned photo-effect filters.

2. Apple `CIColorCube`  
   Source: https://developer.apple.com/documentation/coreimage/cicolorcube  
   Summary: 3D LUTs can be represented as RGBA float cube data and applied with `CIColorCube` or `CIColorCubeWithColorSpace`.  
   Implementation mapping: `LUTLoader` applies parsed or generated cubes with `CIColorCubeWithColorSpace`, then blends the result by intensity.  
   Not copied: Any vendor LUT data.

3. Core Image Filter Reference  
   Source: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/  
   Summary: Core Image has useful primitives for blur, bloom/gloom, color controls, temperature/tint, vibrance, vignette, random generation, compositing, and image export.  
   Implementation mapping: Custom kernels are combined with built-in blur, color, vignette, random, and compositing filters instead of writing a single opaque effect.  
   Not copied: Built-in `CIPhotoEffect*` looks are deliberately avoided.

4. Metal Performance Shaders  
   Source: https://developer.apple.com/documentation/metalperformanceshaders  
   Summary: MPS provides optimized GPU kernels for image and compute operations.  
   Implementation mapping: The first version uses Core Image because it is sufficient for still-image filter graphs; MPS remains a future path for faster custom convolution, grain, and larger exports.  
   Not copied: No private or platform-specific shader tricks.

5. Apple Metal overview  
   Source: https://developer.apple.com/metal/  
   Summary: Metal gives direct access to Apple GPU graphics and compute with profiling/debugging tools.  
   Implementation mapping: The architecture keeps effect stages separate so they can later move from Core Image kernels to Metal kernels without redesigning the app.  
   Not copied: No Metal sample UI or demo content.

## LUTs, CLUTs, And Film Simulation

6. RawTherapee Film Simulation and HaldCLUT explanation  
   Source: https://rawpedia.rawtherapee.com/Film_Simulation  
   Summary: HaldCLUT images encode global color transforms; they cannot represent local effects like sharpening, denoising, grain, blur, halation, or distortion. Pixel values matter more than assigned profiles for CLUT data.  
   Implementation mapping: `HaldCLUTLoader` converts Hald images into CI cube data, and the app keeps LUTs separate from grain/halation/bloom/lens stages.  
   Not copied: RawTherapee's film collection and preset names.

7. G'MIC color presets / film simulation CLUTs  
   Source: https://gmic.eu/color_presets/  
   Summary: Large collections of film-style CLUTs demonstrate the usefulness and limitation of global color mappings.  
   Implementation mapping: The app supports external `.cube`/Hald transforms but ships only original analytic fallback cubes.  
   Not copied: G'MIC preset data, labels, or exact looks.

8. Pat David on G'MIC film emulation presets and Hald CLUTs  
   Source: https://patdavid.net/2013/08/film-emulation-presets-in-gmic-gimp/  
   Summary: Hald workflows are practical for distributing global color grades and can be authored by applying global edits to an identity image.  
   Implementation mapping: The parser/export architecture treats LUTs as reusable global transforms, with a `lutOnly` export mode for color transform workflows.  
   Not copied: Downloaded preset packs or preset recipes.

## Tone Response And Color Management

9. darktable filmic rgb  
   Source: https://docs.darktable.org/usermanual/development/en/module-reference/processing-modules/filmic-rgb/  
   Summary: Filmic tone mapping maps scene dynamic range to display range, protects midtone contrast, and compresses shadows/highlights with a parametric curve.  
   Implementation mapping: `ToneCurveFilter` is a separate parametric stage with exposure, toe, shoulder, midtone contrast, black point, white point, and roll-off behavior.  
   Not copied: darktable's spline implementation or UI.

10. Unreal Engine filmic tonemapper / ACES  
    Source: https://dev.epicgames.com/documentation/unreal-engine/color-grading-and-the-filmic-tonemapper-in-unreal-engine  
    Summary: Filmic rendering benefits from highlight desaturation/roll-off and a consistent output transform rather than simple clipping.  
    Implementation mapping: The pipeline normalizes exposure, rolls highlights before LUT/spatial effects, and exports through an explicit output color space.  
    Not copied: Unreal's exact tonemapper constants.

11. OpenColorIO overview  
    Source: https://opencolorio.org/  
    Summary: OCIO formalizes color transforms, display/view transforms, and predictable color pipelines across applications.  
    Implementation mapping: The app documents its working and output color spaces explicitly and keeps color transforms as named stages.  
    Not copied: OCIO configs or transforms.

12. OpenColorIO documentation  
    Source: https://opencolorio.readthedocs.io/en/latest/  
    Summary: Production color pipelines separate scene spaces, looks, displays, and file outputs.  
    Implementation mapping: `ExportSettings` and `RenderContext` make output color choices explicit, with room for future OCIO integration.  
    Not copied: ACES/OCIO config data.

13. Kodak Basic Photographic Sensitometry Workbook  
    Source: https://www.kodak.com/content/products-brochures/Film/Basic-Photographic-Sensitometry-Workbook.pdf  
    Summary: Sensitometry uses log exposure versus density curves; film response has toe, straight-line, and shoulder regions, plus D-min/D-max and contrast index.  
    Implementation mapping: The tone model exposes toe, shoulder, black point, white point, and contrast as first-class profile parameters.  
    Not copied: Kodak curves, stock names, or measured film data.

14. Kodak Characteristics of Film / sensitometry  
    Source: https://www.kodak.com/uploadedfiles/motion/US_plugins_acrobat_en_motion_newsletters_filmEss_06_Characteristics_of_Film.pdf  
    Summary: Film look comes from exposure latitude, characteristic curves, grain, color dye behavior, and print interpretation.  
    Implementation mapping: Profiles combine tone response, color transform, print-like LUT, and late spatial effects rather than a single contrast/saturation adjustment.  
    Not copied: Kodak trademarks in user-facing preset names or recipes.

## Grain, Halation, And Film Profile References

15. Steve Yedlin, On Film Grain Emulation  
    Source: https://www.yedlin.net/NerdyFilmTechStuff/OnFilmGrainEmulation  
    Summary: Good grain is a model of probabilistic behavior, not merely a scanned overlay or flat random texture; repetition and poor luminance interaction are failure modes.  
    Implementation mapping: `GrainFilter` generates procedural multi-scale grain at render resolution and modulates it by luminance and chroma.  
    Not copied: Yedlin's algorithms or private data.

16. Dehancer Halation  
    Source: https://www.dehancer.com/learn/article/halation  
    Summary: Halation is a local red/orange halo around bright sources, highlights, and contrast edges; controls include source limiting, diffusion, hue, and impact.  
    Implementation mapping: `HalationFilter` builds a soft highlight/edge-biased mask, blurs it, tints it warm, and blends it locally.  
    Not copied: Dehancer's profiles, UI, parameter names as a product system, or exact behavior.

17. Dehancer Film Grain  
    Source: https://www.dehancer.com/learn/article/grain  
    Summary: Film grain relates to image brightness/color and film format/ISO; simple noise can be useful for drafts but is not rich film emulation.  
    Implementation mapping: Grain presets model fine 50, medium 250, heavy 500, and disposable compact with size, roughness, strength, chroma, and highlight bias.  
    Not copied: Dehancer grain profiles or emulsion model.

18. Dehancer Film Profiles  
    Source: https://www.dehancer.com/learn/article/film-profiles  
    Summary: Film profiles combine input interpretation, negative/print behavior, and additional analogue effects.  
    Implementation mapping: `FilmLookProfile` groups tone, LUT, grain, halation, bloom, vignette, lens, dust, and date stamp settings in one model while leaving execution modular.  
    Not copied: Profile names, commercial film identities, or measured data.

19. Dehancer, How We Build Film Profiles  
    Source: https://www.dehancer.com/learn/articles/how-we-build-film-profiles  
    Summary: Strong film profiles are built from controlled sampling and nonlinear interpretation; exposure variation can change color and contrast.  
    Implementation mapping: The current app uses original approximations only; future profile authoring should use controlled targets and measured transforms.  
    Not copied: Dehancer sampling technique details, datasets, or profile data.

20. Dehancer, Print Film Profiles  
    Source: https://www.dehancer.com/learn/articles/print-film-profiles-in-dehancer  
    Summary: Print media is a separate interpretive stage after negative capture and has its own contrast/color response.  
    Implementation mapping: The pipeline has room for a separate print/emulsion LUT stage; the current generated cubes approximate print-like color density separately from tone and spatial effects.  
    Not copied: Named print film profiles.

21. Alex Castronovo, From Code to Kodachrome  
    Source: https://articles.alexcastronovo.com/article/2/from-code-to-kodachrome-film-emulation-from-scratch  
    Summary: A from-scratch film emulator should reason about tone curves, color bias, grain, halation, and the order of operations.  
    Implementation mapping: The app implements a staged pipeline and avoids reducing the look to one slider stack.  
    Not copied: Article code, stock names, or recipes.

22. Frame.io on Resolve Film Look Creator  
    Source: https://blog.frame.io/2024/08/15/what-is-resolves-new-film-look-creator-plugin/  
    Summary: Modern film-look tools expose separable controls for film response, bloom/halation, grain, and print-like finishing instead of relying only on LUTs.  
    Implementation mapping: The UI exposes Tone, Colour, LUT, Grain, Halation, Bloom, Lens, Artefacts, and Export groups.  
    Not copied: Resolve UI, parameter taxonomy as a product, or commercial behavior.

## Advanced LUT / Learned Enhancement

23. Learning Image-adaptive 3D LUTs for Real-time Photo Enhancement  
    Source: https://arxiv.org/abs/2009.14468  
    Summary: Learned systems can combine multiple basis LUTs with content-dependent weights for fast high-resolution enhancement.  
    Implementation mapping: The current app supports static LUTs; future work could add image-adaptive blending while preserving spatial effects as separate stages.  
    Not copied: Model architecture, weights, data, or claims.

24. NILUT  
    Source: https://arxiv.org/abs/2306.11920  
    Summary: Neural implicit LUTs can represent continuous color transforms and blend styles memory-efficiently.  
    Implementation mapping: This is a future direction for compact custom looks; current implementation sticks to explicit cubes for inspectability.  
    Not copied: NILUT code, models, or datasets.

25. AdaInt  
    Source: https://arxiv.org/abs/2204.13983  
    Summary: Non-uniform LUT sampling can better model local nonlinearities than a uniform lattice.  
    Implementation mapping: The `.cube` parser supports standard uniform LUTs now; future parser/rendering work could support adaptive or higher-density transforms.  
    Not copied: AdaInt algorithm or learned intervals.

26. Real-time Image Enhancer via Learnable Spatial-aware 3D LUTs  
    Source: https://arxiv.org/abs/2108.08697  
    Summary: Spatial-aware learned LUTs can vary transforms by image content while keeping runtime practical.  
    Implementation mapping: This remains future work; this app intentionally does not fake spatial effects by baking them into LUTs.  
    Not copied: Network design, training data, or model weights.

## Implementation Principles

- Decode with orientation and use explicit Core Image contexts for working/output color spaces.
- Keep tone response separate from LUT application.
- Treat LUTs as global color/tone transforms only.
- Generate grain late, at preview/export resolution, with luminance and chroma dependence.
- Build halation from thresholded highlight/edge masks, not a global red overlay.
- Build bloom from thresholded highlights, not the whole image.
- Keep lens and artefact effects optional and profile-driven.
- Export JPEG/PNG from the fully rendered pipeline, with selectable output color space and JPEG quality.

## Deliberately Not Copied

- No commercial film stock trademarks are used for shipped preset names.
- No Dazz Cam, Dehancer, VSCO, Fuji, Kodak, Lightroom, Resolve, RawTherapee, or G'MIC UI/preset systems are copied.
- No proprietary profile measurements, LUTs, stock recipes, scanned grain assets, or sample images are included.
- No private Apple APIs are used.

## Open Questions And Future Improvements

- Replace Core Image Kernel Language strings with Metal Shading Language kernels for long-term API health.
- Add user-facing import for external `.cube` and HaldCLUT files in the UI.
- Add measured profile authoring from color charts and exposure brackets.
- Add a true separate print/emulsion transform stage instead of folded analytic fallback cubes.
- Preserve richer metadata on export, including selected EXIF/IPTC fields where safe.
- Add visual regression tests with generated reference images.
- Add batch export and sidecar profile serialization.

## Second-Pass Preset Research Notes

After the first usable build, the preset system was revised to make each look behave less like a simple slider stack and more like a compact film pipeline recipe.

RawTherapee's HaldCLUT notes are especially important because they draw a hard boundary around LUTs: HaldCLUTs can encode global tone/color changes, but not local contrast, denoising, sharpening, distortion, grain, or other spatial effects. This confirms the app's separation of fallback LUT cubes from halation, bloom, lens effects, dust, and procedural grain. It also informs future UI work: imported LUTs should be presented as color transforms, not as complete film emulations.

darktable's filmic rgb documentation emphasizes preparation around exposure/white balance and remapping scene dynamic range into display range while protecting midtones and compressing shadows/highlights. Presets were therefore adjusted around exposure assumptions instead of only warmth/saturation: `Slide Chrome` is underexposed with stronger positive-style density, `High-Key Portrait` is deliberately overexposed and shoulder-heavy, and `Night Tungsten` is lower-exposure with heavy shoulder compression.

Unreal's filmic tonemapper documentation reinforces two useful behaviours: highlight roll-off should preserve shape rather than clipping, and bright saturated colors should move toward white as they approach display saturation. The generated fallback cubes now include a small highlight compression/whitening step after profile-specific color shaping so very bright colors feel less digitally clipped.

Dehancer's profile notes describe exposure variation and source white balance as first-class parts of film behavior, especially the distinction between daylight and tungsten assumptions. The app still does not copy Dehancer data, but the presets now vary exposure, color-temperature bias, tint, and contrast together, rather than treating them as isolated creative sliders.

Dehancer's print-profile article reinforces print media as a separate interpretive stage after a negative. FilmForge still uses analytic fallback cubes rather than measured print media, but the cube recipes now lean into print-like density: raised paper blacks for `Matte Archive`, warm highlight paper stain for `Faded Print`, deep positive contrast for `Slide Chrome`, and neutral-warm monochrome paper response for `Silver Gelatin`.

Dehancer's halation notes describe source limiting, background gain, diffusion radius, hue, and impact. The halation mask now compares the source image against a small local blur before the larger diffusion blur, so bright local contrast edges and sources contribute more than flat bright regions. It also damps halation over already-bright backgrounds to avoid a global haze.

Dehancer's grain notes and Steve Yedlin's grain essay both argue against a flat overlay. The grain model was extended with shadow/midtone/highlight zone controls, clipped black/white guarding, chroma amount, grain size, roughness, and a resolution coupling blur. This remains procedural and approximate, not measured emulsion reconstruction, but it is closer to the practical lesson: grain participates in the image and varies with density.

New original looks added in this pass:

- `Slide Chrome`: positive-film-like contrast, saturated density, fine grain, minimal halation.
- `Silver Gelatin`: monochrome paper warmth, strong tonal separation, fine silver-style texture.
- `Night Tungsten`: blue-black night density, amber practical lights, strong edge/source halation.
- `High-Key Portrait`: bright negative-style portrait rendering with low chroma grain and soft bloom.
- `Matte Archive`: aged low-sheen print with lifted paper blacks, yellowed highlights, dust, and scratches.
- `Coastal Print`: cool open-shadow print with fine grain and restrained bloom.

The names and recipes are original approximations. They intentionally avoid commercial stock names, measured proprietary profile data, vendor LUTs, and commercial UI systems.
