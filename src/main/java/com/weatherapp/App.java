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
        WeatherAPI weatherAPI = new WeatherAPI();
        WeatherResponse weather = weatherAPI.findAll();

        String display = weather.name() + ": " + weather.main().temp() + "°F, "
                + weather.weather().get(0).description();

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