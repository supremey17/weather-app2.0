import CoreGraphics
import Testing
@testable import WeatherApp

struct PoseGuidanceTests {

    /// Arms down at the sides, shoulders level and well separated: a "good" reference pose.
    private static let goodPose = BodyPoseLandmarks(
        leftShoulder: CGPoint(x: 0.4, y: 0.8),
        rightShoulder: CGPoint(x: 0.6, y: 0.8),
        leftWrist: CGPoint(x: 0.42, y: 0.45),
        rightWrist: CGPoint(x: 0.58, y: 0.45),
        leftHip: CGPoint(x: 0.42, y: 0.5),
        rightHip: CGPoint(x: 0.58, y: 0.5)
    )

    @Test func goodPoseHasNoSuggestion() {
        #expect(PoseGuidance.evaluate(Self.goodPose) == nil)
    }

    @Test func raisedArmsSuggestsArmsDown() {
        var pose = Self.goodPose
        pose = BodyPoseLandmarks(
            leftShoulder: pose.leftShoulder, rightShoulder: pose.rightShoulder,
            leftWrist: CGPoint(x: 0.42, y: 0.85), rightWrist: CGPoint(x: 0.58, y: 0.85), // raised above shoulders
            leftHip: pose.leftHip, rightHip: pose.rightHip
        )
        let suggestion = PoseGuidance.evaluate(pose)
        #expect(suggestion?.contains("arms down") == true)
    }

    @Test func flaredArmsSuggestsArmsDown() {
        var pose = Self.goodPose
        pose = BodyPoseLandmarks(
            leftShoulder: pose.leftShoulder, rightShoulder: pose.rightShoulder,
            leftWrist: CGPoint(x: 0.1, y: 0.45), rightWrist: CGPoint(x: 0.9, y: 0.45), // flared way out to the sides
            leftHip: pose.leftHip, rightHip: pose.rightHip
        )
        let suggestion = PoseGuidance.evaluate(pose)
        #expect(suggestion?.contains("arms down") == true)
    }

    @Test func profilePoseSuggestsFacingStraight() {
        var pose = Self.goodPose
        pose = BodyPoseLandmarks(
            leftShoulder: CGPoint(x: 0.49, y: 0.8), rightShoulder: CGPoint(x: 0.51, y: 0.8), // shoulders nearly overlap in x: a side profile
            leftWrist: pose.leftWrist, rightWrist: pose.rightWrist,
            leftHip: pose.leftHip, rightHip: pose.rightHip
        )
        let suggestion = PoseGuidance.evaluate(pose)
        #expect(suggestion?.contains("straight-on") == true)
    }

    @Test func tiltedShouldersSuggestsFacingStraight() {
        var pose = Self.goodPose
        pose = BodyPoseLandmarks(
            leftShoulder: CGPoint(x: 0.4, y: 0.7), rightShoulder: CGPoint(x: 0.6, y: 0.9), // one shoulder much higher
            leftWrist: pose.leftWrist, rightWrist: pose.rightWrist,
            leftHip: pose.leftHip, rightHip: pose.rightHip
        )
        let suggestion = PoseGuidance.evaluate(pose)
        #expect(suggestion?.contains("straight-on") == true)
    }

    @Test func bothIssuesAreMentionedTogether() {
        let pose = BodyPoseLandmarks(
            leftShoulder: CGPoint(x: 0.49, y: 0.7), rightShoulder: CGPoint(x: 0.51, y: 0.9),
            leftWrist: CGPoint(x: 0.42, y: 0.85), rightWrist: CGPoint(x: 0.58, y: 0.85),
            leftHip: CGPoint(x: 0.42, y: 0.5), rightHip: CGPoint(x: 0.58, y: 0.5)
        )
        let suggestion = PoseGuidance.evaluate(pose)
        #expect(suggestion?.contains("straight-on") == true)
        #expect(suggestion?.contains("arms down") == true)
    }

    @Test func suggestionNeverClaimsToBlockUsingThePhoto() {
        let pose = BodyPoseLandmarks(
            leftShoulder: CGPoint(x: 0.49, y: 0.7), rightShoulder: CGPoint(x: 0.51, y: 0.9),
            leftWrist: CGPoint(x: 0.42, y: 0.85), rightWrist: CGPoint(x: 0.58, y: 0.85),
            leftHip: CGPoint(x: 0.42, y: 0.5), rightHip: CGPoint(x: 0.58, y: 0.5)
        )
        // Regression guard: the pose check must always read as a suggestion, never a requirement.
        #expect(PoseGuidance.evaluate(pose)?.contains("this photo works too") == true)
    }
}
