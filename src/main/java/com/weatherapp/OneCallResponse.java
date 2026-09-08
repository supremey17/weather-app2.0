package com.weatherapp;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;


@JsonIgnoreProperties(ignoreUnknown = true)
public record OneCallResponse(List<CurrentBlock> data) {}
