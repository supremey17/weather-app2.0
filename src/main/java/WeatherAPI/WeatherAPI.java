package WeatherAPI;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.weatherapp.Weather;

import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import java.io.IOException;
import java.util.List;


public class WeatherAPI {

        private final String BASE_URL = "https://api.openweathermap.org/data/2.5/weather?q=" + "Hamlin" + "&appid=" + "5810ae2ed1e896ae321dcdcee9162539";
        private final HttpClient client;


        public WeatherAPI() {
            client = HttpClient.newHttpClient();
            ObjectMapper objectMapper = new ObjectMapper();
        }

        public List<Weather> findAll() throws IOException, InterruptedException {
            String apiKey = "5810ae2ed1e896ae321dcdcee9162539";
            String city = "Hamlin";
            String url = "api.openweathermap.org" + city + "&appid=" + apiKey;

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(BASE_URL))
                    .GET()
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            return response.body();
        }
}
