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
    /// Placeholder catalog for this scaffold: exactly one item per slot. No real artwork exists
    /// for these yet (see the design doc's "still to build" section), and there's no picker UI to
    /// choose between them — this just establishes the shape of the data.
    static let catalog: [AvatarAccessory] = [
        AvatarAccessory(
            id: "partyhat", slot: .head, assetName: "accessory-head-partyhat",
            widthFraction: 1.3, anchorOffset: CGSize(width: 0, height: -0.35)
        ),
        AvatarAccessory(
            id: "roundglasses", slot: .eyes, assetName: "accessory-eyes-roundglasses",
            widthFraction: 0.9
        ),
        AvatarAccessory(
            id: "cigarette", slot: .mouth, assetName: "accessory-mouth-cigarette",
            widthFraction: 0.25, anchorOffset: CGSize(width: 0.2, height: 0)
        ),
    ]
}
