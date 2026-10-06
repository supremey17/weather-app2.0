import CoreGraphics
import Foundation

/// Persists the processed avatar locally. The image is never uploaded and is excluded from backup.
struct AvatarPhotoStore {
    private let fileURL: URL
    private let anchorsURL: URL

    init(directory: URL = AvatarPhotoStore.defaultDirectory()) {
        self.fileURL = directory.appendingPathComponent("avatar.png")
        self.anchorsURL = directory.appendingPathComponent("avatar-face-anchors.json")
    }

    static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    func save(_ data: Data) throws {
        try data.write(to: fileURL, options: .atomic)
        // Complete protection is supported on device. Test containers and some development
        // volumes do not support that attribute, so preserve the successful local save there.
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: fileURL.path
        )
        var url = fileURL
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Loads the face anchors saved alongside the avatar image, if any. `nil` covers "never
    /// detected a face", "no file yet", and "corrupt JSON" alike — callers already treat a nil
    /// `FaceAnchors` as "render no accessories", so there's no need to distinguish those cases.
    func loadAnchors() -> FaceAnchors? {
        guard let data = try? Data(contentsOf: anchorsURL) else { return nil }
        return try? JSONDecoder().decode(FaceAnchors.self, from: data)
    }

    /// The anchors are tiny and derived (four points, no pixel data), so this skips the
    /// backup-exclusion/protection-attribute dance `save` does for the actual photo.
    func saveAnchors(_ anchors: FaceAnchors) throws {
        let data = try JSONEncoder().encode(anchors)
        try data.write(to: anchorsURL, options: .atomic)
    }

    func deleteAnchors() {
        try? FileManager.default.removeItem(at: anchorsURL)
    }
}
