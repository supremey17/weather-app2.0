import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Turns a user's photo into the avatar: downscaled (so storage and processing stay cheap — full
/// photos can be several MB) and pixelated (matching the app's existing pixel-art look; this is a
/// style choice, not a privacy/anonymization measure).
enum AvatarImageProcessing {
    static let maxDimension: CGFloat = 400
    /// Roughly how big each pixelated block is, in source pixels, before scaling back up.
    static let pixelScale: Double = 12

    /// Pure, so it's unit-testable without rendering an actual image.
    static func targetSize(for size: CGSize, maxDimension: CGFloat = maxDimension) -> CGSize {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension, largestSide > 0 else { return size }
        let scale = maxDimension / largestSide
        return CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }

    /// Downscales, then applies a pixellate filter. Falls back to a plain downscale if Core Image
    /// can't produce an output (e.g. a corrupt image) rather than throwing away the photo.
    static func pixelate(_ image: UIImage) -> UIImage {
        let targetSize = targetSize(for: image.size)
        let resized = resize(image, to: targetSize) ?? image

        guard let ciImage = CIImage(image: resized) else { return resized }
        let filter = CIFilter.pixellate()
        filter.inputImage = ciImage
        filter.scale = Float(pixelScale)

        let context = CIContext()
        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: ciImage.extent) else {
            return resized
        }
        return UIImage(cgImage: cgImage, scale: resized.scale, orientation: resized.imageOrientation)
    }

    private static func resize(_ image: UIImage, to size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
