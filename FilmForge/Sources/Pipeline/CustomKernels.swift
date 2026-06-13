import CoreImage
import Foundation

enum FilmKernelLibrary {
    static let filmicResponse: CIColorKernel? = {
        metalColorKernel(named: "filmicResponse") ?? CIColorKernel(source:
            """
            kernel vec4 filmicResponse(__sample image, float toe, float shoulder, float lift, float intensity) {
                vec3 color = max(image.rgb, vec3(0.0));
                vec3 lifted = color + vec3(lift);
                vec3 toeMapped = pow(lifted, vec3(max(0.25, toe)));
                vec3 shouldered = vec3(1.0) - exp(-toeMapped * max(0.6, shoulder));
                vec3 outputColor = mix(color, shouldered, clamp(intensity, 0.0, 1.0));
                return vec4(clamp(outputColor, 0.0, 1.0), image.a);
            }
            """
        )
    }()

    static let filmGrain: CIColorKernel? = {
        metalColorKernel(named: "filmGrain") ?? CIColorKernel(source:
            """
            float hash21(vec2 p) {
                p = fract(p * vec2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return fract(p.x * p.y);
            }

            kernel vec4 filmGrain(__sample image, float amount, float scale, float colorAmount, float seed, float shadowWeight, float highlightWeight) {
                vec2 p = floor(destCoord() / max(scale, 0.45));
                float n1 = hash21(p + vec2(seed, seed * 1.371));
                float n2 = hash21(p * 1.73 + vec2(seed * 0.417, seed * 1.913));
                float n3 = hash21(p * 2.31 + vec2(seed * 2.117, seed * 0.791));
                float clump = (n1 + n2 * 0.62 + n3 * 0.38) / 2.0;
                float lum = dot(image.rgb, vec3(0.2126, 0.7152, 0.0722));
                float mid = 1.0 - abs(lum * 2.0 - 1.0);
                float response = mix(shadowWeight, highlightWeight, lum);
                response = max(response, mid * 0.55);
                float grain = (clump - 0.5) * amount * response;
                vec3 mono = vec3(grain);
                vec3 chroma = vec3(
                    (n1 - 0.5) * amount * response,
                    (n2 - 0.5) * amount * response,
                    (n3 - 0.5) * amount * response
                );
                vec3 outputColor = image.rgb + mix(mono, chroma, clamp(colorAmount, 0.0, 1.0));
                return vec4(clamp(outputColor, 0.0, 1.0), image.a);
            }
            """
        )
    }()

    static var usesMetalKernels: Bool {
        metalKernels["filmicResponse"] != nil && metalKernels["filmGrain"] != nil
    }

    private static func metalColorKernel(named name: String) -> CIColorKernel? {
        metalKernels[name]
    }

    private static let metalKernels: [String: CIColorKernel] = {
        guard #available(macOS 12.0, *) else { return [:] }
        let kernels = try? CIKernel.kernels(withMetalString:
            """
            #include <CoreImage/CoreImage.h>
            using namespace metal;

            float filmforgeHash21(float2 p) {
                p = fract(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return fract(p.x * p.y);
            }

            [[ stitchable ]] half4 filmicResponse(coreimage::sample_h image, float toe, float shoulder, float lift, float intensity) {
                float3 color = max(float3(image.rgb), float3(0.0));
                float3 lifted = color + float3(lift);
                float3 toeMapped = pow(lifted, float3(max(0.25, toe)));
                float3 shouldered = float3(1.0) - exp(-toeMapped * max(0.6, shoulder));
                float3 outputColor = mix(color, shouldered, clamp(intensity, 0.0, 1.0));
                return half4(half3(clamp(outputColor, 0.0, 1.0)), image.a);
            }

            [[ stitchable ]] half4 filmGrain(coreimage::sample_h image, float amount, float scale, float colorAmount, float seed, float shadowWeight, float highlightWeight, coreimage::destination dest) {
                float2 p = floor(dest.coord() / max(scale, 0.45));
                float n1 = filmforgeHash21(p + float2(seed, seed * 1.371));
                float n2 = filmforgeHash21(p * 1.73 + float2(seed * 0.417, seed * 1.913));
                float n3 = filmforgeHash21(p * 2.31 + float2(seed * 2.117, seed * 0.791));
                float clump = (n1 + n2 * 0.62 + n3 * 0.38) / 2.0;
                float3 rgb = float3(image.rgb);
                float lum = dot(rgb, float3(0.2126, 0.7152, 0.0722));
                float mid = 1.0 - abs(lum * 2.0 - 1.0);
                float response = mix(shadowWeight, highlightWeight, lum);
                response = max(response, mid * 0.55);
                float grain = (clump - 0.5) * amount * response;
                float3 mono = float3(grain);
                float3 chroma = float3(
                    (n1 - 0.5) * amount * response,
                    (n2 - 0.5) * amount * response,
                    (n3 - 0.5) * amount * response
                );
                float3 outputColor = rgb + mix(mono, chroma, clamp(colorAmount, 0.0, 1.0));
                return half4(half3(clamp(outputColor, 0.0, 1.0)), image.a);
            }
            """
        )
        return kernels?.reduce(into: [String: CIColorKernel]()) { result, kernel in
            guard let colorKernel = kernel as? CIColorKernel else { return }
            result[kernel.name] = colorKernel
        } ?? [:]
    }()
}
