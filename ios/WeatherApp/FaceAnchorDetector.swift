import CoreGraphics
import Vision

/// Normalized (0...1) 2D face landmark positions, origin bottom-left — the same convention as
/// `BodyPoseLandmarks`. These are already resolved into full-image-normalized space (Vision
/// reports landmark points relative to each face's own bounding box; `FaceAnchorDetector` folds
/// that bounding box back in), so callers never need to think about the face rectangle.
struct FaceAnchors: Codable, Equatable {
    let eyesCenter: CGPoint
    let mouthCenter: CGPoint
    let faceTop: CGPoint
    /// The detected face's width, normalized to the image width (same `0...1` space as the
    /// points above). Accessory sizing is expressed as a fraction of this.
    let faceWidth: CGFloat
}

/// Runs Apple's on-device Vision face-landmarks model — no network call, nothing ever leaves the
/// phone. Call this off the main actor (it's synchronous CPU work); the caller is responsible for
/// hopping off the main thread, e.g. via `Task.detached`. Mirrors `BodyPoseDetector`'s shape.
enum FaceAnchorDetector {
    private static let minimumConfidence: Float = 0.3

    /// `nil` if no face (or not enough of one) was detected, or required landmarks are missing —
    /// callers should then skip rendering accessories entirely rather than guessing a position.
    /// If more than one face is in frame, anchors to the largest rather than whichever Vision
    /// happens to list first.
    static func detect(in cgImage: CGImage) -> FaceAnchors? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.max(by: { $0.boundingBox.width < $1.boundingBox.width }),
              observation.confidence >= minimumConfidence,
              let landmarks = observation.landmarks else {
            return nil
        }

        let boundingBox = observation.boundingBox

        // Vision reports landmark points normalized to the face's own bounding box (origin
        // bottom-left, like everything else here); fold that box back in to get a point in the
        // full image's normalized space.
        func imagePoint(_ region: VNFaceLandmarkRegion2D?) -> CGPoint? {
            guard let points = region?.normalizedPoints, !points.isEmpty else { return nil }
            let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            let count = CGFloat(points.count)
            let relative = CGPoint(x: sum.x / count, y: sum.y / count)
            return CGPoint(
                x: boundingBox.origin.x + relative.x * boundingBox.width,
                y: boundingBox.origin.y + relative.y * boundingBox.height
            )
        }

        guard let leftEye = imagePoint(landmarks.leftEye),
              let rightEye = imagePoint(landmarks.rightEye),
              let mouth = imagePoint(landmarks.outerLips) else {
            return nil
        }

        let eyesCenter = CGPoint(x: (leftEye.x + rightEye.x) / 2, y: (leftEye.y + rightEye.y) / 2)
        let faceTop = CGPoint(x: boundingBox.midX, y: boundingBox.maxY)

        return FaceAnchors(eyesCenter: eyesCenter, mouthCenter: mouth, faceTop: faceTop, faceWidth: boundingBox.width)
    }
}

extension FaceAnchors {
    /// Hand-tuned anchors for the static `"casual"` default avatar image. Detection doesn't run
    /// against the silhouette (it's a fixed, known asset, not a user photo), so these values are
    /// eyeballed once against that specific asset's proportions. If `"casual"` is ever redrawn or
    /// re-cropped, these need to be re-tuned, or accessories will drift off the silhouette's face.
    static let silhouetteDefault = FaceAnchors(
        eyesCenter: CGPoint(x: 0.5, y: 0.78),
        mouthCenter: CGPoint(x: 0.5, y: 0.73),
        faceTop: CGPoint(x: 0.5, y: 0.86),
        faceWidth: 0.22
    )
}
