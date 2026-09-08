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
    private final SlangService slangService = new SlangService();
    private final WeatherAPI weatherAPI = new WeatherAPI();
    private final PreferencesService prefsService = new PreferencesService();
    private String units; // no longer hardcoded to "imperial"

    @Override
    public void start(Stage stage) throws IOException, InterruptedException {
        units = prefsService.getDefaultUnits();

        String initialCity = prefsService.getHomeCity();
        if (initialCity == null || initialCity.isBlank()) {
            initialCity = prefsService.getSavedCity();
        }
        if (initialCity == null) {
            LocationService locationService = new LocationService();
            initialCity = locationService.detectCity();
            prefsService.saveCity(initialCity);
        }

        TextField cityInput = new TextField(initialCity);
        Button searchButton = new Button("Search");
        Button unitToggle = new Button(units.equals("metric") ? "°C" : "°F");
        Button settingsButton = new Button("⚙");
        Label resultLabel = new Label();
        resultLabel.setWrapText(true);
        resultLabel.setMaxWidth(450);

        HBox searchRow = new HBox(10, cityInput, searchButton, unitToggle, settingsButton);
        searchRow.setAlignment(Pos.CENTER);

        settingsButton.setOnAction(event -> {
            SettingsWindow.show(prefsService, () -> {
                units = prefsService.getDefaultUnits();
                unitToggle.setText(units.equals("metric") ? "°C" : "°F");
                runSearch(cityInput.getText(), resultLabel);
            });
        });

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

    private final ClothingAdvisor clothingAdvisor = new ClothingAdvisor();

    private void runSearch(String city, Label resultLabel) {
        try {
            WeatherResponse weather = weatherAPI.findByCity(city, units);
            double uvi = weatherAPI.getUvIndex(weather.coord().lat(), weather.coord().lon());

            String unitSymbol = units.equals("imperial") ? "°F" : "°C";
            String condition = weather.weather().getFirst().main();
            String slang = slangService.getPhrase(condition);
            String advice = clothingAdvisor.getAdvice(weather.main().temp(), weather.main().humidity(), condition, uvi);

            resultLabel.setText(weather.name() + ": " + weather.main().temp() + unitSymbol + ", "
                    + weather.weather().getFirst().description() + " — " + slang
                    + "\n" + advice);
            prefsService.saveCity(city);
        } catch (CityNotFoundException e) {
            resultLabel.setText("Yikes \"" + city + "\". was spelled wrong. First day on earth? ");
        } catch (IOException e) {
            //System.out.println("Debug: " + e.getMessage()); //I use this whenever I don't know the error in the api or code.
            resultLabel.setText("TS not working twin");
        } catch (InterruptedException e) {
            resultLabel.setText("Oh hit a snag.");
        }
    }

    public static void main(String[] args) {
        launch(args);
    }
}