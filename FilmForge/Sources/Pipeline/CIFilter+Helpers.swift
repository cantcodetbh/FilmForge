import CoreImage
import Foundation

extension CIImage {
    func applyingFilterIfAvailable(_ name: String, parameters: [String: Any]) -> CIImage {
        guard let filter = CIFilter(name: name) else { return self }
        filter.setValue(self, forKey: kCIInputImageKey)
        for (key, value) in parameters {
            filter.setValue(value, forKey: key)
        }
        return filter.outputImage ?? self
    }
}

func clamped(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
    min(max(value, lower), upper)
}

func mix(_ original: CIImage, with filtered: CIImage, amount: Double) -> CIImage {
    let amount = clamped(amount, 0, 1)
    guard amount > 0.001 else { return original }
    guard amount < 0.999 else { return filtered.cropped(to: original.extent) }
    guard let filter = CIFilter(name: "CIMix") else { return filtered.cropped(to: original.extent) }
    filter.setValue(filtered.cropped(to: original.extent), forKey: kCIInputImageKey)
    filter.setValue(original, forKey: "inputBackgroundImage")
    filter.setValue(amount, forKey: "inputAmount")
    return (filter.outputImage ?? filtered).cropped(to: original.extent)
}

func constantColorImage(red: Double, green: Double, blue: Double, alpha: Double, extent: CGRect) -> CIImage {
    CIImage(color: CIColor(red: red, green: green, blue: blue, alpha: alpha)).cropped(to: extent)
}

func radialEdgeMask(extent: CGRect, inner: CGFloat, outer: CGFloat) -> CIImage {
    let center = CIVector(x: extent.midX, y: extent.midY)
    guard let filter = CIFilter(name: "CIRadialGradient") else {
        return constantColorImage(red: 1, green: 1, blue: 1, alpha: 1, extent: extent)
    }
    filter.setValue(center, forKey: "inputCenter")
    filter.setValue(inner, forKey: "inputRadius0")
    filter.setValue(max(inner + 1, outer), forKey: "inputRadius1")
    filter.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 1), forKey: "inputColor0")
    filter.setValue(CIColor(red: 1, green: 1, blue: 1, alpha: 1), forKey: "inputColor1")
    return (filter.outputImage ?? CIImage.empty()).cropped(to: extent)
}
