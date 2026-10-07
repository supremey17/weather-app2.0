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

    @Test func catalogHasExactlyThreeItemsPerSlot() {
        let slots = AvatarAccessory.catalog.map(\.slot)
        #expect(Set(slots) == Set(AccessorySlot.allCases))
        for slot in AccessorySlot.allCases {
            #expect(slots.filter { $0 == slot }.count == 3)
        }
    }

    // MARK: - AvatarAccessory.options(for:) / accessory(id:)

    @Test func optionsReturnsExactlyThreeItemsPerSlotMatchingThatSlot() {
        for slot in AccessorySlot.allCases {
            let options = AvatarAccessory.options(for: slot)
            #expect(options.count == 3)
            #expect(options.allSatisfy { $0.slot == slot })
        }
    }

    @Test func optionsPreservesCatalogOrder() {
        for slot in AccessorySlot.allCases {
            let expected = AvatarAccessory.catalog.filter { $0.slot == slot }
            #expect(AvatarAccessory.options(for: slot).map(\.id) == expected.map(\.id))
        }
    }

    @Test func accessoryFindsKnownIDAndReturnsNilForUnknownID() {
        #expect(AvatarAccessory.accessory(id: "partyhat")?.slot == .head)
        #expect(AvatarAccessory.accessory(id: "shades")?.slot == .eyes)
        #expect(AvatarAccessory.accessory(id: "not-a-real-id") == nil)
    }

    // MARK: - AvatarAccessory.cycledAccessoryID

    @Test func cyclingForwardFromNilVisitsAllThreeOptionsThenReturnsToNil() {
        let slot = AccessorySlot.head
        let options = AvatarAccessory.options(for: slot).map(\.id)

        var current: String? = nil
        var visited: [String?] = []
        for _ in 0..<4 {
            current = AvatarAccessory.cycledAccessoryID(currentID: current, slot: slot, forward: true)
            visited.append(current)
        }

        #expect(visited == [options[0], options[1], options[2], nil])
    }

    @Test func cyclingBackwardFromNilGoesToTheLastOption() {
        let slot = AccessorySlot.eyes
        let options = AvatarAccessory.options(for: slot).map(\.id)

        let previous = AvatarAccessory.cycledAccessoryID(currentID: nil, slot: slot, forward: false)
        #expect(previous == options.last)
    }

    @Test func cyclingBackwardFullCircleReturnsToNil() {
        let slot = AccessorySlot.mouth
        var current: String? = nil
        for _ in 0..<4 {
            current = AvatarAccessory.cycledAccessoryID(currentID: current, slot: slot, forward: false)
        }
        #expect(current == nil)
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

    // MARK: - Preferences.selectedAccessoryIDs

    /// Matches the literal UserDefaults key `Preferences` stores `selectedAccessoryIDs` under, so
    /// this test can poke bogus raw values directly into the same suite without `Preferences`
    /// exposing that key as public API.
    private static let selectedAccessoryIDsKey = "selected_accessory_ids"

    @Test func selectedAccessoryIDsRoundTripsAFullValidSelection() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        let selection: [AccessorySlot: String] = [
            .head: "beanie",
            .eyes: "monocle",
            .mouth: "pipe",
        ]
        prefs.selectedAccessoryIDs = selection
        #expect(prefs.selectedAccessoryIDs == selection)
    }

    @Test func selectedAccessoryIDsDropsAnEntryWithAnInvalidSlotKey() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        defaults.set(
            ["not-a-real-slot": "partyhat", "head": "partyhat"],
            forKey: Self.selectedAccessoryIDsKey
        )

        #expect(prefs.selectedAccessoryIDs == [.head: "partyhat"])
    }

    @Test func selectedAccessoryIDsDropsAnEntryWhoseIDBelongsToADifferentSlot() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        // "roundglasses" is a real catalog id, but it belongs to .eyes, not .head — this must be
        // dropped rather than trusted, since a corrupted or stale-after-a-catalog-change value
        // should never crash or silently mis-slot an accessory.
        defaults.set(
            ["head": "roundglasses", "eyes": "shades"],
            forKey: Self.selectedAccessoryIDsKey
        )

        #expect(prefs.selectedAccessoryIDs == [.eyes: "shades"])
    }

    @Test func selectedAccessoryIDsNeverCrashesOnCompletelyBogusStoredData() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        defaults.set(
            ["head": "nonexistent-id", "bogus-slot": "cap", "mouth": "cigarette"],
            forKey: Self.selectedAccessoryIDsKey
        )

        #expect(prefs.selectedAccessoryIDs == [.mouth: "cigarette"])
    }
}

// MARK: - WeatherViewModel.activeAccessories

@MainActor
struct WeatherViewModelActiveAccessoriesTests {
    /// Each test gets its own throwaway UserDefaults suite and avatar photo directory so tests
    /// can't interfere with each other or touch real storage. Mirrors
    /// `WeatherViewModelSavedCityTests.makeModel()`.
    private func makeModel(prefs: Preferences) -> WeatherViewModel {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let avatarStore = AvatarPhotoStore(directory: dir)
        return WeatherViewModel(prefs: prefs, avatarStore: avatarStore)
    }

    @Test func activeAccessoriesIsEmptyWhenAccessoriesDisabled() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)
        prefs.isAvatarEnabled = true
        prefs.isAccessoriesEnabled = false
        prefs.selectedAccessoryIDs = [.head: "cap", .eyes: "shades", .mouth: "pipe"]

        let model = makeModel(prefs: prefs)
        #expect(model.activeAccessories.isEmpty)
    }

    @Test func activeAccessoriesIsEmptyWhenAvatarDisabledEvenIfAccessoriesEnabled() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)
        prefs.isAvatarEnabled = false
        prefs.isAccessoriesEnabled = true
        prefs.selectedAccessoryIDs = [.head: "cap"]

        let model = makeModel(prefs: prefs)
        #expect(model.activeAccessories.isEmpty)
    }

    @Test func activeAccessoriesResolvesValidSelectionsWhenEnabled() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)
        prefs.isAvatarEnabled = true
        prefs.isAccessoriesEnabled = true
        prefs.selectedAccessoryIDs = [.head: "cap", .mouth: "pipe"]

        let model = makeModel(prefs: prefs)
        let resolvedIDs = model.activeAccessories.map(\.id)
        #expect(resolvedIDs == ["cap", "pipe"])
    }
}
