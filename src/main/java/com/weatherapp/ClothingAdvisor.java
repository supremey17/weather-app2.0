package com.weatherapp;

import java.util.List;
import java.util.ArrayList;

public class ClothingAdvisor {
    public List<String> getAdvice(double tempF, int humidity, String condition, double uvi){
        List<String> advice = new ArrayList<>();

        if(tempF < 40) {
            advice.add("ITS MAD BRICK");
        } else if(tempF < 60){
            advice.add("Grab a light jacket it'll be warm");
        } else if (tempF < 80){
            advice.add("Very Hot");
        }

        if (humidity > 70){
            advice.add("Wear some Linen or lightweight cotton to keep cool");
        }
        if (condition.equalsIgnoreCase("Rain") || condition.equalsIgnoreCase("Drizzle")) {
            advice.add("tinkle: bring raincoat");
        } else if (condition.equalsIgnoreCase("Snow")) {
            advice.add("Snow lingering, Wear boots and a winter coat.");
        }

        if (uvi >= 6) {
            advice.add("High UV, If Sunscreen's applied: wear light-toned clothing, If no Sunscreen's applied: wear dark colors");
        } else if (uvi >= 3) {
            advice.add("Moderate UV, sunscreen recommended. you do you i guess.");
        }

        if (advice.isEmpty()) {
            advice.add("Dress comfortably for the day.");
        }
        return advice;
        }
        public List<String> getOutfitLayers(double tempF, int humidity, String condition, double uvi){
            List<String> layers = new ArrayList<>();

            if (tempF > 80){
                layers.add("hot");
            }

            if (tempF < 60) {
                layers.add("coat");
            }

            if (condition.equalsIgnoreCase("Rain") || condition.equalsIgnoreCase("Drizzle")) {
                layers.add("Jacket");
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

