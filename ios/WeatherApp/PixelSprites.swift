import SwiftUI
import UIKit

/// Every icon concept the app needs, standing in for the SF Symbols that used to be here.
/// Each case maps to one hand-drawn 16x16 bitmap in `PixelSpriteKind.grid` below.
enum PixelSpriteKind: String, CaseIterable {
    // Weather
    case sun
    case moon
    case cloud
    case cloudSun
    case cloudMoon
    case rain
    case snow
    case storm
    case fog

    // UI and metrics
    case search
    case star
    case starFilled
    case map
    case gear
    case location
    case backpack
    case check
    case flag
    case trash
    case close
    case drop
    case wind
    case thermometer
    case thermometerVariable
    case tempRange
    case humidity
    case gauge
    case gaugeAQI
    case eye
    case sunrise
    case sunset
    case clock
    case calendar
    case house
    case sliders
    case refresh

    // Avatar accessories (see `AvatarAccessory.sprite`): full-color game sprites, drawn with the
    // extra palette characters in `color(for:tint:)` rather than the tintable icon palette.
    case accessoryPartyHat
    case accessoryCap
    case accessoryBeanie
    case accessoryRoundGlasses
    case accessoryShades
    case accessoryMonocle
    case accessoryCigarette
    case accessoryPipe
    case accessoryLollipop

    /// Maps the SF Symbol names previously used across the app onto the closest original sprite,
    /// so call sites that stored a symbol string (e.g. `DetailItem.symbol`) keep working.
    init(sfSymbol: String) {
        switch sfSymbol {
        case "sun.max.fill", "sun.max": self = .sun
        case "moon.stars.fill", "moon.stars": self = .moon
        case "cloud.fill", "cloud": self = .cloud
        case "cloud.sun.fill", "cloud.sun": self = .cloudSun
        case "cloud.moon.fill", "cloud.moon": self = .cloudMoon
        case "cloud.rain.fill", "cloud.rain": self = .rain
        case "cloud.bolt.rain.fill", "cloud.bolt.rain": self = .storm
        case "snowflake", "cloud.snow": self = .snow
        case "cloud.fog.fill", "cloud.fog": self = .fog
        case "magnifyingglass": self = .search
        case "star": self = .star
        case "star.fill": self = .starFilled
        case "map": self = .map
        case "gearshape": self = .gear
        case "location": self = .location
        case "backpack": self = .backpack
        case "checkmark.square.fill": self = .check
        case "flag.checkered": self = .flag
        case "trash": self = .trash
        case "drop.fill": self = .drop
        case "wind": self = .wind
        case "thermometer": self = .thermometer
        case "thermometer.variable": self = .thermometerVariable
        case "arrow.up.arrow.down": self = .tempRange
        case "humidity": self = .humidity
        case "gauge": self = .gauge
        case "gauge.with.dots.needle.67percent", "aqi.medium": self = .gaugeAQI
        case "eye": self = .eye
        case "sunrise", "sunrise.fill": self = .sunrise
        case "sunset", "sunset.fill": self = .sunset
        case "clock": self = .clock
        case "calendar": self = .calendar
        case "house": self = .house
        case "slider.horizontal.3": self = .sliders
        case "arrow.triangle.2.circlepath": self = .refresh
        default: self = .cloud
        }
    }
}

