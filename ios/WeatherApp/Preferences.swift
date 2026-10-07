import Foundation

/// Port of PreferencesService.java, backed by UserDefaults instead of java.util.prefs.
/// Key names are kept the same as the Java app.
struct Preferences {
    private let defaults: UserDefaults

    private static let cityKey = "last_city"
    private static let homeCityKey = "home_city"
    private static let unitsKey = "default_units"
    private static let savedCitiesKey = "saved_cities"
    private static let adviceKey = "advice_enabled"
    private static let avatarKey = "avatar_enabled"
    private static let accessoriesKey = "accessories_enabled"
    private static let selectedAccessoryIDsKey = "selected_accessory_ids"
    private static let backgroundKey = "selected_background"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var savedCities: [String] {
        defaults.stringArray(forKey: Self.savedCitiesKey) ?? []
    }

    func addSavedCity(_ city: String) {
        var cities = savedCities
        if !cities.contains(city) {
            cities.append(city)
            defaults.set(cities, forKey: Self.savedCitiesKey)
        }
    }

    func removeSavedCity(_ city: String) {
        defaults.set(savedCities.filter { $0 != city }, forKey: Self.savedCitiesKey)
    }

    var lastCity: String? {
        get { defaults.string(forKey: Self.cityKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.cityKey) }
    }

    var homeCity: String? {
        get { defaults.string(forKey: Self.homeCityKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.homeCityKey) }
    }

    var defaultUnits: Units {
        get { Units(rawValue: defaults.string(forKey: Self.unitsKey) ?? "") ?? .imperial }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.unitsKey) }
    }

    var isAdviceEnabled: Bool {
        get { defaults.object(forKey: Self.adviceKey) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: Self.adviceKey) }
    }

    var isAvatarEnabled: Bool {
        get { defaults.object(forKey: Self.avatarKey) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: Self.avatarKey) }
    }

    /// Off by default: avatar accessories (hat/glasses/cigarette) are a scaffold with no settings
    /// UI yet, so this flag exists for the pipeline to read without changing anyone's experience.
    var isAccessoriesEnabled: Bool {
        get { defaults.object(forKey: Self.accessoriesKey) as? Bool ?? false }
        nonmutating set { defaults.set(newValue, forKey: Self.accessoriesKey) }
    }

    /// The selected accessory id for each slot, if any. Backed by a `[String: String]` dictionary
    /// in `UserDefaults` (keyed by `AccessorySlot.rawValue`, since `UserDefaults` can't store a
    /// `[AccessorySlot: String]` directly).
    ///
    /// Persisted data is untrusted: a corrupted, hand-edited, or stale-after-a-catalog-change
    /// value must be silently dropped, never force-unwrapped or trusted blindly. On read, an
    /// entry only survives if its key is a valid `AccessorySlot.rawValue` AND its value is a
    /// known accessory id that belongs to that same slot in `AvatarAccessory.catalog`.
    var selectedAccessoryIDs: [AccessorySlot: String] {
        get {
            let raw = defaults.dictionary(forKey: Self.selectedAccessoryIDsKey) as? [String: String] ?? [:]
            var result: [AccessorySlot: String] = [:]
            for (slotRaw, accessoryID) in raw {
                guard let slot = AccessorySlot(rawValue: slotRaw),
                      let accessory = AvatarAccessory.accessory(id: accessoryID),
                      accessory.slot == slot else {
                    continue
                }
                result[slot] = accessoryID
            }
            return result
        }
        nonmutating set {
            var raw: [String: String] = [:]
            for (slot, accessoryID) in newValue {
                raw[slot.rawValue] = accessoryID
            }
            defaults.set(raw, forKey: Self.selectedAccessoryIDsKey)
        }
    }

    /// Falls back to `.weather` (the default, weather-reactive look) on any missing, corrupt, or
    /// unrecognized stored value — persisted data is untrusted, same rule as every other enum-backed
    /// preference in this file.
    var selectedBackground: PixelBackground {
        get { PixelBackground(rawValue: defaults.string(forKey: Self.backgroundKey) ?? "") ?? .weather }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.backgroundKey) }
    }
}
