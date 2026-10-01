import CoreGraphics
import Vision

/// Runs Apple's on-device Vision body-pose model — no network call, nothing ever leaves the
/// phone. Call this off the main actor (it's synchronous CPU work); the caller is responsible
/// for hopping off the main thread, e.g. via `Task.detached`.
enum BodyPoseDetector {
    private static let minimumConfidence: Float = 0.3

    /// `nil` if no person (or not enough of one) was detected — callers should then skip the
    /// pose suggestion entirely rather than guessing.
    static func detectLandmarks(in cgImage: CGImage) -> BodyPoseLandmarks? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first else {
            return nil
        }

        func point(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let recognized = try? observation.recognizedPoint(joint),
                  recognized.confidence >= minimumConfidence else { return nil }
            return recognized.location
        }

        guard let leftShoulder = point(.leftShoulder),
              let rightShoulder = point(.rightShoulder),
              let leftWrist = point(.leftWrist),
              let rightWrist = point(.rightWrist),
              let leftHip = point(.leftHip),
              let rightHip = point(.rightHip) else {
            return nil
        }

        return BodyPoseLandmarks(
            leftShoulder: leftShoulder, rightShoulder: rightShoulder,
            leftWrist: leftWrist, rightWrist: rightWrist,
            leftHip: leftHip, rightHip: rightHip
        )
    }
}
