import Foundation
import Testing
@testable import WeatherApp

struct AvatarPhotoStoreTests {

    /// Each test gets its own throwaway directory so tests can't interfere with each other or
    /// touch the real Application Support directory.
    private func makeStore() -> AvatarPhotoStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return AvatarPhotoStore(directory: dir)
    }

    @Test func savedDataRoundTripsThroughLoad() {
        let store = makeStore()
        let data = Data([0x01, 0x02, 0x03])
        try? store.save(data)
        #expect(store.load() == data)
        #expect(store.exists)
    }

    @Test func loadReturnsNilWhenNothingSaved() {
        let store = makeStore()
        #expect(store.load() == nil)
        #expect(!store.exists)
    }

    @Test func deleteRemovesTheSavedPhoto() {
        let store = makeStore()
        try? store.save(Data([0x01]))
        #expect(store.exists)
        store.delete()
        #expect(!store.exists)
        #expect(store.load() == nil)
    }

    @Test func savingTwiceOverwritesThePreviousPhoto() {
        let store = makeStore()
        try? store.save(Data([0x01]))
        try? store.save(Data([0x02, 0x02]))
        #expect(store.load() == Data([0x02, 0x02]))
    }
}
