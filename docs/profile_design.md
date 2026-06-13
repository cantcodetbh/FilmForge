# FilmForge Profile Design

FilmForge profiles are now composed from a camera profile plus a film stock response. Camera profiles describe the capture device; film stocks describe the emulsion/sensor response.

Each composed profile is made from layered settings:

- base color transform
- tone curve
- saturation behavior
- grain/noise model
- bloom
- halation
- vignette
- lens softness or digital sharpening
- chromatic aberration
- dust/scratch intensity
- optional border

User controls scale the recipe instead of replacing it. For example, the grain slider increases or decreases the recipe's own grain character; it does not apply one generic grain setting to every profile.

## Current Camera Profiles

| Camera | Intent |
| --- | --- |
| Canon AE-1 | Clean 135 SLR baseline. |
| Contax T2 | Sharp premium compact 35mm. |
| Hasselblad 500 | Square 120 medium-format clarity. |
| Mamiya RB67 | Creamy 6x7 medium-format portrait feel. |
| Olympus Pen F | Half-frame 18x24mm travel diary feel. |
| Holga 120N | Plastic 120 toy-camera vignette and softness. |
| Diana F+ | Dreamy low-fi plastic-lens blur. |
| Polaroid SX-70 | Slow instant chemistry and white-frame rendering. |
| Disposable Flash | Fixed-focus flash plastic camera. |
| Canon PowerShot G2 | Warm early CCD compact digital. |
| Sony DSC-F707 | Vivid CCD with purple/cyan fringing. |
| Mini DV Still | Y2K video-still frame-grab look. |

## Current Film Stocks

| Film | Intent |
| --- | --- |
| Portra 400 | Fine high-speed negative grain, warm skin response, soft shoulder. |
| Ektar 100 | Ultra-vivid fine-grain negative color. |
| Consumer 400 | Warm everyday color, rougher grain, lively yellows/reds. |
| Ektachrome E100 | Neutral, fine-grain E-6 transparency. |
| Velvia 50 | High-saturation landscape chrome. |
| Provia 100F | Faithful crisp slide-film color. |
| Tri-X 400 | Punchy documentary black-and-white grain. |
| HP5 Plus | Medium-contrast forgiving black-and-white. |
| Delta 3200 | Low-light heavy-grain black-and-white. |
| Color Instant | Warm dreamy instant chemistry. |
| CCD Sensor | Early digital sensor/JPEG response for CCD cameras. |

## Control Mapping

- `Intensity`: blends major color/tone/effect identity toward or away from the composed camera/film recipe.
- `Exposure`: applies user EV compensation before profile color shaping.
- `Temperature`: warms or cools the photo in addition to profile defaults.
- `Tint`: shifts magenta/green in addition to profile defaults.
- `Grain`: scales recipe grain/noise amount.
- `Bloom`: scales profile bloom intensity.
- `Halation`: scales profile highlight glow.
- `Vignette`: scales profile edge falloff.
- `Fade`: adds extra lifted-black print fade.
- `Softness`: scales lens softness.
- `Dust`: scales procedural dust.
- `Border`: toggles profile border/frame generation.
