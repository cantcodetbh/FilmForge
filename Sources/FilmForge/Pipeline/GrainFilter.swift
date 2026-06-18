import CoreImage
import Foundation

struct GrainFilter {
    func apply(to image: CIImage, profile: GrainProfile, intensity: Double, softness: Double, seed: TimeInterval) -> CIImage {
        guard profile.enabled, profile.strength > 0 else { return image }
        let extent = image.extent
        // Resolution-aware grain: scale grain to physical 35mm-equivalent size.
        // Grain appears identical regardless of export resolution (1080p vs 4K).
        let physicalScale: Double = max(extent.width, extent.height) / 1800.0
        let baseScale = max(0.45, profile.size) / max(physicalScale, 0.28)
        let source = applyResolutionCoupling(to: image, profile: profile, softness: softness)

        let fine = random(extent: extent, scale: baseScale, seed: seed, channel: 1)
        let medium = random(extent: extent, scale: baseScale * 1.85, seed: seed, channel: 2)
        let coarse = random(extent: extent, scale: baseScale * 3.2, seed: seed, channel: 3)

        return Self.grainKernel.apply(
            extent: extent,
            arguments: [
                source,
                fine,
                medium,
                coarse,
                CGFloat(profile.strength * intensity * 1.15),
                CGFloat(profile.roughness),
                CGFloat(profile.chromaAmount),
                CGFloat(profile.highlightBias),
                CGFloat(profile.shadowAmount),
                CGFloat(profile.midtoneAmount),
                CGFloat(profile.highlightAmount)
            ]
        ) ?? source
    }

    private func random(extent: CGRect, scale: Double, seed: TimeInterval, channel: Double) -> CIImage {
        let offsetX = CGFloat(Self.fract(sin(seed * 12.9898 + channel * 78.233) * 43758.5453) * 4096)
        let offsetY = CGFloat(Self.fract(sin(seed * 39.3468 + channel * 11.135) * 24634.6345) * 4096)
        let generator = CIFilter(name: "CIRandomGenerator")?.outputImage ?? CIImage.empty()
        let scaled = generator
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return scaled.cropped(to: extent)
    }

    private static func fract(_ value: Double) -> Double {
        value - floor(value)
    }

    private func applyResolutionCoupling(to image: CIImage, profile: GrainProfile, softness: Double) -> CIImage {
        let blurRadius = max(0, (1 - profile.resolution) * profile.size * profile.strength * 7 * softness)
        guard blurRadius > 0.08 else { return image }
        return image
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: blurRadius])
            .cropped(to: image.extent)
    }

    private static let grainKernel = CIColorKernel(source: """
    kernel vec4 filmGrain(__sample source, __sample fine, __sample medium, __sample coarse, float strength, float roughness, float chroma, float highlightBias, float shadowAmount, float midAmount, float highlightAmount) {
        float l = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
        float shadowZone = smoothstep(0.02, 0.22, l) * (1.0 - smoothstep(0.30, 0.58, l));
        float midZone = smoothstep(0.12, 0.44, l) * (1.0 - smoothstep(0.62, 0.92, l));
        float highZone = smoothstep(0.50, 0.90, l) * (1.0 - smoothstep(0.96, 1.0, l));
        float zone = shadowZone * shadowAmount + midZone * midAmount + highZone * highlightAmount;
        float density = mix(1.0 - l, l, highlightBias);
        density = clamp((0.30 + density * 0.70) * zone, 0.0, 1.55);
        float poissonDensity = sqrt(clamp(density, 0.0, 1.55));

        vec3 f = fine.rgb - vec3(0.5);
        vec3 m = medium.rgb - vec3(0.5);
        vec3 c = coarse.rgb - vec3(0.5);
        float mono = dot(f, vec3(0.3333)) * 0.52 + dot(m, vec3(0.3333)) * (0.30 + roughness * 0.18) + dot(c, vec3(0.3333)) * roughness * 0.24;
        float clump = smoothstep(0.12, 0.66, abs(mono) * 1.8 + abs(c.r - 0.5) * roughness * 1.25);
        float amp = 0.72 + clump * (0.64 + roughness * 0.42);
        vec3 n = f * 0.52 + m * (0.30 + roughness * 0.18) + c * roughness * 0.24;
        n *= amp;
        float chromaScale = 0.65 + chroma * 0.35;

        vec3 perChannel = vec3(
            dot(n, vec3(0.40 + chroma * 0.28, 0.28 - chroma * 0.10, 0.32 - chroma * 0.18)),
            dot(n, vec3(0.28 - chroma * 0.06, 0.44 + chroma * 0.24, 0.28 - chroma * 0.18)),
            dot(n, vec3(0.22 - chroma * 0.08, 0.28 - chroma * 0.10, 0.50 + chroma * 0.18))
        );
        vec3 shaped = mix(vec3(mono), n * (0.45 + chromaScale * 0.55) + perChannel * chroma * 0.38, chroma);

        vec3 safeSource = max(source.rgb, vec3(0.0001));
        vec3 densityDomain = -log(safeSource);

        // Pure density-domain grain: modulate each channel's density independently.
        // No additive overlay, no blending — grain IS the image structure per Newson/IPOL 2017.
        // Per-channel grain sizing: blue layer (top, coarsest), green (middle), red (bottom, finest).
        densityDomain.r += shaped.r * strength * poissonDensity * (0.90 + roughness * 0.55) * 0.55;
        densityDomain.g += shaped.g * strength * poissonDensity * (0.90 + roughness * 0.55) * 0.78;
        densityDomain.b += shaped.b * strength * poissonDensity * (0.90 + roughness * 0.55) * 1.0;

        vec3 result = exp(-max(densityDomain, vec3(0.0)));
        return vec4(clamp(result, 0.0, 1.0), source.a);
    }
    """)!
}
