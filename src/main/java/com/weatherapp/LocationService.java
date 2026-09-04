package com.weatherapp;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.io.IOException;

public class LocationService {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record IpLocation(String city) {}

    private final HttpClient client;
    private final ObjectMapper objectMapper;

    public LocationService() {
        client = HttpClient.newHttpClient();
        objectMapper = new ObjectMapper();
    }

    public String detectCity() throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://ip-api.com/json/"))
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        IpLocation location = objectMapper.readValue(response.body(), IpLocation.class);

        return location.city();

    }
}
