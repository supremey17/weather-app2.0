package com.weatherapp;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
//this grabs the values that are needed in json parsing
@JsonIgnoreProperties(ignoreUnknown = true)
public record WeatherInfo(String main, String description, String icon) {}