# Reference Analysis

Generated from local research-only references in `/Users/josh/Projects/Film Camera/references/film-look`.

## Group Summary

| Group | Count | Luma | Contrast | Saturation | Warm Bias | Highlights | Shadows | Grain Proxy | Edge Contrast | Edge Warm Shift |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| app-screens | 3 | 0.645 | 0.641 | 0.200 | 0.038 | 0.381 | 0.054 | 0.034 | 0.870 | -0.077 |
| dazz-filter-comparisons | 7 | 0.329 | 0.516 | 0.153 | 0.049 | 0.041 | 0.224 | 0.031 | 0.782 | 0.003 |
| dazz-organic | 7 | 0.455 | 0.549 | 0.226 | 0.107 | 0.045 | 0.103 | 0.045 | 0.768 | -0.210 |
| fuji-quicksnap | 5 | 0.625 | 0.468 | 0.147 | -0.041 | 0.145 | 0.024 | 0.027 | 0.558 | -0.102 |
| huji-boards | 7 | 0.281 | 0.702 | 0.136 | 0.017 | 0.081 | 0.490 | 0.027 | 0.646 | -0.026 |
| huji-direct | 7 | 0.333 | 0.658 | 0.134 | 0.038 | 0.050 | 0.326 | 0.038 | 0.807 | -0.010 |
| imperfections | 4 | 0.642 | 0.567 | 0.154 | -0.028 | 0.355 | 0.042 | 0.024 | 0.624 | 0.016 |
| kodak-funsaver | 5 | 0.591 | 0.733 | 0.107 | 0.005 | 0.291 | 0.104 | 0.047 | 0.693 | -0.023 |

## Preset Implications

- Higher `grainProxy` and lower `edgeContrastRatio` point toward stronger density grain, lower render resolution, and heavier edge softness.
- Positive `warmBias` plus high `highlightPressure` points toward warm/red highlight bloom and stronger print rolloff.
- Negative or low `warmBias` with elevated shadows points toward Fuji/cool cyan shadow profiles.
- High saturation and contrast in app-filter references should be handled in `CameraResponseProfile`, not just global saturation.

## Image Metrics

