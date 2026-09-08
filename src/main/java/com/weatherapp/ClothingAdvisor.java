package com.weatherapp;

public class ClothingAdvisor {
    public String getAdvice(double tempF, int humidity, String condition, double uvi){
        StringBuilder advice = new StringBuilder();

        if(tempF < 40) {
            advice.append("Gotta larp as a nyc hooligan bring a puffer Jacket");
        } else if(tempF < 60){
            advice.append("Grab a light jacket it'll be warm ");
        } else if(tempF < 80){
            advice.append("It's HOT bring something lighter than my hopes");
        }
        if(tempC < 40) {
            advice.append("Gotta larp as a nyc hooligan bring a puffer Jacket");
        } else if(tempC < 60){
            advice.append("Grab a light jacket it'll be warm ");
        } else if(tempC < 80){
            advice.append("It's HOT bring something lighter than my hopes");
        }

        if (humidity > 70){
            advice.append("");
        }
        if (condition.equalsIgnoreCase("Rain") || condition.equalsIgnoreCase("Drizzle")) {
            advice.append("Bring an umbrella. ");
        } else if (condition.equalsIgnoreCase("Snow")) {
            advice.append("Wear boots and a waterproof coat. ");
        }

        if (uvi >= 6) {
            advice.append("High UV, wear sunscreen. Wear Light Colored Clothes, NO BLACK YOU'LL BURN ");
        } else if (uvi >= 3) {
            advice.append("Moderate UV, sunscreen recommended. you do you i guess.   ");
        }

        return advice.isEmpty() ? "Dress comfortably for the day." : advice.toString().trim();
    }

    }
}
