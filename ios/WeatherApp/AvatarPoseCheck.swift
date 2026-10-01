import CoreGraphics

/// Normalized (0...1) 2D positions of the body landmarks `PoseGuidance` cares about, origin
/// bottom-left, matching Vision's coordinate space. Kept separate from Vision types so the
/// guidance logic can be unit tested without running real pose detection.
struct BodyPoseLandmarks {
    let leftShoulder: CGPoint
    let rightShoulder: CGPoint
    let leftWrist: CGPoint
    let rightWrist: CGPoint
    let leftHip: CGPoint
    let rightHip: CGPoint
}

/// Checks whether a photo roughly matches "arms at your sides, facing the camera" — a soft guide,
/// never a hard gate. The app always lets the person use their photo regardless of this result;
/// it only ever suggests a retake. Thresholds are deliberately loose so people the detector reads
/// less confidently (different body shapes, clothing, lighting) aren't singled out by a stricter
/// pass/fail line than the people it reads well.
enum PoseGuidance {
    private static let shoulderTiltTolerance: CGFloat = 0.06
    private static let minShoulderSpread: CGFloat = 0.08
    private static let armsDownTolerance: CGFloat = 0.15
    private static let armsFlaredTolerance: CGFloat = 0.18

    /// `nil` means the pose looks fine; otherwise a friendly, non-blocking suggestion.
    static func evaluate(_ landmarks: BodyPoseLandmarks) -> String? {
        var issues: [String] = []

        let shoulderTilt = abs(landmarks.leftShoulder.y - landmarks.rightShoulder.y)
        let shoulderSpread = abs(landmarks.leftShoulder.x - landmarks.rightShoulder.x)
        if shoulderTilt > shoulderTiltTolerance || shoulderSpread < minShoulderSpread {
            issues.append("facing the camera straight-on")
        }

        let hipMidY = (landmarks.leftHip.y + landmarks.rightHip.y) / 2
        let wristsNearHipHeight = abs(landmarks.leftWrist.y - hipMidY) < armsDownTolerance
            && abs(landmarks.rightWrist.y - hipMidY) < armsDownTolerance
        let wristsNotFlaredOut = abs(landmarks.leftWrist.x - landmarks.leftHip.x) < armsFlaredTolerance
            && abs(landmarks.rightWrist.x - landmarks.rightHip.x) < armsFlaredTolerance
        if !wristsNearHipHeight || !wristsNotFlaredOut {
            issues.append("keeping your arms down at your sides")
        }

        guard !issues.isEmpty else { return nil }
        return "Try \(issues.joined(separator: " and ")) for the best result — but this photo works too."
    }
}