| File | Group | Size | Luma | Contrast | Sat | Warm | Hi | Shadow | Grain | Edge Ratio |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `app-screens/autostraddle-dazz-camera-picker.png` | app-screens | 594x899 | 0.508 | 0.629 | 0.197 | -0.024 | 0.091 | 0.084 | 0.060 | 1.290 |
| `app-screens/sarah-huji-screen-01.png` | app-screens | 471x260 | 0.878 | 0.499 | 0.090 | 0.033 | 0.797 | 0.047 | 0.020 | 0.266 |
| `app-screens/sarah-huji-screen-02.png` | app-screens | 519x254 | 0.548 | 0.796 | 0.312 | 0.103 | 0.256 | 0.030 | 0.024 | 1.053 |
| `dazz/autostraddle-dclassic-room.jpg` | dazz-organic | 1200x1799 | 0.529 | 0.548 | 0.078 | 0.051 | 0.054 | 0.034 | 0.023 | 0.451 |
| `dazz/autostraddle-dclassic-sign.jpg` | dazz-organic | 1200x1799 | 0.558 | 0.433 | 0.356 | -0.168 | 0.046 | 0.037 | 0.023 | 0.398 |
| `dazz/autostraddle-dclassic-stilllife.jpg` | dazz-organic | 1200x1799 | 0.488 | 0.662 | 0.142 | 0.069 | 0.079 | 0.112 | 0.050 | 0.591 |
| `dazz/autostraddle-dfuns-daylight.jpg` | dazz-organic | 1200x1799 | 0.405 | 0.532 | 0.147 | 0.061 | 0.031 | 0.053 | 0.044 | 1.024 |
| `dazz/autostraddle-dfuns-market.jpg` | dazz-organic | 1200x800 | 0.301 | 0.518 | 0.305 | 0.302 | 0.013 | 0.289 | 0.085 | 0.664 |
| `dazz/autostraddle-dfuns-night.jpg` | dazz-organic | 1200x1799 | 0.411 | 0.522 | 0.425 | 0.375 | 0.028 | 0.084 | 0.035 | 0.980 |
| `dazz/autostraddle-dfuns-portrait.jpg` | dazz-organic | 1200x1799 | 0.495 | 0.630 | 0.131 | 0.060 | 0.062 | 0.110 | 0.057 | 1.266 |
| `dazz/parallax-dazz-filter-01.jpg` | dazz-filter-comparisons | 1000x628 | 0.267 | 0.775 | 0.073 | 0.044 | 0.092 | 0.575 | 0.035 | 0.765 |
| `dazz/parallax-dazz-filter-02.jpg` | dazz-filter-comparisons | 1000x667 | 0.313 | 0.330 | 0.156 | -0.036 | 0.000 | 0.100 | 0.017 | 1.292 |
| `dazz/parallax-dazz-filter-03.jpg` | dazz-filter-comparisons | 1000x628 | 0.447 | 0.651 | 0.319 | 0.290 | 0.109 | 0.087 | 0.035 | 0.576 |
| `dazz/parallax-dazz-filter-04.jpg` | dazz-filter-comparisons | 1000x628 | 0.366 | 0.360 | 0.205 | -0.022 | 0.009 | 0.000 | 0.014 | 0.656 |
| `dazz/parallax-dazz-filter-05.jpg` | dazz-filter-comparisons | 1000x628 | 0.380 | 0.447 | 0.072 | 0.037 | 0.045 | 0.097 | 0.020 | 0.672 |
| `dazz/parallax-dazz-filter-06b.jpg` | dazz-filter-comparisons | 1000x628 | 0.238 | 0.573 | 0.121 | 0.077 | 0.001 | 0.472 | 0.042 | 0.750 |
| `dazz/parallax-dazz-filter-07.jpg` | dazz-filter-comparisons | 1000x667 | 0.292 | 0.476 | 0.127 | -0.048 | 0.029 | 0.234 | 0.051 | 0.761 |
| `huji/ecency-huji-01.jpg` | huji-boards | 1334x750 | 0.502 | 0.714 | 0.396 | 0.122 | 0.148 | 0.036 | 0.022 | 1.120 |
| `huji/ecency-huji-02.jpg` | huji-boards | 400x300 | 0.452 | 0.853 | 0.175 | 0.022 | 0.173 | 0.256 | 0.035 | 0.798 |
| `huji/ecency-huji-board-01.png` | huji-boards | 4800x5868 | 0.246 | 0.752 | 0.055 | 0.016 | 0.065 | 0.565 | 0.022 | 0.483 |
| `huji/ecency-huji-board-02.png` | huji-boards | 4800x5868 | 0.126 | 0.505 | 0.071 | 0.026 | 0.027 | 0.759 | 0.021 | 0.411 |
| `huji/ecency-huji-board-03.png` | huji-boards | 4800x5868 | 0.223 | 0.789 | 0.045 | -0.008 | 0.071 | 0.644 | 0.021 | 0.302 |
| `huji/ecency-huji-board-04.png` | huji-boards | 4800x5868 | 0.254 | 0.780 | 0.060 | -0.036 | 0.075 | 0.558 | 0.032 | 0.597 |
| `huji/ecency-huji-board-05.png` | huji-boards | 4800x5868 | 0.163 | 0.520 | 0.148 | -0.021 | 0.011 | 0.614 | 0.033 | 0.809 |
| `huji/sarah-huji-6067.jpg` | huji-direct | 2448x3264 | 0.335 | 0.544 | 0.131 | -0.070 | 0.024 | 0.214 | 0.053 | 0.558 |
| `huji/sarah-huji-6070.jpg` | huji-direct | 3264x2448 | 0.292 | 0.485 | 0.130 | 0.010 | 0.018 | 0.271 | 0.064 | 0.734 |
| `huji/sarah-huji-6162.jpg` | huji-direct | 2448x3264 | 0.326 | 0.728 | 0.153 | 0.097 | 0.087 | 0.376 | 0.036 | 1.060 |
| `huji/sarah-huji-6163.jpg` | huji-direct | 2448x3264 | 0.361 | 0.692 | 0.168 | 0.110 | 0.070 | 0.292 | 0.030 | 0.975 |
| `huji/sarah-huji-6165.jpg` | huji-direct | 2448x3264 | 0.360 | 0.692 | 0.109 | 0.010 | 0.034 | 0.307 | 0.043 | 0.927 |
| `huji/sarah-huji-6166.jpg` | huji-direct | 2448x3264 | 0.367 | 0.772 | 0.120 | 0.066 | 0.099 | 0.332 | 0.030 | 0.954 |
| `huji/sarah-huji-6167.jpg` | huji-direct | 3264x2448 | 0.294 | 0.694 | 0.125 | 0.040 | 0.021 | 0.493 | 0.011 | 0.438 |
| `imperfections/siwf-common-film-issues-01.jpg` | imperfections | 850x570 | 0.627 | 0.761 | 0.179 | 0.167 | 0.422 | 0.079 | 0.012 | 0.665 |
| `imperfections/siwf-tips-disposable-flash-01.jpg` | imperfections | 1000x1500 | 0.657 | 0.406 | 0.154 | -0.095 | 0.280 | 0.002 | 0.021 | 0.415 |
| `imperfections/siwf-tips-disposable-flash-02.jpg` | imperfections | 1000x1500 | 0.756 | 0.694 | 0.039 | 0.030 | 0.638 | 0.079 | 0.037 | 0.320 |
| `imperfections/siwf-tips-disposable-flash-03.jpg` | imperfections | 1000x1500 | 0.528 | 0.406 | 0.245 | -0.215 | 0.080 | 0.008 | 0.026 | 1.095 |
| `real-disposable/siwf-fuji-quicksnap-01.jpg` | fuji-quicksnap | 850x1270 | 0.601 | 0.597 | 0.101 | 0.045 | 0.188 | 0.026 | 0.028 | 0.396 |
| `real-disposable/siwf-fuji-quicksnap-02.jpg` | fuji-quicksnap | 850x569 | 0.649 | 0.412 | 0.110 | -0.021 | 0.125 | 0.023 | 0.028 | 0.498 |
| `real-disposable/siwf-fuji-quicksnap-03.jpg` | fuji-quicksnap | 850x569 | 0.559 | 0.451 | 0.168 | -0.110 | 0.042 | 0.018 | 0.022 | 0.552 |
| `real-disposable/siwf-fuji-quicksnap-04.jpg` | fuji-quicksnap | 850x569 | 0.669 | 0.433 | 0.146 | -0.038 | 0.192 | 0.022 | 0.028 | 0.647 |
| `real-disposable/siwf-fuji-quicksnap-05.jpg` | fuji-quicksnap | 850x569 | 0.645 | 0.445 | 0.209 | -0.079 | 0.176 | 0.031 | 0.029 | 0.697 |
| `real-disposable/siwf-kodak-funsaver-01.jpg` | kodak-funsaver | 850x1275 | 0.592 | 0.773 | 0.089 | 0.066 | 0.331 | 0.127 | 0.049 | 0.462 |
| `real-disposable/siwf-kodak-funsaver-02.jpg` | kodak-funsaver | 850x1275 | 0.637 | 0.741 | 0.059 | 0.037 | 0.354 | 0.051 | 0.049 | 0.434 |
| `real-disposable/siwf-kodak-funsaver-03.jpg` | kodak-funsaver | 850x567 | 0.693 | 0.647 | 0.061 | 0.039 | 0.461 | 0.040 | 0.033 | 1.256 |
| `real-disposable/siwf-kodak-funsaver-04.jpg` | kodak-funsaver | 850x1275 | 0.525 | 0.848 | 0.108 | 0.026 | 0.258 | 0.173 | 0.067 | 0.566 |
| `real-disposable/siwf-kodak-funsaver-05.jpg` | kodak-funsaver | 850x1270 | 0.505 | 0.653 | 0.217 | -0.141 | 0.050 | 0.128 | 0.034 | 0.746 |
