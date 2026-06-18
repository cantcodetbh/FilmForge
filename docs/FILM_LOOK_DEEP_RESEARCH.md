# Film Look Deep Research

This is a practical research memo for pushing FilmForge closer to the best disposable/film-camera apps without copying proprietary app presets, stock recipes, UI, names, assets, or measured commercial profile data.

## Short Version

FilmForge already has the right broad ingredients: tone curve, LUT, halation, bloom, grain, lens softness, vignette, dust, light leaks, and date stamp. The missing quality is mostly in five areas:

1. Make transforms scene-aware instead of profile-static.
2. Model capture constraints before styling: flash, under/overexposure, phone sharpening, local tone mapping, and white balance.
3. Split "negative/emulsion" and "print/display" stages instead of folding too much into one cube.
4. Make grain a density/resolution process, not just an overlay-like additive texture.
5. Treat app feel as part of the image result: simple camera models, committed constraints, delayed/roll-like capture, and controlled randomness.

## What The Strong Apps Appear To Be Doing

### HUJI

HUJI is strong because it commits to one narrow fantasy: "Just Like The Year 1998". The App Store copy and reviews repeatedly highlight vivid/vibrant photos, a tiny viewfinder, light effects, import processing, photo quality settings, date formats, and a vintage orange date stamp. Version notes also mention "More Light Effects" several times, which implies they kept iterating on the most memorable artifact rather than broadening endlessly.

What matters for FilmForge:

- HUJI is not trying to be a full film lab.
- It uses a very limited disposable-camera mental model.
- It accepts stylization that can crush subtle source color, as one review notes with northern lights.
- The feeling comes from strong defaults, random light effects, date stamp, and a constrained shooting experience as much as from color science.

Source: https://apps.apple.com/us/app/huji-cam/id781383622

### Dazz Cam

Dazz explicitly says it is inspired by classic 1980s cameras and has "sampled real film stock" to recreate colors and textures. Its current App Store listing mentions many format/camera categories: 135 film, 120 film, toy cameras, slide film, half-frame, instant, 3D, disposable, CCD/compact digital, and more. Recent release notes mention optimized camera exposure, profile editing, saving edited profiles, a new color profile with smoother tones/colors, and a new rendering pipeline for one camera.

What matters for FilmForge:

- Dazz is selling camera simulations, not just filters.
- The library is segmented by capture device/format, which lets each look have coherent optical, frame, exposure, and texture rules.
- "Sampled real film stock" is the key differentiator. Even if we do not ship measured stock data, we should build a measurement workflow so original profiles can be authored from our own targets.
- Their recent updates point to exposure handling and per-camera rendering pipelines as live areas of quality work.

Source: https://apps.apple.com/us/app/dazz-cam-vintage-camera/id1422471180

### OldRoll, FIMO, NOMO, Film(ish), Dehancer

The wider market says the same thing in different language:

- OldRoll emphasizes real camera experience plus color, hue, grain, texture, light leaks, and camera-specific models.
- FIMO emphasizes dust, scratches, retro color, flickering, light leaks, and frame shake.
- NOMO emphasizes shooting rather than retouching, camera selection, double exposure, and point-and-shoot constraints.
- Film(ish) advertises response curves, halation, diffusion, and realistic grain.
- Dehancer exposes film profiles, grain, bloom, halation, expand/black-white point control, and measured sampling.

Sources:

- https://apps.apple.com/us/app/oldroll-vintage-film-camera/id1570093460
- https://apps.apple.com/us/app/fimo-analog-camera/id1454219307
- https://apps.apple.com/us/app/nomo-cam-point-and-shoot/id1362548649
- https://apps.apple.com/us/app/film-ish/id6761363553
- https://apps.apple.com/pl/app/dehancer-film-emulation/id6443648413

## Technical Findings

### 1. LUTs Are Necessary But Not Sufficient

RawTherapee's HaldCLUT documentation is blunt: HaldCLUTs can encode global color/tone changes, but not denoising, sharpening, tone mapping, distortion, local contrast, grain, or other spatial operations. That matches why a static LUT can feel like an Instagram filter even when its colors are nice.

FilmForge implication:

