package com.weatherapp;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record WeatherResponse(
        String name,
        List<WeatherInfo> weather,
        MainInfo main
) {}