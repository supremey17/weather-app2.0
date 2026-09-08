package com.weatherapp;

public class ClothingAdvisor {
    public String getAdvice(double tempF, int humidity, String condition, double uvi){
        StringBuilder advice = new StringBuilder();

        if(tempF < 40) {
            advice.append("ITS MAD BRICK");
        } else if(tempF < 60){
            advice.append("Grab a light jacket it'll be warm ");
        } else if(tempF < 80){
            advice.append("Cook my kid in the car weather");
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
    }
