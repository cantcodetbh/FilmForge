import CoreImage
import Foundation

struct DigitalTamingFilter {
    func apply(to image: CIImage, profile: DigitalTamingProfile, intensity: Double) -> CIImage {
        guard profile.enabled else { return image }

        var output = image
        let amount = max(0, min(intensity, 1.5))

        let local = output
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(1.5, 5.0 * profile.clarityReduction * amount)])
            .cropped(to: output.extent)

        output = Self.detailKernel.apply(
            extent: output.extent,
            arguments: [
                output,
                local,
                CGFloat(profile.clarityReduction * amount),
                CGFloat(profile.edgeHaloSuppression * amount),
                CGFloat(profile.localHDRCompression * amount)
            ]
        ) ?? output

        let blurRadius = profile.preBlur * amount
        guard blurRadius > 0.05 else { return output.cropped(to: image.extent) }

        return output
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: blurRadius])
            .cropped(to: image.extent)
    }

    private static let detailKernel = CIColorKernel(source: """
    kernel vec4 tameDigital(__sample source, __sample local, float clarity, float halo, float localHDR) {
        vec3 detail = source.rgb - local.rgb;
        float l = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
        float localL = dot(local.rgb, vec3(0.2126, 0.7152, 0.0722));
        float edge = smoothstep(0.025, 0.24, abs(l - localL));
        float brightLocal = smoothstep(0.58, 0.94, l) * smoothstep(0.48, 0.88, localL);

        vec3 softened = local.rgb + detail * (1.0 - clarity * (0.28 + edge * 0.42));
        vec3 haloDamped = mix(softened, local.rgb + detail * 0.54, edge * halo * 0.50);

        float compressedL = localL + (l - localL) * (1.0 - localHDR * brightLocal * 0.48);
        vec3 chroma = haloDamped - vec3(max(l, 0.0001));
        vec3 compressed = vec3(compressedL) + chroma * (1.0 - localHDR * brightLocal * 0.18);

        vec3 result = mix(haloDamped, compressed, localHDR * brightLocal);
        return vec4(clamp(result, 0.0, 4.0), source.a);
    }
    """)!
}
