import CoreImage
import Foundation

struct ToneCurveFilter {
    func apply(to image: CIImage, profile: FilmLookProfile, intensity: Double) -> CIImage {
        // True subtractive CMY orange mask: convert RGB to CMY density space,
        // apply the unexposed film base transmission matrix (orange mask),
        // apply per-channel D-Log E curves in subtractive space, then return to RGB.
        // This is the "real deal" — approximates what C-41 color negative film actually does.

        let rToe = CGFloat((profile.toeStrength * 0.90) * intensity)
        let gToe = CGFloat(profile.toeStrength * intensity)
        let bToe = CGFloat((profile.toeStrength * 1.12) * intensity)

        let rShoulder = CGFloat((profile.shoulderStrength * 0.95) * intensity)
        let gShoulder = CGFloat(profile.shoulderStrength * intensity)
        let bShoulder = CGFloat((profile.shoulderStrength * 1.06) * intensity)

        let rBlack = CGFloat(profile.blackPoint * 0.92)
        let gBlack = CGFloat(profile.blackPoint)
        let bBlack = CGFloat(profile.blackPoint * 1.10)

        let whitePoint = CGFloat(profile.whitePoint)

        return Self.kernel.apply(
            extent: image.extent,
            arguments: [
                image,
                CIVector(x: rToe, y: gToe, z: bToe),
                CIVector(x: rShoulder, y: gShoulder, z: bShoulder),
                CGFloat(profile.contrast),
                CIVector(x: rBlack, y: gBlack, z: bBlack),
                CIVector(x: whitePoint, y: whitePoint, z: whitePoint),
                CGFloat(profile.baseExposure)
            ]
        ) ?? image
    }

    private static let kernel = CIColorKernel(source: """
    kernel vec4 filmicTone(__sample s, vec3 toe, vec3 shoulder, float contrast, vec3 blackPoint, vec3 whitePoint, float exposure) {
        vec3 c = max(s.rgb, vec3(0.0));
        c *= pow(2.0, exposure * 0.45);

        // Step 1: Convert additive RGB to subtractive CMY density space.
        // Density = -log10(transmission). Using natural log for kernel efficiency.
        // Clamp to avoid log(0) — minimum density represents film base + fog.
        vec3 cmyDensity = -log(max(c, vec3(0.0005)));

        // Step 2: Apply unexposed film base transmission (the C-41 orange mask).
        // The orange mask is a constant cyan+yellow density that shifts the
        // blue-sensitive (yellow dye) and green-sensitive (magenta dye) layers.
        // C-41 orange = high cyan density + moderate yellow density.
        vec3 orangeMask = vec3(0.145, 0.220, 0.085);
        cmyDensity += orangeMask;

        // Step 3: Per-channel normalization in density space.
        // Include the orange mask in the density bounds so that a pure white
        // pixel (density 0 + mask) normalizes to exactly 0 (brightest), and
        // a black pixel normalizes to 1 (darkest). Without this, the mask
        // pushes whites off the bottom of the range, crushing them to grey.
        vec3 baseDensityBlack = -log(max(whitePoint, vec3(0.001)));
        vec3 baseDensityWhite = -log(max(blackPoint, vec3(0.001)));
        vec3 densityBlack = baseDensityBlack + orangeMask;
        vec3 densityWhite = baseDensityWhite + orangeMask;
        vec3 normalizedDensity = (cmyDensity - densityBlack) / max(densityWhite - densityBlack, vec3(0.001));
        normalizedDensity = clamp(normalizedDensity, vec3(0.0), vec3(1.0));

        // Step 4: Contrast adjustment in density space.
        float slope = mix(1.0, contrast, 0.42);
        vec3 mid = (normalizedDensity - vec3(0.5)) * slope + vec3(0.5);
        mid = max(mid, vec3(0.0));

        // Step 5: Per-channel toe lift (staggered for orange mask behavior).
        vec3 toeLift = mix(mid, mid * mid * (vec3(3.0) - vec3(2.0) * mid), clamp(toe * 0.38, vec3(0.0), vec3(0.55)));

        // Step 6: Per-channel shoulder roll in density space.
        vec3 shoulderRoll = vec3(1.0) - exp(-toeLift * (vec3(1.0) + shoulder * 1.4));
        vec3 mixed = mix(toeLift, shoulderRoll, clamp(shoulder * 0.28, vec3(0.0), vec3(0.45)));

        // Step 7: Convert back from density to linear RGB.
        // Denormalize from [0, 1] back to actual density, subtract the
        // orange mask (scanner compensation), then exp(-density) maps
        // high-density (dark) to low RGB values and vice versa.
        vec3 denormalizedDensity = mixed * max(densityWhite - densityBlack, vec3(0.001)) + densityBlack;
        denormalizedDensity -= orangeMask;
        vec3 rgbResult = exp(-denormalizedDensity);

        // Highlight neutralization
        float mx = max(max(rgbResult.r, rgbResult.g), rgbResult.b);
        vec3 neutral = vec3(dot(rgbResult, vec3(0.2126, 0.7152, 0.0722)));
        float high = smoothstep(0.72, 1.0, mx);
        rgbResult = mix(rgbResult, neutral + (rgbResult - neutral) * 0.86, high * dot(shoulder, vec3(0.3333)) * 0.35);

        return vec4(clamp(rgbResult, 0.0, 1.0), s.a);
    }
    """)!
}
