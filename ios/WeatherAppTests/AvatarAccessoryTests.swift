import CoreGraphics
import Foundation
import Testing
@testable import WeatherApp

struct AvatarAccessoryTests {

    // MARK: - AvatarAccessory.catalog

    @Test func catalogHasUniqueAssetNames() {
        let names = AvatarAccessory.catalog.map(\.assetName)
        #expect(Set(names).count == names.count)
    }

    @Test func catalogHasUniqueIDs() {
        let ids = AvatarAccessory.catalog.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func catalogHasExactlyOneItemPerSlot() {
        let slots = AvatarAccessory.catalog.map(\.slot)
        #expect(Set(slots) == Set(AccessorySlot.allCases))
        #expect(slots.count == AccessorySlot.allCases.count)
    }

    // MARK: - AvatarAccessoryGeometry.aspectFitRect / point

    @Test func pointMapsCorrectlyWhenImageIsWiderThanFrame() {
        // 2:1 image inside a square frame letterboxes top/bottom.
        let imageSize = CGSize(width: 400, height: 200)
        let frameSize = CGSize(width: 100, height: 100)

        let rect = AvatarAccessoryGeometry.aspectFitRect(imageSize: imageSize, in: frameSize)
        #expect(rect == CGRect(x: 0, y: 25, width: 100, height: 50))

        // Vision's bottom-left (0, 0) is the bottom-left of the fitted rect in view space.
        let bottomLeft = AvatarAccessoryGeometry.point(CGPoint(x: 0, y: 0), imageSize: imageSize, in: frameSize)
        #expect(bottomLeft == CGPoint(x: 0, y: 75))

        // Vision's top-right (1, 1) is the top-right of the fitted rect in view space.
        let topRight = AvatarAccessoryGeometry.point(CGPoint(x: 1, y: 1), imageSize: imageSize, in: frameSize)
        #expect(topRight == CGPoint(x: 100, y: 25))
    }

    @Test func pointMapsCorrectlyWhenImageIsTallerThanFrame() {
        // 1:2 image inside a square frame pillarboxes left/right.
        let imageSize = CGSize(width: 200, height: 400)
        let frameSize = CGSize(width: 100, height: 100)

        let rect = AvatarAccessoryGeometry.aspectFitRect(imageSize: imageSize, in: frameSize)
        #expect(rect == CGRect(x: 25, y: 0, width: 50, height: 100))

        let bottomLeft = AvatarAccessoryGeometry.point(CGPoint(x: 0, y: 0), imageSize: imageSize, in: frameSize)
        #expect(bottomLeft == CGPoint(x: 25, y: 100))

        let topRight = AvatarAccessoryGeometry.point(CGPoint(x: 1, y: 1), imageSize: imageSize, in: frameSize)
        #expect(topRight == CGPoint(x: 75, y: 0))
    }

    @Test func pointHandlesDegenerateZeroFrameSafely() {
        let result = AvatarAccessoryGeometry.point(
            CGPoint(x: 0.5, y: 0.5), imageSize: CGSize(width: 100, height: 100), in: .zero
        )
        #expect(result.x.isFinite)
        #expect(result.y.isFinite)
        #expect(result == .zero)
    }

    @Test func aspectFitRectHandlesDegenerateZeroImageSizeSafely() {
        let rect = AvatarAccessoryGeometry.aspectFitRect(imageSize: .zero, in: CGSize(width: 100, height: 100))
        #expect(rect.width.isFinite)
        #expect(rect.height.isFinite)
    }

    @Test func anchorPointSelectsTheRightFieldPerSlot() {
        let anchors = FaceAnchors(
            eyesCenter: CGPoint(x: 0.1, y: 0.2),
            mouthCenter: CGPoint(x: 0.3, y: 0.4),
            faceTop: CGPoint(x: 0.5, y: 0.6),
            faceWidth: 0.25
        )
        #expect(AvatarAccessoryGeometry.anchorPoint(for: .head, in: anchors) == anchors.faceTop)
        #expect(AvatarAccessoryGeometry.anchorPoint(for: .eyes, in: anchors) == anchors.eyesCenter)
        #expect(AvatarAccessoryGeometry.anchorPoint(for: .mouth, in: anchors) == anchors.mouthCenter)
    }

    // MARK: - FaceAnchors Codable

    @Test func faceAnchorsRoundTripsThroughCodable() throws {
        let anchors = FaceAnchors(
            eyesCenter: CGPoint(x: 0.45, y: 0.7),
            mouthCenter: CGPoint(x: 0.5, y: 0.6),
            faceTop: CGPoint(x: 0.5, y: 0.85),
            faceWidth: 0.3
        )
        let data = try JSONEncoder().encode(anchors)
        let decoded = try JSONDecoder().decode(FaceAnchors.self, from: data)
        #expect(decoded == anchors)
    }

    // MARK: - Preferences.isAccessoriesEnabled

    @Test func isAccessoriesEnabledDefaultsToFalseAndPersistsWhenSet() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        #expect(prefs.isAccessoriesEnabled == false)

        prefs.isAccessoriesEnabled = true
        #expect(prefs.isAccessoriesEnabled == true)

        prefs.isAccessoriesEnabled = false
        #expect(prefs.isAccessoriesEnabled == false)
    }
}