- Keep LUT import, but label/think of LUTs as "color response" or "print color", not a complete film look.
- Add a second color stage: `captureTransform -> negative/emulsion response -> print/display transform`.
- Preserve enough pre-LUT dynamic range that bloom/halation and shoulder roll-off have useful signal.

Source: https://rawpedia.rawtherapee.com/Film_Simulation

### 2. Film Tone Is A Curve System, Not A Contrast Slider

Kodak sensitometry sources describe a characteristic curve with toe, straight-line portion, and shoulder. This is not just aesthetic S-curve language: shadows, midtones, and highlights live in different regions of the negative response.

FilmForge implication:

- The existing `ToneCurveFilter` has toe/shoulder controls, which is good.
- It should become exposure-dependent and possibly per-channel, because overexposed color response is a big part of why film does not feel like digital clipping.
- Add profile-specific D-min/D-max style controls: paper black floor, print white softness, shoulder hue drift, and highlight desaturation.

Sources:

- https://www.kodak.com/content/products-brochures/Film/Basic-Photographic-Sensitometry-Workbook.pdf
- https://www.kodak.com/uploadedfiles/motion/US_plugins_acrobat_en_motion_newsletters_filmEss_06_Characteristics_of_Film.pdf

### 3. Modern Phone Images Need De-Phone-ification

The mobile computational photography survey is useful because it explains why phone photos fight the film look. Modern phones use multi-frame merging, denoising, tone mapping, sharpening, local tone mapping, and sensor-specific color correction before we ever see the JPEG/HEIC. Local tone mapping and sharpening are especially important because they make everything clean, bright, and edge-enhanced.

FilmForge implication:

- Add a "digital removal" pre-stage for imported phone images:
  - tame microcontrast/clarity;
  - reduce edge halos;
  - reintroduce directional/optical blur selectively;
  - compress over-bright local HDR areas back into a simpler exposure model;
  - optionally add a mild negative clarity pass before grain.
- For a camera version, support RAW/ProRAW capture where possible so the app starts before the default phone look hardens.

Sources:

- https://ar5iv.labs.arxiv.org/html/2102.09000
- https://developer.apple.com/documentation/avfoundation/capturing-photos-in-raw-and-apple-proraw-formats

### 4. Grain Needs To Participate In The Image

Steve Yedlin argues against treating scanned grain as a magical fixed texture; film never repeats a single correct pattern, and scanned gray fields do not automatically imply a good algorithm. Newson et al. model film grain as stochastic geometry and emphasize physically meaningful parameters, arbitrary resolution rendering, and no separate blend step: the image results from the grain model. Dehancer's public docs similarly treat grain as linked to tonal zones, chroma, optical density, and film resolution.

FilmForge implication:

- The current procedural multi-scale grain is directionally right.
- Next improvement should move from additive noise toward density modulation:
  - generate grain in a density/log-light domain;
  - vary grain size/distribution by luminance and color channel;
  - include grain clumping and non-uniform grain radius;
  - soften source detail in relation to grain size;
  - avoid visible grain in pure clipped black/white, but allow it in deep textured shadows and bright textured highlights.
- Add a stable seed per exported image, not `Date()` during preview, so previews stop shimmering unpredictably unless intentionally animated.

Sources:

- https://www.yedlin.net/NerdyFilmTechStuff/OnFilmGrainEmulation
- https://www.lirmm.fr/~nfaraj/publications/film_grain_ipol/2017_Newson_film_grain.pdf
- https://www.dehancer.com/learn/article/grain

### 5. Halation And Bloom Should Be Different, But Coupled

Dehancer's public halation notes separate local diffusion, global diffusion, hue, background gain, source limiting, blue compensation, amplify, and impact. It also notes halation and bloom usually coexist and influence one another. Resolve's Film Look Creator discussion similarly treats halation radius/hue and bloom as separate controls.

FilmForge implication:

- Current halation has a highlight/local-average mask, which is a good base.
- Add separate local and global diffusion paths:
  - local red/orange edge halos around high-contrast sources;
  - broader low-opacity glare for portraits/lights;
  - cool-background damping and optional blue compensation;
  - source limiter so white skies do not wash the whole image red.
