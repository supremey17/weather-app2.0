# Avatar accessories (scaffold)

Status: scaffold only — model, detector, and a rendering hook exist and compile; there is no
settings toggle, no picker UI, and no real art yet. The feature is off by default and changes
nothing visually until a caller explicitly opts in.

## Goal & privacy boundary

Same boundary as the rest of the avatar feature: everything is on-device. Detection runs with
Apple's Vision framework locally; accessory anchors, the catalog, and the user's photo never
leave the phone, and nothing is uploaded or sent to a server. As with the rest of this codebase,
pixelation is a stylistic choice, not an anonymization measure — accessories don't change that,
and nothing here should be read as adding or removing privacy protection beyond "stays on
device."

## Art spec

- Each accessory is a transparent PNG, pixel-art sized in 16px multiples — matching the
  hand-drawn 16x16 sprite grid convention in `PixelSprites.swift` — and scaled with nearest-
  neighbor interpolation (`interpolation(.none)`) so it stays crisp like the rest of the avatar.
- Assets live in `Assets.xcassets` named `accessory-<slot>-<id>`, e.g. `accessory-head-partyhat`,
  `accessory-eyes-roundglasses`, `accessory-mouth-cigarette`.
- Each asset is documented with an anchor point (where it attaches to the face anchor for its
  slot) and a size expressed as a fraction of the detected face width (`widthFraction`), so the
  accessory scales naturally with whatever face Vision finds rather than being a fixed pixel
  size.

## Slots

Three slots, one item per slot — no stacking (e.g. no hat + headband together) yet:

- `head` — hats
- `eyes` — glasses
- `mouth` — cigarette (and similar mouth props)

## Detection

`FaceAnchorDetector` runs `VNDetectFaceLandmarksRequest` (Vision, fully on-device) and follows
the same shape as the existing `BodyPoseDetector`: synchronous, `try?`-guarded, a minimum-
confidence threshold, nil-on-failure, no force unwraps, and always called off the main actor
(from inside the same `Task.detached` block that already does the pixelation work in
`WeatherViewModel.setAvatarPhoto`).

Detection runs on the **downscaled, pre-pixelation** image, not the final pixelated avatar.
Landmark detection is unreliable on blocky, pixelated input — the model is trained on normal
photographic edges and gradients, and the sharp, large flat blocks produced by `pixellate`
destroy exactly the fine eye/mouth contours the landmark model relies on. Downscaling first (the
same downscale `AvatarImageProcessing.makeAvatar` already does before background removal) keeps
detection cheap without paying that accuracy cost.

If Vision finds no face, or confidence is below the threshold, or required landmark points are
missing, detection returns `nil` and no accessories render for that photo — never a guessed or
default position overlaid on an unrelated photo.

## Coordinate mapping

Vision returns points normalized to `0...1` with the origin at the **bottom-left** of the image.
`AvatarView` renders the avatar image with `.scaledToFit()` inside a fixed `CGSize`, which
letterboxes or pillarboxes depending on how the image's aspect ratio compares to the frame's.
Mapping a Vision point into view space takes two steps:

1. Compute the aspect-fit rect: given the image's own aspect ratio and the frame size, the image
   is either full-width (letterboxed top/bottom) or full-height (pillarboxed left/right); the
   unused margin is split evenly on both sides.
2. Map the normalized point into that rect, flipping the y-axis (`1 - y`) to go from Vision's
   bottom-left origin to SwiftUI's top-left origin: `x = rect.minX + normalized.x * rect.width`,
   `y = rect.minY + (1 - normalized.y) * rect.height`.

This math is pulled out into a small pure helper (`AvatarAccessoryGeometry` in `AvatarView.swift`)
specifically so it's unit-testable without rendering a real view, and so it can be guarded against
zero-size input (a degenerate frame or image size returns a safe fallback point instead of NaN).

## Persistence

Detected anchors are tiny (four points, derived — no pixel data) and are stored as a small JSON
file next to the avatar image, via new `saveAnchors`/`loadAnchors`/`deleteAnchors` methods on
`AvatarPhotoStore` (same directory, same file-based pattern as `avatar.png`). They're deleted
whenever the avatar photo itself is deleted, so there's never a stale anchor file pointing at a
photo that no longer exists.

## Default silhouette

When there's no user photo, the default `"casual"` silhouette image is shown instead, and
detection doesn't run against it — it's a fixed, known asset, so its face position is hand-placed
once (`FaceAnchors.silhouetteDefault`) rather than detected every time. Those values are tuned by
eye against that specific asset; if `"casual"` is ever redrawn or re-cropped, they need to be
re-tuned, or accessories will drift off the silhouette's face.

## Still to build

Explicitly out of scope for this scaffold:

- Settings toggle UI (the `Preferences.isAccessoriesEnabled` flag exists and defaults to `false`,
  but nothing in Settings exposes it yet).
- Accessory picker UI.
- Real pixel-art PNGs — `AvatarAccessory.catalog`'s `assetName`s don't have matching assets yet,
  so `AvatarView` falls back to a placeholder `PixelSprite` per slot.
- Persisting the user's *chosen* accessory per slot. Only the catalog (what accessories exist)
  and the anchors (where a face is) exist so far — there's no "the user picked this hat" state.

## Open questions

- **No face found**: already handled — `FaceAnchorDetector` returns `nil` and `AvatarView` renders
  no accessories for that photo.
- **Multiple faces in frame**: the detector picks the first/largest face observation and ignores
  the rest; there's no multi-person accessory placement.
- **Re-posing**: if the user's photo changes but their face doesn't move much, should detection
  re-run or should stale anchors be reused? Out of scope for now — detection always re-runs on a
  new `setAvatarPhoto` call, and there's no "refresh anchors without changing the photo" path.
