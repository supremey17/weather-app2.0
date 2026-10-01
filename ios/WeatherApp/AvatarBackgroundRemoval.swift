import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Cuts the person out of the photo and makes everything else transparent, using Vision's
/// on-device person-segmentation model as the "contrast" signal between avatar and background:
/// the model scores every pixel by how confident it is that pixel is part of a person, and a
/// hard threshold on that score is where the image splits — above it, the original pixel stays;
/// below it, the pixel becomes fully transparent. No gradient, no soft fade: a clean cut.
///
/// A plain per-pixel RGB contrast/edge threshold was considered and rejected: it falls apart on
/// exactly the cases that matter (dark hair against a dark background, low-contrast lighting,
/// busy backgrounds), because there's no dependable "background color" to measure contrast
/// against in an arbitrary user photo. Vision's model already solves that problem, so the
/// threshold is applied to its confidence map instead of to raw pixels.
enum AvatarBackgroundRemoval {
    /// Mask confidence (0...1) at or above this counts as "avatar"; everything else is cut away.
    static let defaultThreshold: Float = 0.5

    /// The pass/fail rule in isolation, so it's unit-testable without running Vision.
    static func isForeground(maskValue: Double, threshold: Double) -> Bool {
        maskValue >= threshold
    }

    /// Expects an already orientation-normalized image (see `AvatarImageProcessing.makeAvatar`).
    /// Falls back to the original image, untouched, if no person is found or anything in the
    /// pipeline fails — this should never crash or hand back a blank/all-transparent image.
    static func removingBackground(from image: UIImage, threshold: Float = defaultThreshold) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first else {
            return image
        }

        let original = CIImage(cgImage: cgImage)
        var mask = CIImage(cvPixelBuffer: observation.pixelBuffer)

        // The mask is usually a lower resolution than the source photo; scale it up to match so
        // the cutout lines up with the original pixels.
        let scaleX = original.extent.width / mask.extent.width
        let scaleY = original.extent.height / mask.extent.height
        mask = mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let thresholdFilter = CIFilter.colorThreshold()
        thresholdFilter.inputImage = mask
        thresholdFilter.threshold = threshold
        guard let hardMask = thresholdFilter.outputImage else { return image }

        let transparent = CIImage(color: .clear).cropped(to: original.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = original
        blend.backgroundImage = transparent
        blend.maskImage = hardMask
        guard let cutout = blend.outputImage else { return image }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(cutout, from: original.extent) else {
            return image
        }
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: .up)
    }
}