extension PixelSpriteKind {
    /// The `Assets.xcassets` imageset this icon's custom artwork lives in, named `icon-<kebab-case>`
    /// (e.g. `icon-cloud-sun`) — scaffolded as empty slots for now. `PixelSprite` prefers this asset
    /// when one exists and falls back to the hand-drawn `grid` below when it's empty, same
    /// named-asset-first pattern as `AvatarView`/`PixelBackgroundLayer`.
    ///
    /// `nil` for the avatar accessories: their hand-drawn grids are the finished art.
    var customAssetName: String? {
        switch self {
        case .sun: "icon-sun"
        case .moon: "icon-moon"
        case .cloud: "icon-cloud"
        case .cloudSun: "icon-cloud-sun"
        case .cloudMoon: "icon-cloud-moon"
        case .rain: "icon-rain"
        case .snow: "icon-snow"
        case .storm: "icon-storm"
        case .fog: "icon-fog"
        case .search: "icon-search"
        case .star: "icon-star"
        case .starFilled: "icon-star-filled"
        case .map: "icon-map"
        case .gear: "icon-gear"
        case .location: "icon-location"
        case .backpack: "icon-backpack"
        case .check: "icon-check"
        case .flag: "icon-flag"
        case .trash: "icon-trash"
        case .close: "icon-close"
        case .drop: "icon-drop"
        case .wind: "icon-wind"
        case .thermometer: "icon-thermometer"
        case .thermometerVariable: "icon-thermometer-variable"
        case .tempRange: "icon-temp-range"
        case .humidity: "icon-humidity"
        case .gauge: "icon-gauge"
        case .gaugeAQI: "icon-gauge-aqi"
        case .eye: "icon-eye"
        case .sunrise: "icon-sunrise"
        case .sunset: "icon-sunset"
        case .clock: "icon-clock"
        case .calendar: "icon-calendar"
        case .house: "icon-house"
        case .sliders: "icon-sliders"
        case .refresh: "icon-refresh"
        case .accessoryPartyHat, .accessoryCap, .accessoryBeanie,
             .accessoryRoundGlasses, .accessoryShades, .accessoryMonocle,
             .accessoryCigarette, .accessoryPipe, .accessoryLollipop:
            nil
        }
    }
}

