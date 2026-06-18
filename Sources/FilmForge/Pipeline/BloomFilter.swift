import CoreImage
import Foundation

struct BloomFilter {
    /// Applies bloom. If a precomputed highlight mask is provided, uses that instead of recomputing.
    func apply(to image: CIImage, profile: BloomProfile, intensity: Double, sharedMask: CIImage? = nil) -> CIImage {
        guard profile.enabled, profile.intensity > 0 else { return image }

        let mask: CIImage
        if let shared = sharedMask {
            mask = shared
        } else {
            mask = Self.thresholdKernel.apply(
                extent: image.extent,
                arguments: [image, CGFloat(profile.threshold), CGFloat(profile.softness)]
            ) ?? image
        }

        let bloom = mask
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: profile.radius])
            .cropped(to: image.extent)

        return Self.blendKernel.apply(
            extent: image.extent,
            arguments: [
                image,
                bloom,
                CGFloat(profile.intensity * intensity * 0.55),
                CGFloat(profile.blendMode == .add ? 0 : profile.blendMode == .softLight ? 2 : 1)
            ]
        ) ?? image
    }

    private static let thresholdKernel = CIColorKernel(source: """
    kernel vec4 bloomThreshold(__sample s, float threshold, float softness) {
        float l = dot(s.rgb, vec3(0.2126, 0.7152, 0.0722));
        float mx = max(max(s.r, s.g), s.b);
        float chroma = mx - min(min(s.r, s.g), s.b);
        float source = max(l, mx * 0.86);
        float m = smoothstep(threshold, min(1.18, threshold + max(softness, 0.02) * 0.35), source);
        vec3 softened = mix(vec3(l), s.rgb, 0.72 - smoothstep(0.72, 1.0, l) * 0.18 + chroma * 0.10);
        return vec4(softened * m, m);
    }
    """)!

    private static let blendKernel = CIColorKernel(source: """
    kernel vec4 bloomBlend(__sample source, __sample bloom, float intensity, float mode) {
        vec3 added = source.rgb + bloom.rgb * intensity;
        vec3 screened = vec3(1.0) - (vec3(1.0) - source.rgb) * (vec3(1.0) - bloom.rgb * intensity);
        vec3 soft = (vec3(1.0) - 2.0 * bloom.rgb) * source.rgb * source.rgb + 2.0 * bloom.rgb * source.rgb;
        vec3 result = mode < 0.5 ? added : (mode > 1.5 ? mix(source.rgb, soft, intensity) : screened);
        return vec4(clamp(result, 0.0, 1.0), source.a);
    }
    """)!
}
