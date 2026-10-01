import Testing
@testable import WeatherApp
import UIKit

struct AvatarBackgroundRemovalTests {

    // MARK: isForeground (the pure threshold rule)

    @Test func valueAboveThresholdIsForeground() {
        #expect(AvatarBackgroundRemoval.isForeground(maskValue: 0.8, threshold: 0.5))
    }

    @Test func valueBelowThresholdIsBackground() {
        #expect(!AvatarBackgroundRemoval.isForeground(maskValue: 0.2, threshold: 0.5))
    }

    @Test func valueExactlyAtThresholdCountsAsForeground() {
        // The split is inclusive on the foreground side: "at least this confident" keeps the pixel.
        #expect(AvatarBackgroundRemoval.isForeground(maskValue: 0.5, threshold: 0.5))
    }

    @Test func thresholdZeroKeepsEverything() {
        #expect(AvatarBackgroundRemoval.isForeground(maskValue: 0, threshold: 0))
    }

    @Test func thresholdOneKeepsOnlyPerfectConfidence() {
        #expect(!AvatarBackgroundRemoval.isForeground(maskValue: 0.999, threshold: 1))
        #expect(AvatarBackgroundRemoval.isForeground(maskValue: 1, threshold: 1))
    }

    // MARK: removingBackground fallback behavior
    // Vision's actual segmentation accuracy can't be meaningfully unit tested (no person detector
    // to assert against in CI), but the "never return nothing" fallback contract can be: a solid
    // color image has no person in it, so this exercises the "no person found" path.

    @Test func imageWithNoPersonFallsBackToTheOriginal() {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        let solidColorImage = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let result = AvatarBackgroundRemoval.removingBackground(from: solidColorImage)
        #expect(result.size == solidColorImage.size)
    }
}
