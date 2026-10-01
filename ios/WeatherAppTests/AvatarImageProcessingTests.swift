import Testing
@testable import WeatherApp
import CoreGraphics
import UIKit

struct AvatarImageProcessingTests {

    private static func makeSolidImage(size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test func targetSizeLeavesSmallImagesUnchanged() {
        let size = CGSize(width: 200, height: 300)
        #expect(AvatarImageProcessing.targetSize(for: size, maxDimension: 400) == size)
    }

    @Test func targetSizeDownscalesLargeImagesPreservingAspectRatio() {
        let size = CGSize(width: 4000, height: 2000) // 2:1
        let result = AvatarImageProcessing.targetSize(for: size, maxDimension: 400)
        #expect(result.width == 400)
        #expect(result.height == 200)
    }

    @Test func targetSizeHandlesTallImages() {
        let size = CGSize(width: 1000, height: 4000) // 1:4, portrait photo
        let result = AvatarImageProcessing.targetSize(for: size, maxDimension: 400)
        #expect(result.height == 400)
        #expect(result.width == 100)
    }

    @Test func targetSizeIgnoresZeroSize() {
        #expect(AvatarImageProcessing.targetSize(for: .zero, maxDimension: 400) == .zero)
    }

    @Test func normalizingOrientationPreservesSize() {
        let image = Self.makeSolidImage(size: CGSize(width: 50, height: 80), color: .red)
        let normalized = AvatarImageProcessing.normalizingOrientation(image)
        #expect(normalized.size == image.size)
    }

    @Test func makeAvatarNeverCrashesAndReturnsAnImage() {
        // No real person in a solid color square, so this exercises the "no person found"
        // fallback through the full pipeline rather than asserting on pixel content.
        let image = Self.makeSolidImage(size: CGSize(width: 800, height: 800), color: .green)
        let avatar = AvatarImageProcessing.makeAvatar(from: image)
        #expect(avatar.size.width <= AvatarImageProcessing.maxDimension)
        #expect(avatar.size.height <= AvatarImageProcessing.maxDimension)
    }
}
