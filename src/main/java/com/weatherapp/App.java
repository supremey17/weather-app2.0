package com.weatherapp;

import WeatherAPI.WeatherAPI;
import WeatherAPI.CityNotFoundException;
import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

import java.io.IOException;

public class App extends Application {
    private final WeatherAPI weatherAPI = new WeatherAPI();
    private final PreferencesService prefsService = new PreferencesService();

    // Tracks the current unit system; imperial = °F, metric = °C
    private String units = "imperial";

    @Override
    public void start(Stage stage) throws IOException, InterruptedException {
        String initialCity = prefsService.getSavedCity();

        if (initialCity == null) {
            LocationService locationService = new LocationService();
            initialCity = locationService.detectCity();
            prefsService.saveCity(initialCity);
        }

        TextField cityInput = new TextField(initialCity);
        Button searchButton = new Button("Search");
        Button unitToggle = new Button("°F");
        Label resultLabel = new Label();

        HBox searchRow = new HBox(10, cityInput, searchButton, unitToggle);
        searchRow.setAlignment(Pos.CENTER);

        VBox root = new VBox(15, searchRow, resultLabel);
        root.setAlignment(Pos.CENTER);
        root.setPadding(new Insets(20));

        searchButton.setOnAction(event -> {
            String city = cityInput.getText();
            runSearch(city, resultLabel);
        });

        unitToggle.setOnAction(event -> {
            if (units.equals("imperial")) {
                units = "metric";
                unitToggle.setText("°C");
            } else {
                units = "imperial";
                unitToggle.setText("°F");
            }
            // Re-run the search for whatever city is currently shown, in the new units
            runSearch(cityInput.getText(), resultLabel);
        });

        searchButton.fire();

        stage.setScene(new Scene(root, 500, 400));
        stage.setTitle("Weather App");
        stage.show();
    }

    private void runSearch(String city, Label resultLabel) {
        try {
            WeatherResponse weather = weatherAPI.findByCity(city, units);
            String unitSymbol = units.equals("imperial") ? "°F" : "°C";
            resultLabel.setText(weather.name() + ": " + weather.main().temp() + unitSymbol + ", "
                    + weather.weather().getFirst().description());
            prefsService.saveCity(city);
        } catch (CityNotFoundException e) {
            resultLabel.setText("Yikes \"" + city + "\". was speeled wrong. First day on earth? ");
        } catch (IOException e) {
            resultLabel.setText("They're taking the wifi:(");
        } catch (InterruptedException e) {
            resultLabel.setText("Please try again i need to pay bills!");
        }
    }

    public static void main(String[] args) {
        launch(args);
    }
}