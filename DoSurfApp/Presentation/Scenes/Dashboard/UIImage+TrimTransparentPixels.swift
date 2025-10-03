import UIKit

extension UIImage {
    /// Trims transparent pixels around the image bounds.
    /// - Parameter threshold: Alpha threshold (0~255). Pixels with alpha <= threshold are treated as transparent.
    /// - Returns: A new UIImage with transparent borders removed, or self if trimming is not needed.
    func trimmedTransparentPixels(threshold: UInt8 = 1) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        guard let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }

        let ptr = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * bytesPerRow + x * bytesPerPixel
                let alpha = ptr[idx + 3]
                if alpha > threshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        // If fully transparent or no opaque pixels found, return original
        if minX > maxX || minY > maxY {
            return self
        }

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        guard let cropped = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropped, scale: self.scale, orientation: self.imageOrientation)
    }
}
