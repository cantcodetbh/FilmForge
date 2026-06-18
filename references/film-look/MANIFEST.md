# Film Look Reference Corpus

Research-only local references for tuning the FilmForge film/disposable camera look. These images are not app assets, not training data, and should not be bundled, published, or used in marketing.

## Summary

- Total verified image files: 45
- Dazz/app-filter references: 14
- HUJI references: 14
- Real disposable references: 10
- Imperfection/flash/film-issue references: 4
- App UI screenshots: 3

## Dazz References

Source pages:
- https://www.autostraddle.com/dazz-cam-app-review/
- https://parallaxaview.com/best-dazz-cam-filters/

Files:
- `dazz/autostraddle-dclassic-room.jpg`
- `dazz/autostraddle-dclassic-sign.jpg`
- `dazz/autostraddle-dclassic-stilllife.jpg`
- `dazz/autostraddle-dfuns-daylight.jpg`
- `dazz/autostraddle-dfuns-market.jpg`
- `dazz/autostraddle-dfuns-night.jpg`
- `dazz/autostraddle-dfuns-portrait.jpg`
- `dazz/parallax-dazz-filter-01.jpg`
- `dazz/parallax-dazz-filter-02.jpg`
- `dazz/parallax-dazz-filter-03.jpg`
- `dazz/parallax-dazz-filter-04.jpg`
- `dazz/parallax-dazz-filter-05.jpg`
- `dazz/parallax-dazz-filter-06b.jpg`
- `dazz/parallax-dazz-filter-07.jpg`

Tuning notes:
- Dazz examples are useful for polished "believable camera" rendering rather than pure defect simulation.
- Autostraddle references emphasize soft detail, warm indoor rendering, organic light leaks, slight blur, and pleasant grain.
- Parallax references are useful for comparing multiple Dazz-style looks: high-contrast saturated D Exp style, softer CPM35-style pastel rendering, and warmer D Fun S-style disposable simulation.

## HUJI References

Source pages:
- https://sarahabibovic.com/2018/05/27/huji-cam-app-review/
- https://ecency.com/@mrslauren/i-ve-become-obsessed-with-the-disposable-film-camera-app-huji

Files:
- `huji/sarah-huji-6067.jpg`
- `huji/sarah-huji-6070.jpg`
- `huji/sarah-huji-6162.jpg`
- `huji/sarah-huji-6163.jpg`
- `huji/sarah-huji-6165.jpg`
- `huji/sarah-huji-6166.jpg`
- `huji/sarah-huji-6167.jpg`
- `huji/ecency-huji-01.jpg`
- `huji/ecency-huji-02.jpg`
- `huji/ecency-huji-board-01.png`
- `huji/ecency-huji-board-02.png`
- `huji/ecency-huji-board-03.png`
- `huji/ecency-huji-board-04.png`
- `huji/ecency-huji-board-05.png`

Tuning notes:
- Several Sarah Abibovic files include EXIF `software=HUJI CAM`, which makes them strong calibration references.
- HUJI targets are less subtle than Dazz: harder flash/contrast behavior, random leak/flare events, timestamp/date-stamp culture, stronger saturation, and more visible "cheap camera" fingerprints.
- The Ecency board images are useful as contact-sheet style comparisons, but should be treated as lower-confidence references than direct HUJI exports.

## Real Disposable References

Source page:
- https://shootitwithfilm.com/fujifilm-quicksnap-and-kodak-funsaver-disposable-cameras/

Files:
- `real-disposable/siwf-fuji-quicksnap-01.jpg`
- `real-disposable/siwf-fuji-quicksnap-02.jpg`
- `real-disposable/siwf-fuji-quicksnap-03.jpg`
- `real-disposable/siwf-fuji-quicksnap-04.jpg`
- `real-disposable/siwf-fuji-quicksnap-05.jpg`
- `real-disposable/siwf-kodak-funsaver-01.jpg`
- `real-disposable/siwf-kodak-funsaver-02.jpg`
- `real-disposable/siwf-kodak-funsaver-03.jpg`
- `real-disposable/siwf-kodak-funsaver-04.jpg`
- `real-disposable/siwf-kodak-funsaver-05.jpg`

