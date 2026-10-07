import SwiftUI
import UIKit

/// Shows the user's own pixelated photo if they've set one (see `AvatarPhotoPickerView`),
/// otherwise a generic pixel-art silhouette. The photo itself is the whole outfit — there's no
/// clothing-layer overlay system — except for the optional accessory overlay below (hat/glasses/
/// cigarette). That overlay only ever draws something when a caller explicitly passes a non-empty
/// `accessories` list; the feature is off by default (see `Preferences.isAccessoriesEnabled`), and
/// with the default empty list, rendering is unchanged from before accessories existed.
struct AvatarView: View {
    let image: UIImage?
    var size: CGSize = CGSize(width: 150, height: 220)
    /// Which accessories to draw, if any. Empty (the default) means "no overlay at all" — the
    /// exact same rendering path as before accessories existed.
    var accessories: [AvatarAccessory] = []
    /// Detected face anchors for `image`, or `nil` if there's no photo (the silhouette's fixed
    /// anchors are used instead) or detection found nothing (in which case no accessories render).
    var anchors: FaceAnchors? = nil

    var body: some View {
        Group {
            if accessories.isEmpty {
                avatarImage
            } else {
                ZStack {
                    avatarImage
                    accessoryOverlay
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var avatarImage: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none) // keep the pixel art crisp
                    .scaledToFit()
            } else {
                Image("casual")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            }
        }
    }

    /// The anchors to position accessories against: the ones detected for the user's photo, the
    /// silhouette's fixed anchors when there's no photo, or `nil` (meaning "render nothing") when
    /// there's a photo but detection didn't find a face.
    private var resolvedAnchors: FaceAnchors? {
        anchors ?? (image == nil ? FaceAnchors.silhouetteDefault : nil)
    }

    /// The pixel size of whichever image `avatarImage` is actually showing, used to reproduce its
    /// `.scaledToFit()` layout math. Falls back to `size` (a square-ish guess) if even the
    /// built-in "casual" asset can't be loaded, which keeps the geometry helpers from dividing by
    /// zero rather than crashing.
    private var underlyingImageSize: CGSize {
        if let image { return image.size }
        guard let casual = UIImage(named: "casual") else { return size }
        return casual.size
    }

    private var accessoryOverlay: some View {
        Group {
            if let resolvedAnchors {
                ForEach(accessories) { accessory in
                    accessoryView(accessory, anchors: resolvedAnchors)
                }
            }
        }
    }

    @ViewBuilder
    private func accessoryView(_ accessory: AvatarAccessory, anchors: FaceAnchors) -> some View {
        let rect = AvatarAccessoryGeometry.aspectFitRect(imageSize: underlyingImageSize, in: size)
        let normalizedAnchor = AvatarAccessoryGeometry.anchorPoint(for: accessory.slot, in: anchors)
        let position = AvatarAccessoryGeometry.point(normalizedAnchor, imageSize: underlyingImageSize, in: size)
        let faceWidthPoints = max(anchors.faceWidth * rect.width, 0)
        let accessoryWidth = max(accessory.widthFraction * faceWidthPoints, 0)
        let offset = CGSize(
            width: accessory.anchorOffset.width * faceWidthPoints,
            height: accessory.anchorOffset.height * faceWidthPoints
        )

        Group {
            if let uiImage = UIImage(named: accessory.assetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: accessoryWidth, height: accessoryWidth)
            } else {
                PixelSprite(accessory.placeholderSprite, scale: 2)
                    .frame(width: accessoryWidth, height: accessoryWidth)
            }
        }
        .position(x: position.x + offset.width, y: position.y + offset.height)
    }
}

/// Pure geometry helpers for positioning accessory overlays, pulled out of the view body so they
/// can be unit tested without rendering anything. All inputs/outputs that represent Vision points
/// use Vision's convention (normalized `0...1`, origin bottom-left); outputs that represent view
/// points use SwiftUI's convention (points, origin top-left).
enum AvatarAccessoryGeometry {
    /// The rect, within `frameSize`, that an image with aspect ratio `imageSize` occupies once
    /// laid out with `.scaledToFit()` — i.e. the letterboxed/pillarboxed rect, excluding the empty
    /// margin on either side. Falls back to the full frame if either size is degenerate (zero
    /// width or height), so callers never divide by zero or produce NaN.
    static func aspectFitRect(imageSize: CGSize, in frameSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              frameSize.width > 0, frameSize.height > 0 else {
            return CGRect(origin: .zero, size: frameSize)
        }

        let imageAspect = imageSize.width / imageSize.height
        let frameAspect = frameSize.width / frameSize.height

        if imageAspect > frameAspect {
            // Image is relatively wider than the frame: fits full width, letterboxed top/bottom.
            let height = frameSize.width / imageAspect
            return CGRect(x: 0, y: (frameSize.height - height) / 2, width: frameSize.width, height: height)
        } else {
            // Image is relatively taller than the frame: fits full height, pillarboxed left/right.
            let width = frameSize.height * imageAspect
            return CGRect(x: (frameSize.width - width) / 2, y: 0, width: width, height: frameSize.height)
        }
    }

    /// Maps a Vision-space normalized point into the view's point space, inside the aspect-fit
    /// image rect for `imageSize` laid out in `frameSize`. Flips the y-axis to go from Vision's
    /// bottom-left origin to SwiftUI's top-left origin. Returns the frame's center — not NaN — if
    /// the fit rect is degenerate.
    static func point(_ normalized: CGPoint, imageSize: CGSize, in frameSize: CGSize) -> CGPoint {
        let rect = aspectFitRect(imageSize: imageSize, in: frameSize)
        guard rect.width > 0, rect.height > 0 else {
            return CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        }
        let x = rect.minX + normalized.x * rect.width
        let y = rect.minY + (1 - normalized.y) * rect.height
        return CGPoint(x: x, y: y)
    }

    /// Which `FaceAnchors` point an accessory slot attaches to.
    static func anchorPoint(for slot: AccessorySlot, in anchors: FaceAnchors) -> CGPoint {
        switch slot {
        case .head: anchors.faceTop
        case .eyes: anchors.eyesCenter
        case .mouth: anchors.mouthCenter
        }
    }
}

#Preview {
    AvatarView(image: nil)
}
