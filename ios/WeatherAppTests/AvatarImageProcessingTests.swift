import Testing
@testable import WeatherApp
import CoreGraphics

struct AvatarImageProcessingTests {

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
}
