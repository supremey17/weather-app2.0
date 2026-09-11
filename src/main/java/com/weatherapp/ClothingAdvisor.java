package com.weatherapp;

import java.util.List;
import java.util.ArrayList;

public class ClothingAdvisor {
    public String getAdvice(double tempF, int humidity, String condition, double uvi){
        StringBuilder advice = new StringBuilder();

        if(tempF < 40) {
            advice.append("ITS MAD BRICK");
        } else if(tempF < 60){
            advice.append("Grab a light jacket it'll be warm ");
        } else if (tempF < 80){
            advice.append("Very Hot ");
        }

        if (humidity > 70){
            advice.append("Wear some Linen or lightweight cotton to keep cool");
        }
        if (condition.equalsIgnoreCase("Rain") || condition.equalsIgnoreCase("Drizzle")) {
            advice.append("Raincoat ");
        } else if (condition.equalsIgnoreCase("Snow")) {
            advice.append("Wear boots and a winter coat. ");
        }

        if (uvi >= 6) {
            advice.append("High UV, If Sunscreen:Wear light-toned clothing, If no Sunscreen: wear dark colors");
        } else if (uvi >= 3) {
            advice.append("Moderate UV, sunscreen recommended. you do you i guess.   ");
        }

        return advice.isEmpty() ? "Dress comfortably for the day." : advice.toString().trim();
        }
        public List<String> getOutfitLayers(double tempF, int humidity, String condition, double uvi){
            List<String> layers = new ArrayList<>();

            if (tempF < 60) {
                layers.add("coat");
            }

            if (condition.equalsIgnoreCase("Rain") || condition.equalsIgnoreCase("Drizzle")) {
                layers.add("umbrella");
            } else if (condition.equalsIgnoreCase("Snow")) {
                layers.add("winter coat");
                layers.add("boots");
            }

            if (uvi >= 6) {
                layers.add("sunscreen");
            }
            return layers;
        }
    }

