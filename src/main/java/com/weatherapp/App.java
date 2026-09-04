package com.weatherapp;

import WeatherAPI.WeatherAPI;
import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

import java.io.IOException;

public class App extends Application {
    @Override
    public void start(Stage stage) throws IOException, InterruptedException {
        PreferencesService prefsService = new PreferencesService();
        String city = prefsService.getSavedCity();

        if (city == null){
            LocationService locationService = new LocationService();
            city = locationService.detectCity();
            prefsService.saveCity(city);
        }

        WeatherAPI weatherAPI = new WeatherAPI();
        WeatherResponse weather = weatherAPI.findByCity(city);

        String display = weather.name() + ": " + weather.main().temp() + "°F, "
                + weather.weather().getFirst().description();

        Label label = new Label(display);
        StackPane root = new StackPane(label);
        stage.setScene(new Scene(root, 500, 400));
        stage.setTitle("Weather App");
        stage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}