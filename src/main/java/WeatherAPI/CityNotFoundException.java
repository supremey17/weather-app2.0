package WeatherAPI;

public class CityNotFoundException extends Exception {
    public CityNotFoundException(String city) {
        super("Uh oh the big Nen found \"" + city + "\"");
    }
}
