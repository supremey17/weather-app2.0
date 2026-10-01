import Foundation

/// Saves the user's avatar photo to disk, the image equivalent of what `Preferences` does for
/// small values. Deliberately separate from `UserDefaults`, which only holds strings/bools today.
///
/// This never touches the network: the photo stays on this device. The file is excluded from
/// iCloud backup so a photo of the user's body isn't copied off-device as a side effect.
struct AvatarPhotoStore {
    private let fileURL: URL

    init(directory: URL = AvatarPhotoStore.defaultDirectory()) {
        self.fileURL = directory.appendingPathComponent("avatar.png")
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
        var url = fileURL
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? url.setResourceValues(resourceValues)
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
