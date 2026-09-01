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
        Label label = new Label("Weather Application — coming soon");
        StackPane root = new StackPane(label);
        stage.setScene(new Scene(root, 500, 400));
        stage.setTitle("Weather App");
        WeatherAPI weatherAPI = new WeatherAPI();
        System.out.print(weatherAPI.findAll());
        stage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}