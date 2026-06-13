# FilmForge Roadmap

## First Build: Proof Of Concept

Status: implemented in the current worktree.

- Native macOS SwiftUI app.
- Dark three-panel editor interface.
- AppKit photo import with drag-and-drop support.
- Reusable Core Image pipeline.
- 12 camera profiles plus compatible film/sensor responses.
- Live preview with before/original toggle.
- Adjustable recipe controls.
- JPG/PNG export via save panel.
- Research, architecture, profile, roadmap, and README docs.

## Next Build: Performance And Fidelity

- Move rendering behind a dedicated worker actor or operation queue.
- Add preview cache keyed by image, profile, and adjustment hash.
- Add cancellable full-resolution export progress.
- Make grain and dust deterministic with profile/image seeds.
- Add a real edge-aware halation stage.
- Improve chromatic aberration with radial channel offsets.
- Add split comparison slider.

## Investor Demo Build

- Add bundled demo images with permission-safe licensing or generated samples.
- Add profile thumbnails rendered from the current imported image.
- Add a profile detail drawer showing recipe personality in plain language.
- Add export success affordance with "Reveal in Finder".
- Add onboarding moment for drag/drop and non-destructive editing.
- Tune the 12 recipes against a small set of portrait, daylight, night, and indoor images.

## Product Build

- Add batch export.
- Add custom profile saving.
- Add `.cube` LUT import behind the existing color transform architecture.
- Add HEIC export if product testing shows demand.
- Add non-destructive project/session files.
- Add keyboard shortcuts for profile navigation and before/after.
