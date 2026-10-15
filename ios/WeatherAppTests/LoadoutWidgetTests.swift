import Testing
@testable import WeatherApp

struct LoadoutWidgetTests {
    @Test(arguments: [
        ("ITS MAD BRICK", PixelSpriteKind.thermometer, "JACKET"),
        ("Grab a light jacket it's chilly", .thermometer, "JACKET"),
        ("Very Hot", .sun, "SHADES"),
        ("Humid: Wear some Linen or lightweight cotton to keep cool", .humidity, "LINEN"),
        ("shower imminent: bring raincoat", .rain, "RAINCOAT"),
        ("Snow lingering, Wear boots and a winter coat.", .snow, "BOOTS"),
        ("High UV, If Sunscreen's applied: wear light-toned clothing, If no Sunscreen's applied: wear dark colors", .star, "SUNSCREEN"),
        ("Moderate UV, sunscreen recommended. you do you i guess.", .star, "SUNSCREEN"),
        ("Dress comfortably for the day.", .check, "COMFY"),
    ])
    func everyAdvisorLineMapsToAnItem(advice: String, sprite: PixelSpriteKind, name: String) {
        let item = LoadoutWidget.item(for: advice)
        #expect(item.sprite == sprite)
        #expect(item.name == name)
        #expect(item.detail == advice)
    }

    @Test func matchingIgnoresCase() {
        #expect(LoadoutWidget.item(for: "very hot").name == "SHADES")
        #expect(LoadoutWidget.item(for: "BRING RAINCOAT").name == "RAINCOAT")
    }

    @Test func matchesWholeWordsOnly() {
        #expect(LoadoutWidget.item(for: "Use your brain").name == "COMFY")
        #expect(LoadoutWidget.item(for: "Photo shoot").name == "COMFY")
    }

    @Test func unknownTextFallsBackToComfy() {
        let item = LoadoutWidget.item(for: "Something new")
        #expect(item.sprite == .check)
        #expect(item.name == "COMFY")
    }

    @Test func capsAtSlotCountAndKeepsOrder() {
        let advice = ["Very Hot", "Humid: linen", "shower imminent: bring raincoat", "High UV", "ITS MAD BRICK"]
        let items = LoadoutWidget.items(for: advice)
        #expect(items.count == LoadoutWidget.slotCount)
        #expect(items.map(\.name) == ["SHADES", "LINEN", "RAINCOAT", "SUNSCREEN"])
    }

    @Test func emptyAdviceGivesOneDefaultItem() {
        let items = LoadoutWidget.items(for: [])
        #expect(items.count == 1)
        #expect(items.first?.name == "COMFY")
        #expect(items.first?.sprite == .check)
    }
}
