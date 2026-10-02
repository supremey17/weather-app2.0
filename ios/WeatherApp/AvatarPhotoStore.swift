import Foundation

/// Persists the processed avatar locally. The image is never uploaded and is excluded from backup.
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
}