- Couple bloom and halation by sharing a highlight source mask, but render them with different colors/radii/blend modes.

Sources:

- https://www.dehancer.com/learn/article/halation
- https://blog.frame.io/2024/08/15/what-is-resolves-new-film-look-creator-plugin/

### 6. Highlight Roll-Off Must Desaturate Toward White

Unreal's ACES/filmic tonemapper docs explain a behavior that matters visually: very bright saturated colors should become lighter and approach white rather than becoming neon blocks. That is one of the classic giveaways of digital filter looks.

FilmForge implication:

- Current `compressHighlights` does a small move toward white, but it happens inside the fallback LUT.
- Make highlight whitening/roll-off a first-class tone response stage, before bloom/halation and before final print transform.
- Tune it per profile: disposable flash should clip/flatten harder than negative portrait; slide-style looks should keep saturation but still avoid neon clipping.

Source: https://dev.epicgames.com/documentation/en-us/unreal-engine/color-grading-and-the-filmic-tonemapper-in-unreal-engine

### 7. Adaptive LUTs Are A Practical Middle Ground Before Full ML

The image-adaptive 3D LUT paper learns multiple basis LUTs and predicts content-dependent weights from a downsampled image, then applies the fused LUT efficiently at high resolution. This is relevant because Dazz/HUJI-like apps often feel like they handle faces, night shots, flash shots, and skies differently without exposing controls.

FilmForge implication:

- We can implement a non-ML version first:
  - compute scene descriptors: average luminance, highlight ratio, skin likelihood, sky/cyan ratio, tungsten warmth, face/portrait flag if available;
  - blend 2-4 internal basis cubes per profile;
  - choose profile variants for under/normal/over exposure.
- Later, train a tiny adaptive LUT model from our own paired reference edits.

Source: https://arxiv.org/abs/2009.14468

### 8. Measured Profiles Beat Hand-Tuned Presets

Dehancer describes building profiles from underexposed, normal, and overexposed samples, and emphasizes negative film as data that requires positive print interpretation. Dazz also claims sampled real film stock. This does not mean FilmForge should copy commercial film data; it means the authoring workflow matters.

FilmForge implication:

- Create our own measurement workflow:
  - shoot color charts/gray scales/skin references on actual disposable, compact, instant, and 35mm cameras;
  - scan consistently;
  - capture matched digital/phone references;
  - estimate input-to-target transforms;
  - fit original analytic parameters and/or internal LUTs;
  - store under/normal/over variants.
- Profiles should be versioned artifacts, not just hand-tuned Swift literals.

Source: https://www.dehancer.com/learn/articles/how-we-build-film-profiles

## Where FilmForge Is Currently Strong

- The pipeline is modular and already separates tone, LUT, halation, bloom, lens, artifacts, and grain.
- It uses an extended linear working color space, which is the right direction for non-destructive intermediate processing.
- Grain is procedural and tonal-zone aware rather than a static overlay.
- Halation already uses a local-average comparison instead of a global red wash.
- LUT import exists for `.cube` and HaldCLUT-style assets.

## Where FilmForge Still Feels Too Digital

1. The LUT stage is globally blended by a profile scalar and built-in scale. It cannot react to scene class.
2. The fallback cubes are analytic and low-dimensional. They lack measured cross-channel weirdness, hue twists at exposure extremes, and print-stage separation.
3. Tone is mostly one global curve. It does not yet undo phone local tone mapping or digital edge enhancement.
4. Grain is additive in RGB; it should be closer to density-domain modulation with clumping/radius variation.
5. Halation and bloom are independent masks. Realistic looks need a shared source model but distinct diffusion paths.
6. Light leaks/dust/scratches are too deterministic and uniform. HUJI-style magic depends on controlled randomness, but not random-looking randomness.
7. The app is an editor. HUJI/Dazz/NOMO succeed partly by making capture itself feel constrained and committed.

## Recommended Build Plan

### Phase 1: Make Existing Pipeline Feel More Organic

- Add stable per-image random seed stored in editor state/export settings.
- Add `DigitalTamingFilter` before tone:
  - mild negative clarity;
  - edge halo damping;
  - optional local HDR flattening.
