# FilmForge

FilmForge is a native macOS photo app proof of concept for applying original camera and film-inspired recipes to imported photos. It does not capture from the Mac camera and does not use cloud services, accounts, telemetry, or subscription logic.

## What Works In This Build

- Import JPG, PNG, HEIC, TIFF, and other system-supported image files.
- Drag a photo into the preview area or use `File > Open Photo...`.
- Choose from 12 camera profiles and compatible film/sensor responses.
- Adjust intensity, exposure, temperature, tint, grain, bloom, halation, vignette, fade, softness, dust, and border.
- Toggle between original and processed preview.
- Export JPG or PNG without overwriting the original image.

## Build And Run

Requirements:

- macOS with Xcode 26.5 or compatible modern Xcode.
- XcodeGen installed at `/opt/homebrew/bin/xcodegen` or available on `PATH`.

Generate the project:

```sh
xcodegen generate
```

Build from the command line:

```sh
xcodebuild -project FilmForge.xcodeproj -scheme FilmForge -configuration Debug -destination 'platform=macOS' build
```

Open in Xcode:

```sh
open FilmForge.xcodeproj
```

## Project Layout

- `FilmForge/Sources/App`: app entry point.
- `FilmForge/Sources/UI`: SwiftUI editor.
- `FilmForge/Sources/Models`: profile, recipe, and adjustment models.
- `FilmForge/Sources/Profiles`: camera catalog, film stock catalog, and recipe composer.
- `FilmForge/Sources/Pipeline`: reusable Core Image film engine.
- `FilmForge/Sources/Services`: import, preview, export, and editor orchestration.
- `docs/film_filter_research.md`: research foundation.
- `docs/camera_film_profile_research.md`: camera/film profile research and implementation mapping.
- `docs/architecture.md`: implementation architecture.
- `docs/profile_design.md`: profile recipe design.
- `docs/roadmap.md`: next steps.

## Design Principle

FilmForge is built around reusable camera-plus-film recipes, not one-off hardcoded filters. The UI selects a `CameraProfile` and `FilmStock`; FilmForge composes them into `FilmProfile` data, and the Core Image pipeline interprets that data through composable stages.