extension PixelSpriteKind {
    /// 16x16 grid of palette characters: '.' clear, 'K' outline, 'W' white, 'A' accent/tint, 'S' shade,
    /// plus the fixed colors in `color(for:tint:)` that the accessory sprites use.
    /// TODO(workstream A): replace with hand-drawn art per case. All cases currently share one
    /// placeholder blob so the view hierarchy compiles and renders something while that work lands.
    var grid: [String] {
        switch self {
        case .sun:
            return [
                ".......A........",
                ".......A........",
                "..A....A.....A..",
                "...A........A...",
                "....A.KKKK.A....",
                ".....KAAAAK.....",
                "....KAAAAAAK....",
                "....KAAAAAAK....",
                "AAA.KAAAAAAKAAAA",
                "....KAAAAAAK....",
                ".....KAAAAK.....",
                "....A.KKKK.A....",
                "...A....A...A...",
                "..A.....A....A..",
                "........A.......",
                "........A.......",
            ]
        case .moon:
            return [
                "................",
                "..W.............",
                ".WWW............",
                "..W........K....",
                "............K...",
                "............KK..",
                "...........KAK..",
                "...........KAAK.",
                "..........KAAAK.",
                ".........KAAAK..",
                "....K..KKAAAAK..",
                ".....KKAAAAAK...",
                "..W...KKAAKK....",
                "........KK......",
                "................",
                "................",
            ]
        case .cloud:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                ".......KKK......",
                ".....KKAAAKK....",
                "....KAAAAAAAK...",
                "...KAAAAAAAAAK..",
                "..KAAAAAAAAAAAK.",
                "..KAAAAAAAAAAAK.",
                "..KKKKKKKKKKKKK.",
                "................",
                "................",
                "................",
            ]
        case .cloudSun:
            return [
                "............A...",
                "............A...",
                "............KK.A",
                "...........KAAK.",
                "..........KAAAAK",
                "..........KAAAAK",
                "...........KAAK.",
                "......KKK...KK.A",
                "....KKAAAKK.A...",
                "...KAAAAAAAKA...",
                "..KAAAAAAAAAK...",
                ".KAAAAAAAAAAAK..",
                ".KAAAAAAAAAAAK..",
                ".KKKKKKKKKKKKK..",
                "................",
                "................",
            ]
        case .cloudMoon:
            return [
                ".............K..",
                ".............KK.",
                ".............KAK",
                ".............KAK",
                "..........KKKAAK",
                "..........KAAAAK",
                "...........KKKK.",
                "................",
                "......KKK.......",
                "....KKAAAKK.....",
                "...KAAAAAAAK....",
                "..KAAAAAAAAAK...",
                ".KAAAAAAAAAAAK..",
                ".KAAAAAAAAAAAK..",
                ".KKKKKKKKKKKKK..",
                "................",
            ]
        case .rain:
            return [
                "................",
                "................",
                ".......KKK......",
                ".....KKAAAKK....",
                "....KAAAAAAAK...",
                "...KAAAAAAAAAK..",
                "..KAAAAAAAAAAAK.",
                "..KAAAAAAAAAAAK.",
                "..KKKKKKKKKKKKK.",
                "................",
                "....A...A...A...",
                "....A...A...A...",
                "...A...A...A....",
                "..A...A...A.....",
                "..A...A...A.....",
                "................",
            ]
        case .snow:
            return [
                "................",
                "................",
                ".......KKK......",
                ".....KKAAAKK....",
                "....KAAAAAAAK...",
                "...KAAAAAAAAAK..",
                "..KAAAAAAAAAAAK.",
                "..KAAAAAAAAAAAK.",
                "..KKKKKKKKKKKKK.",
                "................",
                "....A......A....",
                "...AAA....AAA...",
                "....A......A....",
                ".......A........",
                "......AAA.......",
                ".......A........",
            ]
        case .storm:
            return [
                "................",
                "................",
                ".......KKK......",
                ".....KKAAAKK....",
                "....KAAAAAAAK...",
                "...KAAAAAAAAAK..",
                "..KAAAAAAAAAAAK.",
                "..KAAAAAAAAAAAK.",
                "..KKKKKKKKKKKKK.",
                ".........KK.....",
                "........KK......",
                ".......KAAK.....",
                "........KK......",
                ".......KK.......",
                "......KK........",
                "................",
            ]
        case .fog:
            return [
                "................",
                "................",
                ".......KKK......",
                ".....KKAAAKK....",
                "....KAAAAAAAK...",
                "...KAAAAAAAAAK..",
                "..KAAAAAAAAAAAK.",
                "..KAAAAAAAAAAAK.",
                "..KKKKKKKKKKKKK.",
                "................",
                "..AAA.AAA.AAAA..",
                "................",
                "...AAAA.AAA.AAA.",
                "................",
                "..AAAA.AAA.AAA..",
                "................",
            ]
        case .search:
            return [
                "................",
                "................",
                ".....AAA........",
                "...AAA.AAA......",
                "...A.....A......",
                "..AA.....AA.....",
                "..A.......A.....",
                "..AA.....AA.....",
                "...A.....A......",
                "...AAA.AAAA.....",
                ".....AAA..AA....",
                "...........AA...",
                "............AA..",
                ".............AA.",
                "..............AA",
                "................",
            ]
        case .star:
            return [
                "................",
                ".......A........",
                ".......A........",
                "......A.A.......",
                "......A.A.......",
                ".AAAAA...AAAAA..",
                "..AA.......AA...",
                "....A.....A.....",
                ".....A...A......",
                "....A.....A.....",
                "....A.AAA.A.....",
                "....AA...AA.....",
                "................",
                "................",
                "................",
                "................",
            ]
        case .starFilled:
            return [
                "................",
                ".......K........",
                ".......K........",
                "......KAK.......",
                "......KAK.......",
                ".KKKKKAAAKKKKK..",
                "..KKAAAAAAAKK...",
                "....KAAAAAK.....",
                ".....KAAAK......",
                "....KAAAAAK.....",
                "....KAKKKAK.....",
                "....KK...KK.....",
                "................",
                "................",
                "................",
                "................",
            ]
        case .map:
            return [
                "................",
                "................",
                ".KKKKKKKKKKKKKK.",
                ".K....K...K...K.",
                ".K....K...K...K.",
                ".K....K...K...K.",
                ".K.A..K...K...K.",
                ".KAAA.K...K...K.",
                ".K.A..K...K...K.",
                ".K....K...K...K.",
                ".K....K...K...K.",
                ".K....K...K...K.",
                ".K....K...K...K.",
                ".KKKKKKKKKKKKKK.",
                "................",
                "................",
            ]
        case .gear:
            return [
                "................",
                "................",
                "......KK........",
                "...KK.KK..KK....",
                "...KK.KAKKAK....",
                ".....KAAAAK.....",
                "....KAAKKAAK....",
                "..KKAAK..KAAK...",
                "..KKAAK..KAAK...",
                "....KAAKKAAK....",
                "...KAKAAAAAK....",
                "...KK.KAAKKK....",
                ".......KK.......",
                "................",
                "................",
                "................",
            ]
        case .location:
            return [
                "................",
                "......KKKK......",
                "....KKAAAAKK....",
                "....KAKKKKAK....",
                "...KAK....KAK...",
                "...KAK....KAK...",
                "...KAK....KAK...",
                "....KKKKKKAAAK..",
                ".......KAAAKK...",
                ".......KAKK.....",
                ".......KK.......",
                ".......K........",
                "................",
                "................",
                "................",
                "................",
            ]
        case .backpack:
            return [
                "................",
                "................",
                "....KKKKKKKK....",
                "....KKAAAAKK....",
                "....KKAAAAKK....",
                "...KKAAAAAAKK...",
                "...KAAAAAAAAK...",
                "...KAAAAAAAAK...",
                "...KAAAAAAAAK...",
                "...KAKKKKKKAK...",
                "...KAKAAAAKAK...",
                "...KAKAAAAKAK...",
                "...KAKKKKKKAK...",
                "...KAAAAAAAAK...",
                "...KKKKKKKKKK...",
                "................",
            ]
        case .check:
            return [
                "................",
                "................",
                "..KKKKKKKKKKKK..",
                "..K..........K..",
                "..K..........K..",
                "..K..........K..",
                "..K.........AK..",
                "..K........AAK..",
                "..K.A....AAA.K..",
                "..K.AAA.AAA..K..",
                "..K..AAAA....K..",
                "..K....A.....K..",
                "..K..........K..",
                "..KKKKKKKKKKKK..",
                "................",
                "................",
            ]
        case .flag:
            return [
                "................",
                "...KKKKKKKKKKK..",
                "...KKKK.KKK.KK..",
                "...KKAA.AAA.AK..",
                "...KKAA.AAA.AK..",
                "...KKKK.KKK.KK..",
                "...KKKK.KKK.KK..",
                "...KKKKKKKKKKK..",
                "...K............",
                "...K............",
                "...K............",
                "...K............",
                "...K............",
                "...K............",
                "...K............",
                "................",
            ]
        case .trash:
            return [
                "................",
                "......KKKK......",
                "...KKKKKKKKKK...",
                "...KKKKKKKKKK...",
                "................",
                "....KKKKKKKK....",
                "....KAKAKAKK....",
                "....KAKAKAKK....",
                "....KAKAKAKK....",
                "....KAKAKAKK....",
                "....KAKAKAKK....",
                "....KAKAKAKK....",
                "....KAKAKAKK....",
                "....KKKKKKKK....",
                "................",
                "................",
            ]
        case .close:
            return [
                "................",
                "................",
                "KK............KK",
                ".KK..........KK.",
                "..KK........KK..",
                "...KK......KK...",
                "....KK....KK....",
                "......KKKK......",
                "......KKKK......",
                "....KK....KK....",
                "...KK......KK...",
                "..KK........KK..",
                ".KK..........KK.",
                "KK............KK",
                "................",
                "................",
            ]
        case .drop:
            return [
                "................",
                "................",
                "................",
                "................",
                "........K.......",
                ".......KK.......",
                ".....KKAAK......",
                "....KAAAAAK.....",
                "....KAAAAAAK....",
                "....KAAAAAAK....",
                "....KAAAAAAK....",
                "....KAAAAAAK....",
                "....KAAAAAAK....",
                ".....KAAAAK.....",
                "......KKKK......",
                "................",
            ]
        case .wind:
            return [
                "................",
                "................",
                "................",
                "..........AA....",
                "..AAAAAAAAAA....",
                "................",
                "................",
                "............AA..",
                ".AAAAAAAAAAAAA..",
                "................",
                "................",
                ".........AA.....",
                "..AAAAAAAAA.....",
                "................",
                "................",
                "................",
            ]
        case .thermometer:
            return [
                "................",
                "................",
                "......KKK.......",
                "......KAK.......",
                "......KAK.......",
                "......KWK.......",
                "......KAK.......",
                "......KAK.......",
                "......KAK.......",
                "......KAK.......",
                ".....KAAAK......",
                ".....KAAAK......",
                ".....KAAAK......",
                ".....KAAAK......",
                ".....KKKKK......",
                "................",
            ]
        case .thermometerVariable:
            return [
                "................",
                "................",
                "....KKK....AAA..",
                "....KAK.....A...",
                "....KAK.....A...",
                "....KAK.....A...",
                "....KAK.....A...",
                "....KAK.........",
                "....KAK.........",
                "....KAK.....A...",
                "....KAK.....A...",
                "...KAAAK....A...",
                "...KAAAK....A...",
                "...KAAAK...AAA..",
                "....KKK.........",
                "................",
            ]
        case .tempRange:
            return [
                "................",
                "................",
                ".......AA.......",
                "......AAAA......",
                ".....AAAAAA.....",
                "....AAAAAAAA....",
                ".......AA.......",
                ".......AA.......",
                ".......AA.......",
                ".......AA.......",
                "....AAAAAAAA....",
                ".....AAAAAA.....",
                "......AAAA......",
                ".......AA.......",
                "................",
                "................",
            ]
        case .humidity:
            return [
                "................",
                "................",
                "....K...........",
                "...KAK..........",
                "..KAAAK.........",
                "..KAAAK.........",
                ".KAAAAAK...K....",
                ".KAAAAAK..KAK...",
                "..KAAAK..KAAAK..",
                "...KKK...KAAAK..",
                "........KAAAAAK.",
                "........KAAAAAK.",
                ".........KAAAK..",
                "..........KKK...",
                "................",
                "................",
            ]
        case .gauge:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                ".....KKKKKK.....",
                "....KKKKKKKK....",
                "...KK......KK...",
                "..KK........AK..",
                "..KK......AAAK..",
                "..K.....AAA..K..",
                ".KK....KKA...KK.",
                ".KKKKKKKKKKKKKK.",
                "................",
                "................",
            ]
        case .gaugeAQI:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                ".....KKKWKK.....",
                "....KKKKWKKK....",
                "...KK...W..KK...",
                "..KK........KK..",
                ".WWK........KWW.",
                "..KWW......WWK..",
                ".KK..........KK.",
                ".KKKKKKKKKKKKKK.",
                "................",
                "................",
            ]
        case .eye:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "......KKKKK.....",
                "...KKKAKKKAKKK..",
                "..KAAAKWKKKAAAK.",
                "..KAAAKKKKKAAAK.",
                "..KAAAKKKKKAAAK.",
                "...KKKAKKKAKKK..",
                "......KKKKK.....",
                "................",
                "................",
                "................",
                "................",
            ]
        case .sunrise:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                ".......A........",
                "....A..A...A....",
                ".....A....A.....",
                ".....KKKKKK.....",
                "..AA.KAAAAK.AA..",
                "....KAAAAAAK....",
                ".KKKKKKKKKKKKKK.",
                "................",
                "................",
                "................",
                "................",
            ]
        case .sunset:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                ".....KKKKKK.....",
                ".....KAAAAK.....",
                "....KAAAAAAK....",
                ".KKKKKKKKKKKKKK.",
                "...A...A...A....",
                "...A...A...A....",
                "...A...A...A....",
                "................",
            ]
        case .clock:
            return [
                "................",
                "................",
                "......AAAAA.....",
                ".....AA...AA....",
                "....A...A...A...",
                "...A....A....A..",
                "..AA....A....AA.",
                "..A.....A.....A.",
                "..A.....AAAAA.A.",
                "..A...........A.",
                "..AA.........AA.",
                "...A.........A..",
                "....A.......A...",
                ".....AA...AA....",
                "......AAAAA.....",
                "................",
            ]
        case .calendar:
            return [
                "................",
                ".....K....K.....",
                ".....K....K.....",
                "..KKKKKKKKKKKK..",
                "..KKKKKKKKKKKK..",
                "..KKKKKKKKKKKK..",
                "..K..........K..",
                "..K.A..A..A.AK..",
                "..K..........K..",
                "..K.A..A..A.AK..",
                "..K..........K..",
                "..K.A..A..A.AK..",
                "..K..........K..",
                "..KKKKKKKKKKKK..",
                "................",
                "................",
            ]
        case .house:
            return [
                "................",
                "................",
                "................",
                ".......AA.......",
                "......AAAA......",
                ".....AAAAAA.....",
                "....AAAAAAAA....",
                "...AAAAAAAAAA...",
                "....KKKKKKKK....",
                "....KAAAAAAK....",
                "....KAAKKAAK....",
                "....KAAKKAAK....",
                "....KAAKKAAK....",
                "....KAAKKAAK....",
                "....KKKKKKKK....",
                "................",
            ]
        case .sliders:
            return [
                "................",
                "................",
                "..AAA...........",
                "..AAAKKKKKKKKK..",
                "..AAA...........",
                "................",
                "................",
                ".........AAA....",
                "..KKKKKKKAAAKK..",
                ".........AAA....",
                "................",
                "................",
                ".....AAA........",
                "..KKKAAAKKKKKK..",
                ".....AAA........",
                "................",
            ]
        case .refresh:
            return [
                "................",
                "................",
                "................",
                "...K.KK...KK....",
                "..KKKAK...KAK...",
                ".KAKAK.....KAK..",
                "..KKK.......KK..",
                "...KK.......KK..",
                "...K.........K..",
                "...KK.......KK..",
                "...KK.......KK..",
                "...KAK.....KAK..",
                "....KAKK.KKAK...",
                ".....KKKKKKK....",
                "................",
                "................",
            ]
        case .accessoryPartyHat:
            return [
                ".......YY.......",
                ".......KK.......",
                "......KMMK......",
                ".....KMYMMK.....",
                "....KMMMMYMK....",
                "...KGWGWGWGWK...",
                "..KKKKKKKKKKKK..",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
            ]
        case .accessoryCap:
            return [
                "................",
                ".....KKKKK......",
                "....KRRRRRK.....",
                "...KRRWRRRRK....",
                "..KRRRRRRRRRK...",
                "..KrrrrrrrrrKKK.",
                "..KKKKKKKKKKRRRK",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
            ]
        case .accessoryBeanie:
            return [
                "................",
                ".......WW.......",
                ".....KKWWKK.....",
                "....KBBBBBBK....",
                "...KBBBBBBBBK...",
                "..KBBBBBBBBBBK..",
                "..KbWbWbWbWbWK..",
                "..KKKKKKKKKKKK..",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
            ]
        case .accessoryRoundGlasses:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "..KKKK....KKKK..",
                ".KCWCCK..KCWCCK.",
                "KKCCCCKKKKCCCCKK",
                ".KCCCCK..KCCCCK.",
                "..KKKK....KKKK..",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
            ]
        case .accessoryShades:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "KKKKKKKKKKKKKKKK",
                ".KDWWDDKKDWWDDK.",
                ".KDDDWDKKDDDWDK.",
                "..KDDDDK.KDDDDK.",
                "...KKKK...KKKK..",
                "................",
                "................",
                "................",
                "................",
                "................",
            ]
        case .accessoryMonocle:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "......ggggg.....",
                ".....gCWCCCg....",
                ".....gCCCCCg....",
                ".....gCCCCCg....",
                ".....gCCCCCg....",
                "......ggggg.....",
                "..........g.....",
                ".........g......",
                "........g.......",
                "................",
            ]
        case .accessoryCigarette:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "...L............",
                "..L.L...........",
                "...L............",
                "..ORWWWWWWWYYY..",
                "..rrLLLLLLLNNN..",
                "................",
                "................",
                "................",
                "................",
                "................",
            ]
        case .accessoryPipe:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "............L...",
                "...........L.L..",
                "..........KKKKK.",
                "..........KOROK.",
                "..KKKKKKKKKNNNK.",
                ".DnnnnnnnnKNNNK.",
                "..KKKKKKKKKnNNK.",
                "...........KKK..",
                "................",
                "................",
            ]
        case .accessoryLollipop:
            return [
                "................",
                "................",
                "................",
                "................",
                "................",
                "......KKKK......",
                ".....KPPPPK.....",
                "....KPWWWRPK....",
                "....KPWRPWPK....",
                "....KPRWWRPK....",
                ".....KPPPPK.....",
                "......KKKK......",
                ".......WL.......",
                ".......WL.......",
                ".......LL.......",
                "................",
            ]
        }
    }

    /// Paints the grid into `context`, one `unit`-sized square per palette character.
    func draw(in context: GraphicsContext, unit: CGFloat, tint: Color? = nil) {
        for (r, row) in grid.enumerated() {
            for (c, char) in row.enumerated() {
                guard let color = color(for: char, tint: tint) else { continue }
                let rect = CGRect(x: CGFloat(c) * unit, y: CGFloat(r) * unit, width: unit, height: unit)
                context.fill(Path(rect), with: .color(color))
            }
        }
    }

    fileprivate func color(for char: Character, tint: Color?) -> Color? {
        switch char {
        case ".": nil
        case "K": .black.opacity(0.85)
        case "W": .white
        case "A": tint ?? .yellow
        case "S": .black.opacity(0.35)
        // Fixed colors for the full-color accessory sprites.
        case "R": Color(red: 0.89, green: 0.22, blue: 0.25)
        case "r": Color(red: 0.58, green: 0.10, blue: 0.16)
        case "O": Color(red: 1.00, green: 0.56, blue: 0.13)
        case "Y": Color(red: 1.00, green: 0.85, blue: 0.24)
        case "g": Color(red: 0.86, green: 0.65, blue: 0.18)
        case "G": Color(red: 0.30, green: 0.78, blue: 0.36)
        case "B": Color(red: 0.22, green: 0.47, blue: 0.92)
        case "b": Color(red: 0.12, green: 0.24, blue: 0.58)
        case "C": Color(red: 0.62, green: 0.88, blue: 1.00).opacity(0.5)
        case "M": Color(red: 0.62, green: 0.34, blue: 0.88)
        case "P": Color(red: 1.00, green: 0.52, blue: 0.76)
        case "N": Color(red: 0.58, green: 0.35, blue: 0.18)
        case "n": Color(red: 0.36, green: 0.20, blue: 0.10)
        case "D": Color(red: 0.13, green: 0.13, blue: 0.18)
        case "L": Color(red: 0.80, green: 0.80, blue: 0.84)
        default: nil
        }
    }
}

