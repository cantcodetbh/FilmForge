import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

struct HalationFilter {
    /// Applies halation. If a precomputed highlight mask is provided, uses that instead of recomputing.
    func apply(to image: CIImage, profile: HalationProfile, intensity: Double, sharedMask: CIImage? = nil) -> CIImage {
        guard profile.enabled, profile.intensity > 0 else { return image }

        let mask: CIImage
        if let shared = sharedMask {
            mask = shared
        } else {
            let localAverage = image
                .clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(1.5, profile.radius * 0.12)])
                .cropped(to: image.extent)

            mask = Self.highlightMaskKernel.apply(
                extent: image.extent,
                arguments: [image, localAverage, CGFloat(profile.threshold), CGFloat(profile.blend)]
            ) ?? image
        }

        // Exponential scatter PSF: physical light scatter through film base follows
        // inverse-exponential decay (tight inner glow + long faint tail).
        // Approximated by 3-pass descending blur — not a single Gaussian bell curve.
        let localMask = mask
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: profile.radius * 0.42])
            .cropped(to: image.extent)

        let midMask = mask
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: profile.radius * 1.4])
            .cropped(to: image.extent)

        let globalMask = mask
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: profile.radius * 3.5])
            .cropped(to: image.extent)

        let glow = Self.tintKernel.apply(
            extent: image.extent,
            arguments: [
                image,
                localMask,
                midMask,
                globalMask,
                profile.tint,
                CGFloat(profile.intensity * intensity * 0.48),
                CGFloat(profile.blend)
            ]
        ) ?? image

        return glow.cropped(to: image.extent)
    }

    /// Computes a highlight mask suitable for sharing between halation and bloom.
    static func makeSharedMask(image: CIImage, threshold: Double, blend: Double, radius: Double) -> CIImage {
        let localAverage = image
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(1.5, radius * 0.12)])
            .cropped(to: image.extent)

        return highlightMaskKernel.apply(
            extent: image.extent,
            arguments: [image, localAverage, CGFloat(threshold), CGFloat(blend)]
        ) ?? image
    }

    private static let highlightMaskKernel = CIColorKernel(source: """
    kernel vec4 halationMask(__sample s, __sample localAverage, float threshold, float blend) {
        float l = dot(s.rgb, vec3(0.70, 0.20, 0.10));
        float base = dot(localAverage.rgb, vec3(0.70, 0.20, 0.10));
        float soft = smoothstep(threshold, min(threshold + 0.22, 1.0), l);
        float contrastEdge = smoothstep(0.015, 0.18, max(l - base, 0.0));
        float chromaEdge = smoothstep(0.04, 0.32, abs(max(max(s.r, s.g), s.b) - min(min(s.r, s.g), s.b)));
        float coolBackground = smoothstep(0.02, 0.22, s.b - max(s.r, s.g));
        float backgroundGain = 1.0 - smoothstep(0.62, 0.96, base) * 0.60 - coolBackground * 0.18;
        float sourceLimit = 1.0 - smoothstep(0.96, 1.35, l) * 0.35;
        float m = soft * mix(0.30, 1.0, max(contrastEdge, chromaEdge * 0.55)) * backgroundGain * sourceLimit * blend;
        return vec4(vec3(m), m);
    }
    """)!

    private static let tintKernel = CIColorKernel(source: """
    kernel vec4 halationTint(__sample source, __sample localMask, __sample midMask, __sample globalMask, __color tint, float intensity, float blend) {
        // Three-pass exponential scatter: tight inner glow (local) +
        // intermediate scatter (mid) + long faint tail (global).
        // Weights follow inverse-exponential decay from the light source.
        float local = clamp(localMask.r * intensity * 0.65, 0.0, 1.0);
        float mid = clamp(midMask.r * intensity * 0.25, 0.0, 0.55);
        float global = clamp(globalMask.r * intensity * (0.08 + blend * 0.12), 0.0, 0.30);
        float m = clamp(local + mid + global, 0.0, 1.0);
        vec3 globalTint = mix(tint.rgb, vec3(1.0, 0.70, 0.30), 0.28);
        vec3 warm = tint.rgb * local + mix(tint.rgb, globalTint, 0.5) * mid + globalTint * global;
        vec3 screened = vec3(1.0) - (vec3(1.0) - source.rgb) * (vec3(1.0) - warm);
        vec3 lifted = mix(source.rgb, screened, clamp(m, 0.0, 0.88));
        return vec4(lifted, source.a);
    }
    """)!
}