- Split bloom/halation masks into shared `HighlightSourceMask` with local and global variants.
- Move highlight desaturation/whitening out of fallback LUT and into tone response.
- Add profile-level randomness ranges for light leak side, intensity, dust, date stamp jitter, and flash center.

### Phase 2: Add Scene-Adaptive Profiles

- Compute scene descriptors from a downsampled CIImage:
  - mean luma;
  - highlight percentage;
  - shadow percentage;
  - color temperature proxy;
  - saturated color ratio;
  - face/skin heuristic if we avoid Vision dependency initially.
- Extend `FilmLookProfile` with under/normal/over variants.
- Blend tone, LUT intensity, halation threshold, bloom threshold, and grain amount based on descriptors.
- Add disposable flash logic that changes falloff, warmth, and contrast based on subject brightness.

### Phase 3: Build Original Measured Profile Authoring

- Add a local CLI/profile-tool target that ingests pairs of reference images and identity CLUTs.
- Generate original internal cubes from measured references.
- Store profile recipes as JSON/YAML rather than only Swift literals.
- Create contact-sheet regression renders for each profile against a standard image set.

### Phase 4: Camera Experience

- Add capture mode with camera models instead of only editor presets.
- Support RAW/ProRAW capture where available.
- Add camera constraints per model:
  - fixed focal length feel;
  - flash behavior;
  - delayed development;
  - roll count;
  - half-frame/square/instant frame options;
  - limited controls.
- Keep the editor, but make the first experience a camera, not a grading panel.

## Source Index

- HUJI Cam App Store: https://apps.apple.com/us/app/huji-cam/id781383622
- Dazz Cam App Store: https://apps.apple.com/us/app/dazz-cam-vintage-camera/id1422471180
- OldRoll App Store: https://apps.apple.com/us/app/oldroll-vintage-film-camera/id1570093460
- FIMO App Store: https://apps.apple.com/us/app/fimo-analog-camera/id1454219307
- NOMO CAM App Store: https://apps.apple.com/us/app/nomo-cam-point-and-shoot/id1362548649
- Film(ish) App Store: https://apps.apple.com/us/app/film-ish/id6761363553
- Dehancer iOS App Store: https://apps.apple.com/pl/app/dehancer-film-emulation/id6443648413
- RawTherapee Film Simulation: https://rawpedia.rawtherapee.com/Film_Simulation
- darktable filmic rgb: https://docs.darktable.org/usermanual/development/en/module-reference/processing-modules/filmic-rgb/
- Unreal Engine Filmic Tonemapper: https://dev.epicgames.com/documentation/en-us/unreal-engine/color-grading-and-the-filmic-tonemapper-in-unreal-engine
- Kodak Basic Photographic Sensitometry Workbook: https://www.kodak.com/content/products-brochures/Film/Basic-Photographic-Sensitometry-Workbook.pdf
- Kodak Characteristics of Film: https://www.kodak.com/uploadedfiles/motion/US_plugins_acrobat_en_motion_newsletters_filmEss_06_Characteristics_of_Film.pdf
- Steve Yedlin, On Grain Emulation: https://www.yedlin.net/NerdyFilmTechStuff/OnFilmGrainEmulation
- Newson et al., Realistic Film Grain Rendering: https://www.lirmm.fr/~nfaraj/publications/film_grain_ipol/2017_Newson_film_grain.pdf
- Dehancer Halation: https://www.dehancer.com/learn/article/halation
- Dehancer Grain: https://www.dehancer.com/learn/article/grain
- Dehancer profile sampling: https://www.dehancer.com/learn/articles/how-we-build-film-profiles
- Frame.io on Resolve Film Look Creator: https://blog.frame.io/2024/08/15/what-is-resolves-new-film-look-creator-plugin/
- Image-adaptive 3D LUTs: https://arxiv.org/abs/2009.14468
- Mobile Computational Photography: https://ar5iv.labs.arxiv.org/html/2102.09000
- Apple RAW/ProRAW capture: https://developer.apple.com/documentation/avfoundation/capturing-photos-in-raw-and-apple-proraw-formats
