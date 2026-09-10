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
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class App extends Application {
    private final SlangService slangService = new SlangService();
    private final WeatherAPI weatherAPI = new WeatherAPI();
    private final PreferencesService prefsService = new PreferencesService();
    private final ClothingAdvisor clothingAdvisor = new ClothingAdvisor();

    private String units;

    // NEW: these need to be fields, not local variables inside start(),
    // because runSearch() (a separate method) needs to update them too.
    private VBox root;
    private Pane avatarPane;

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

        // NEW: build the avatar once at startup with an empty outfit,
        // just so there's something on screen before the first search runs.
        avatarPane = AvatarView.build(new ArrayList<>());

        // NEW: "root" is now assigned to the field (not "var root = ...")
        // and avatarPane is added as one of its children.
        root = new VBox(15, searchRow, avatarPane, resultLabel);
        root.setAlignment(Pos.CENTER);
        root.setPadding(new Insets(20));

        settingsButton.setOnAction(event -> {
            SettingsWindow.show(prefsService, () -> {
                units = prefsService.getDefaultUnits();
                unitToggle.setText(units.equals("metric") ? "°C" : "°F");
                runSearch(cityInput.getText(), resultLabel);
            });
        });

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
            runSearch(cityInput.getText(), resultLabel);
        });

        searchButton.fire();

        stage.setScene(new Scene(root, 500, 500));
        stage.setTitle("Weather App");
        stage.show();
    }

    private void runSearch(String city, Label resultLabel) {
        try {
            WeatherResponse weather = weatherAPI.findByCity(city, units);
            double uvi = weatherAPI.getUvIndex(weather.coord().lat(), weather.coord().lon());

            String unitSymbol = units.equals("imperial") ? "°F" : "°C";
            String condition = weather.weather().getFirst().main();

            String slang = prefsService.isSlangEnabled() ? slangService.getPhrase(condition) : "";

            String display = weather.name() + ": " + weather.main().temp() + unitSymbol + ", "
                    + weather.weather().getFirst().description();

            if (!slang.isEmpty()) {
                display += " — " + slang;
            }

            if (prefsService.isAdviceEnabled()) {
                String advice = clothingAdvisor.getAdvice(weather.main().temp(), weather.main().humidity(), condition, uvi);
                display += "\n" + advice;
            }

            resultLabel.setText(display);
            prefsService.saveCity(city);

            // NEW: get the outfit layers and swap in a freshly built avatar
            List<String> layers = clothingAdvisor.getOutfitLayers(weather.main().temp(), weather.main().humidity(), condition, uvi);
            Pane newAvatar = AvatarView.build(layers);
            root.getChildren().set(root.getChildren().indexOf(avatarPane), newAvatar);
            avatarPane = newAvatar;

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