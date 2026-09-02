package WeatherAPI;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.weatherapp.WeatherResponse;

import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import java.io.IOException;

public class WeatherAPI {

    private final String BASE_URL = "https://api.openweathermap.org/data/2.5/weather?q=Hamlin&units=imperial&appid=5810ae2ed1e896ae321dcdcee9162539";
    private final HttpClient client;
    private final ObjectMapper objectMapper;

    public WeatherAPI() {
        client = HttpClient.newHttpClient();
        objectMapper = new ObjectMapper();
    }

    public WeatherResponse findAll() throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL))
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        return objectMapper.readValue(response.body(), WeatherResponse.class);
    }
}