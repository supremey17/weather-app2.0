import Foundation

/// Port of ClothingAdvisor.java, with the fixes from notes/bug-fixes-for-swift.md. Thresholds are in Fahrenheit,
/// so callers convert Celsius first (see WeatherViewModel).
struct ClothingAdvisor {
    func advice(tempF: Double, humidity: Int, condition: String, uvi: Double) -> [String] {
        var advice: [String] = []

        if tempF < 40 {
            advice.append("ITS MAD BRICK")
        } else if tempF < 60 {
            advice.append("Grab a light jacket it's chilly")
        } else if tempF > 80 {
            advice.append("Very Hot")
        }

        if humidity > 70 {
            advice.append("Humid: Wear some Linen or lightweight cotton to keep cool")
        }
        if isRain(condition) {
            advice.append("shower imminent: bring raincoat")
        } else if condition.caseInsensitiveCompare("Snow") == .orderedSame {
            advice.append("Snow lingering, Wear boots and a winter coat.")
        }

        if uvi >= 6 {
            advice.append("High UV, If Sunscreen's applied: wear light-toned clothing, If no Sunscreen's applied: wear dark colors")
        } else if uvi >= 3 {
            advice.append("Moderate UV, sunscreen recommended. you do you i guess.")
        }

        if advice.isEmpty {
            advice.append("Dress comfortably for the day.")
        }
        return advice
    }

    private func isRain(_ condition: String) -> Bool {
        condition.caseInsensitiveCompare("Rain") == .orderedSame
            || condition.caseInsensitiveCompare("Drizzle") == .orderedSame
    }
}
