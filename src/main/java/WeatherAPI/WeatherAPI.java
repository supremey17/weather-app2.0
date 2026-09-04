package WeatherAPI;

//imports
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weatherapp.WeatherResponse;

import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import java.io.IOException;

public class WeatherAPI {
    //This is written so it is only called once in the beginning.
    private final String apiKey;
    //manages connection pooling to keeping network connections warm so future requests are faster).
    private final HttpClient client;
    //from jackson to explicitly expensive to create and cheap to reuse
    private final ObjectMapper objectMapper;

    public WeatherAPI() {
        client = HttpClient.newHttpClient();
        objectMapper = new ObjectMapper();

        //this checks the api at startup and if it fails it'll show the problem
        //System.getenv right amount of complexity, also works great with java
        apiKey = System.getenv("OWM_API_KEY");
        if (apiKey == null || apiKey.isBlank()){
            throw new IllegalStateException("OWM_API_KEY environment variable has not been set aka ts not working:/");
        }
    }

    public WeatherResponse findByCity(String city) throws IOException, InterruptedException {
       String url ="https://api.openweathermap.org/data/2.5/weather?q="
               + city + "&units=imperial&appid" + apiKey;


        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        return objectMapper.readValue(response.body(), WeatherResponse.class);
    }
}