Tuning notes:
- These are the grounding references. Use them to decide whether our app output still looks like a phone filter instead of an actual cheap camera.
- Fuji QuickSnap references lean cooler/greener/bluer.
- Kodak FunSaver references lean warmer, grainier, and more colorful.
- Look for fixed-focus softness, flash distance falloff, compressed highlight behavior, plastic-lens edge degradation, and non-clinical color separation.

## Imperfections And Flash References

Source page:
- https://shootitwithfilm.com/fujifilm-quicksnap-and-kodak-funsaver-disposable-cameras/

Files:
- `imperfections/siwf-common-film-issues-01.jpg`
- `imperfections/siwf-tips-disposable-flash-01.jpg`
- `imperfections/siwf-tips-disposable-flash-02.jpg`
- `imperfections/siwf-tips-disposable-flash-03.jpg`

Tuning notes:
- Use these for rare/optional events, not every render.
- Useful targets: light leaks, flash-driven subject separation, underlit backgrounds, and imperfect exposure.

## App Screens

Source pages:
- https://www.autostraddle.com/dazz-cam-app-review/
- https://sarahabibovic.com/2018/05/27/huji-cam-app-review/

Files:
- `app-screens/autostraddle-dazz-camera-picker.png`
- `app-screens/sarah-huji-screen-01.png`
- `app-screens/sarah-huji-screen-02.png`

Tuning notes:
- These are only for understanding UX/camera-selection framing and date-stamp culture. They should not drive image-processing curves.

## Undownloaded Leads

Instagram leads:
- https://www.instagram.com/dazz.camera/
- https://www.instagram.com/reel/CuMb434IF1j/
- https://www.instagram.com/reel/DWTol-yjEIS/
- https://www.instagram.com/reel/DUAJHJ6CA0p/
- https://www.instagram.com/p/B2XO1RCFcvi/
- https://www.instagram.com/p/DVaEh_NDniz/
- https://www.instagram.com/p/DYCOiXdgdV4/
- https://www.instagram.com/p/DBNlb_jvJkI/
- https://www.instagram.com/p/DYXdEDfFEcM/

Reddit leads:
- https://www.reddit.com/r/DazzCam/comments/1tuyemk/my_dazzcam_guide_every_camera_explained/
- https://www.reddit.com/r/DazzCam/comments/1i4t2we/i_did_several_tests_to_see_what_filters_i_would/
- https://www.reddit.com/r/DazzCam/comments/1rx1fmv/which_dazzcam_filter_is_this/
- https://www.reddit.com/r/iPhoneography/comments/1o0peit/some_shots_from_16_pro_max_shot_in_dazzcam_app/
- https://www.reddit.com/r/postprocessing/comments/8056vt/what_is_the_post_processing_being_done_in_apps/
- https://www.reddit.com/r/postprocessing/comments/1qtf3kf/afterbefore_disposable_camera_look/
- https://www.reddit.com/r/disposablecamera/

Notes:
- Reddit preview URLs returned 403 through direct local downloads, so those are kept as source leads instead of corrupt local files.
- The Eric Kim HUJI article still lists many image URLs in HTML, but the media URLs now return 404. It is a useful article lead, not a usable local reference source.

## Calibration Path

1. Pick 6 anchor references: 2 Dazz, 2 HUJI, 1 Kodak FunSaver, 1 Fuji QuickSnap.
2. Render the same 6-10 input photos through FilmForge and create side-by-side contact sheets.
3. Tune in this order: exposure/contrast curve, color separation, digital-detail suppression, lens softness, flash/leak probability, grain.
4. Treat HUJI as a higher-randomness profile family and Dazz as a lower-randomness polished camera family.
5. Keep randomness deterministic per imported photo unless the user explicitly taps a reroll control.
