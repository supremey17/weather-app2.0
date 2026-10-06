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
}
