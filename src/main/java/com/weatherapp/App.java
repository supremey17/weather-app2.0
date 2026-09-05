package com.weatherapp;

import WeatherAPI.WeatherAPI;
import javafx.application.Application;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import WeatherAPI.CityNotFoundException;

import java.io.IOException;

public class App extends Application {
    //these are now fields so it's easier to recall
    private final WeatherAPI weatherAPI = new WeatherAPI();
    private final PreferencesService prefsService = new PreferencesService();

    @Override
    public void start(Stage stage) throws IOException, InterruptedException {
        PreferencesService prefsService = new PreferencesService();
        String initialCity = prefsService.getSavedCity();

        //initialCity so whenever it starts up there's no buffer from last use.
        if (initialCity == null){
            LocationService locationService = new LocationService();
            initialCity = locationService.detectCity();
            prefsService.saveCity(initialCity);
        }
        //Search bar to find cities
        TextField cityInput = new TextField(initialCity);
        Button searchButton = new Button("Search");
        Label resultLabel = new Label();

        HBox searchRow = new HBox(10, cityInput,searchButton);
        searchRow.setAlignment(Pos.CENTER);

        VBox root = new VBox(15, searchRow, resultLabel);
        root.setAlignment(Pos.CENTER);
        root.setPadding(new javafx.geometry.Insets(20));

        searchButton.setOnAction(event -> {
            String city = cityInput.getText();
            try {
                WeatherResponse weather = weatherAPI.findByCity(city);
                resultLabel.setText(weather.name() + ": " + weather.main().temp() + "°F, "
                        + weather.weather().getFirst().description());
                prefsService.saveCity(city);
            } catch (CityNotFoundException e) {
                resultLabel.setText("Yikes \"" + city + "\". was speeled wrong. First day on earth? ");
            } catch (IOException e) {
                resultLabel.setText("They're taking the wifi:(");
            } catch (InterruptedException e) {
                resultLabel.setText("Please try again i need to pay bills!");
            }
        });
        //trigger an initial search so the app shows data on launch not a blank screen
        searchButton.fire();

        stage.setScene(new Scene(root, 500, 400));
        stage.setTitle("Weather App");
        stage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}