/// Renders one `PixelSpriteKind` as crisp, integer-snapped squares instead of a vector glyph.
/// Purely decorative: callers that convey meaning (toolbar buttons, labeled rows) supply their
/// own accessibility label, since the sprite itself is hidden from assistive technologies.
struct PixelSprite: View {
    let kind: PixelSpriteKind
    var scale: CGFloat = 2
    var tint: Color?
    @ScaledMetric(relativeTo: .body) private var baseUnit: CGFloat = 1

    init(_ kind: PixelSpriteKind, scale: CGFloat = 2, tint: Color? = nil) {
        self.kind = kind
        self.scale = scale
        self.tint = tint
    }

    var body: some View {
        let grid = kind.grid
        let rows = grid.count
        let cols = grid.first?.count ?? 0
        let unit = scale * baseUnit
        let size = CGSize(width: CGFloat(cols) * unit, height: CGFloat(rows) * unit)

        Group {
            if let assetName = kind.customAssetName, let uiImage = UIImage(named: assetName) {
                // A custom icon exists for this kind — use it as-is (nearest-neighbor, so it
                // stays crisp like the rest of the pixel art) instead of the hand-drawn grid.
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Canvas { context, _ in
                    kind.draw(in: context, unit: unit, tint: tint)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 12) {
            ForEach(PixelSpriteKind.allCases, id: \.self) { kind in
                PixelSprite(kind, scale: 2)
            }
        }
        .padding()
    }
    .background(Color.black)
}
