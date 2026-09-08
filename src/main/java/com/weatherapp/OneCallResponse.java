package com.weatherapp;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
@JsonIgnoreProperties(ignoreUnknown = true)
public record OneCallResponse(CurrentBlock curreent) {}
