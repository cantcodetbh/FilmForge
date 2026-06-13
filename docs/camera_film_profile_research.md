# Camera And Film Profile Research

Research date: 2026-06-13

This note records the profile research that drove the second FilmForge profile pass. The product model changed from one flattened preset list into two layers:

- Camera profile: format, optics, sensor/flash behavior, vignette, sharpness, softness, frame/border, digital downsample, aberration.
- Film stock response: tone scale, color palette, saturation behavior, grain, halation, bloom, monochrome/slide/negative/instant chemistry.

The goal is not to clone any app preset. The goal is to build a tunable camera-plus-film engine where the same camera can feel meaningfully different depending on the selected stock.

## Source Notes

- Kodak Portra 400 technical data describes high-speed color negative film with fine grain, strong skin-tone reproduction, and wide lighting usefulness. <https://business.kodakmoments.com/sites/default/files/files/products/e4050_portra_400.pdf>
- Kodak Ektar 100 technical data describes ISO 100 color negative film with ultra-vivid color, very fine grain, and high saturation. <https://business.kodakmoments.com/sites/default/files/files/products/e4046_ektar_100.pdf>
- Kodak Ektachrome E100 technical data describes E-6 transparency film with extremely fine grain, low D-min, moderately enhanced saturation, neutral balance, and low-contrast tone scale. <https://business.kodakmoments.com/sites/default/files/files/products/e4000_ektachrome_100.pdf>
- Kodak Tri-X information describes a high-speed black-and-white film with classic grain, sharpness, wide exposure latitude, and push-processing use. <https://www.kodakprofessional.com/photographers/film/black-white/kodak-professional-tri-x-films/515>
- Fujifilm Velvia 50 documentation emphasizes very high color saturation, fine grain, resolving power, and vibrant reproduction. <https://www.fujifilm.com/us/en/business/professional-photography/film/velvia-50>
- Fujifilm Provia 100F data describes fine grain, high sharpness, faithful vivid color, and rich gradation. <https://asset.fujifilm.com/master/emea/files/2020-10/2c27854d5609945fbe7e48afc61f815d/films_provia-100f_datasheet_01.pdf>
- Ilford HP5 Plus is described as high-speed, fine-grain, medium-contrast black-and-white film with push-processing flexibility. <https://www.ilfordphoto.com/hp5-plus-sheet-film>
- Ilford Delta 3200 is described as very high-speed black-and-white film for low light with wide tonal range. <https://www.ilfordphoto.com/delta-3200-professional-35mm>
- Polaroid SX-70 film is lower speed and should be shot in strong natural light; modern i-Type color is described as dreamy, nostalgic, and finished in white frames. <https://www.polaroid.com/en_us/products/color-sx70-instant-film> and <https://www.polaroid.com/en_us/products/color-itype-instant-film>
- 135 film commonly uses a 24 x 36 mm frame, while 120 medium format supports larger frame families such as 6x6 and 6x7. <https://obsoletemedia.org/135-film/> and <https://www.photoethnography.com/ClassicCameras/filmformats.html>
- Half-frame 35mm cameras such as the Olympus Pen F use an 18 x 24 mm frame, making grain more visible than full 35mm for the same stock. <https://mrleica.com/olympus-pen-f/>
- Toy cameras such as Holga/Diana are known for plastic-lens softness, vignetting, light leaks, low-fi blur, and unpredictable color. Lomography’s own material notes stronger saturation/vignette when slide film is cross-processed. <https://www.lomography.com/magazine/338582-a-simple-tip-to-enhance-your-diana-f-vignettes-in-your-photos>
- Canon’s PowerShot G2 museum page identifies it as a 4MP CCD camera with an RGB primary color filter and Canon imaging engine; early CCD references commonly point to lower dynamic range, stronger sharpening, chroma noise, and clipped highlights. <https://global.canon/en/c-museum/product/dcc474.html>
- Sony DSC-F707 reviews identify vivid color, 5MP CCD output, and fringing issues around high-contrast details. <https://www.dpreview.com/reviews/sonydscf707/18>

## Implementation Translation

### Camera Layer

Camera profiles now live in `CameraProfile` and control:

- `CaptureFormat`: 135, 120, half-frame, instant, toy, disposable, CCD.
- Lens softness, sharpening, and downsample.
- Vignette strength and border style.
- Bloom/halation from optics and flash.
- Chromatic aberration and old-digital edge behavior.

Current camera profiles:

- Canon AE-1
- Contax T2
- Hasselblad 500
- Mamiya RB67
- Olympus Pen F
- Holga 120N
- Diana F+
- Polaroid SX-70
- Disposable Flash
- Canon PowerShot G2
- Sony DSC-F707
- Mini DV Still

### Film Layer

Film stocks now live in `FilmStock` and control:

- color negative, slide, black-and-white, instant, or digital-sensor response
- tone curve and highlight shoulder
- saturation behavior
- split-tone and CMY-style bias
- grain amount/scale/monochrome behavior
- halation and bloom contribution

Current film responses:

- Portra 400
- Ektar 100
- Consumer 400
- Ektachrome E100
- Velvia 50
- Provia 100F
- Tri-X 400
- HP5 Plus
- Delta 3200
- Color Instant
- CCD Sensor, for CCD cameras only

### Pipeline Change

The Core Image pipeline gained `SplitToneStage`, which applies:

- CMY-style bias for subtractive print/film color behavior
- shadow tint
- highlight tint

This is not a substitute for a future proper LUT or Metal selective-HSL stage, but it gives the current Core Image engine more color separation than simple RGB gain.

## Next Fidelity Step

The next profile-quality jump should be a generated 3D color cube stage per camera/film pair. That would let FilmForge model hue-selective behavior more realistically:

- Portra-style warm skin retention without overcooking reds
- Ektar-style strong reds/blues with protected neutrals
- Velvia-style landscape greens/blues and narrow latitude
- CCD red channel clipping and cyan shadow drift
- instant-film yellow/warm highlight chemistry with lifted shadows

