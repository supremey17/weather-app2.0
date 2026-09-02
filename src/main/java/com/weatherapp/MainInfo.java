package com.weatherapp;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record MainInfo(
        double temp,
        @JsonProperty("feels_like") double feelsLike,
        int humidity
) {}