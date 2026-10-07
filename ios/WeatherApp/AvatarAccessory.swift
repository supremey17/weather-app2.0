import CoreGraphics
import Foundation

/// Where on the avatar an accessory attaches. Exactly one item can occupy a slot at a time — no
/// stacking (e.g. two hats) yet.
enum AccessorySlot: String, CaseIterable, Codable {
    case head
    case eyes
    case mouth
}

/// One wearable accessory: its `Assets.xcassets` artwork, which slot it occupies, and how big it
/// renders relative to the detected face. See `ios/docs/avatar-accessories.md` for the full
/// design, including the `accessory-<slot>-<id>` asset naming convention `assetName` follows.
struct AvatarAccessory: Identifiable, Codable, Equatable {
    /// Short, stable, unique slug — also the `<id>` half of `assetName`'s naming convention.
    let id: String
    let slot: AccessorySlot
    /// Expected to match an asset named `accessory-<slot>-<id>` in `Assets.xcassets`. That asset
    /// doesn't have to exist yet: `AvatarView` falls back to a placeholder sprite if it's missing.
    let assetName: String
    /// Size relative to the detected face width, e.g. `1.3` renders 1.3x as wide as the face.
    let widthFraction: Double
    /// Fine-tuning offset from the slot's anchor point, in face-width units. `.zero` means
    /// "exactly at the anchor" — positive `width`/`height` nudge right/down in view space.
    var anchorOffset: CGSize = .zero
}

extension AvatarAccessory {
    /// Placeholder catalog: three items per slot. No real artwork exists for these yet (see the
    /// design doc's "still to build" section) — `AvatarView` falls back to a per-item placeholder
    /// sprite (see `placeholderSprite` below) until real `Assets.xcassets` entries land.
    static let catalog: [AvatarAccessory] = [
        AvatarAccessory(
            id: "partyhat", slot: .head, assetName: "accessory-head-partyhat",
            widthFraction: 1.3, anchorOffset: CGSize(width: 0, height: -0.35)
        ),
        AvatarAccessory(
            id: "cap", slot: .head, assetName: "accessory-head-cap",
            widthFraction: 1.15, anchorOffset: CGSize(width: 0, height: -0.3)
        ),
        AvatarAccessory(
            id: "beanie", slot: .head, assetName: "accessory-head-beanie",
            widthFraction: 1.2, anchorOffset: CGSize(width: 0, height: -0.22)
        ),
        AvatarAccessory(
            id: "roundglasses", slot: .eyes, assetName: "accessory-eyes-roundglasses",
            widthFraction: 0.9
        ),
        AvatarAccessory(
            id: "shades", slot: .eyes, assetName: "accessory-eyes-shades",
            widthFraction: 0.95
        ),
        AvatarAccessory(
            id: "monocle", slot: .eyes, assetName: "accessory-eyes-monocle",
            widthFraction: 0.35, anchorOffset: CGSize(width: 0.18, height: 0.02)
        ),
        AvatarAccessory(
            id: "cigarette", slot: .mouth, assetName: "accessory-mouth-cigarette",
            widthFraction: 0.25, anchorOffset: CGSize(width: 0.2, height: 0)
        ),
        AvatarAccessory(
            id: "pipe", slot: .mouth, assetName: "accessory-mouth-pipe",
            widthFraction: 0.3, anchorOffset: CGSize(width: 0.2, height: 0.08)
        ),
        AvatarAccessory(
            id: "lollipop", slot: .mouth, assetName: "accessory-mouth-lollipop",
            widthFraction: 0.22, anchorOffset: CGSize(width: 0.05, height: 0.05)
        ),
    ]

    /// All catalog items for `slot`, in catalog order.
    static func options(for slot: AccessorySlot) -> [AvatarAccessory] {
        catalog.filter { $0.slot == slot }
    }

    /// The first catalog item with the given `id`, or `nil` if no such item exists. Safe to call
    /// with untrusted input (e.g. a value read back from `UserDefaults`) — never crashes.
    static func accessory(id: String) -> AvatarAccessory? {
        catalog.first { $0.id == id }
    }

    /// Steps `currentID` to the next (`forward: true`) or previous (`forward: false`) choice in
    /// the cycle `nil -> options[0] -> options[1] -> ... -> options[n-1] -> nil -> ...` for the
    /// given slot's `options(for:)` list. Returns `nil` if the slot has no options at all.
    ///
    /// Modular arithmetic: the cycle has `options.count + 1` positions (the `+1` is the "NONE"
    /// position, which `currentID == nil` maps to as index `options.count`). Stepping adds or
    /// subtracts 1 and wraps with a non-negative modulo (`((x % n) + n) % n`), since Swift's `%`
    /// can return a negative result for a negative left-hand operand.
    static func cycledAccessoryID(currentID: String?, slot: AccessorySlot, forward: Bool) -> String? {
        let options = options(for: slot)
        guard !options.isEmpty else { return nil }

        let noneIndex = options.count
        let cycleLength = options.count + 1
        let currentIndex = currentID.flatMap { id in options.firstIndex { $0.id == id } } ?? noneIndex

        let step = forward ? 1 : -1
        let rawNext = (currentIndex + step) % cycleLength
        let nextIndex = (rawNext + cycleLength) % cycleLength

        return nextIndex == noneIndex ? nil : options[nextIndex].id
    }
}

extension AvatarAccessory {
    /// The placeholder sprite `AvatarView` draws for this accessory when its real
    /// `Assets.xcassets` artwork (named by `assetName`) doesn't exist yet. Not part of `Codable`
    /// — purely a UI-layer lookup from `id` to art, kept separate from the persisted shape above.
    var placeholderSprite: PixelSpriteKind {
        switch id {
        case "partyhat": .accessoryHatPlaceholder
        case "cap": .accessoryCapPlaceholder
        case "beanie": .accessoryBeaniePlaceholder
        case "roundglasses": .accessoryGlassesPlaceholder
        case "shades": .accessoryShadesPlaceholder
        case "monocle": .accessoryMonoclePlaceholder
        case "cigarette": .accessoryCigarettePlaceholder
        case "pipe": .accessoryPipePlaceholder
        case "lollipop": .accessoryLollipopPlaceholder
        default: .accessoryHatPlaceholder
        }
    }
}
