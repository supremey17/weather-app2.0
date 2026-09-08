package com.weatherapp;

import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Label;
import javafx.scene.control.RadioButton;
import javafx.scene.control.TextField;
import javafx.scene.control.ToggleGroup;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

public class SettingsWindow {

    public static void show(PreferencesService prefsService, Runnable onSaved) {
        Stage settingsStage = new Stage();
        settingsStage.setTitle("Settings");

        Label unitLabel = new Label("Default unit:");
        ToggleGroup unitGroup = new ToggleGroup();
        RadioButton fahrenheit = new RadioButton("Fahrenheit (°F)");
        RadioButton celsius = new RadioButton("Celsius (°C)");
        fahrenheit.setToggleGroup(unitGroup);
        celsius.setToggleGroup(unitGroup);
        if (prefsService.getDefaultUnits().equals("metric")) {
            celsius.setSelected(true);
        } else {
            fahrenheit.setSelected(true);
        }

        Label homeCityLabel = new Label("Home city:");
        TextField homeCityField = new TextField(prefsService.getHomeCity());
        homeCityField.setPromptText("e.g. Rochester");

        CheckBox slangCheckBox = new CheckBox("Enable Gen Z slang phrases");
        slangCheckBox.setSelected(prefsService.isSlangEnabled());

        CheckBox AdviceCheckBox = new CheckBox("Clothing Advisor");
        AdviceCheckBox.setSelected(prefsService.isAdviceEnabled());

        Button saveButton = new Button("Save");
        saveButton.setOnAction(event -> {
            String units = celsius.isSelected() ? "metric" : "imperial";
            prefsService.saveDefaultUnits(units);
            prefsService.saveHomeCity(homeCityField.getText());
            prefsService.saveSlangEnabled(slangCheckBox.isSelected());
            onSaved.run();
            prefsService.saveAdviceEnabled(AdviceCheckBox.isSelected());
            onSaved.run();
            settingsStage.close();
        });

        VBox root = new VBox(15, unitLabel, fahrenheit, celsius, homeCityLabel, homeCityField, slangCheckBox, AdviceCheckBox, saveButton);
        root.setAlignment(Pos.CENTER_LEFT);
        root.setPadding(new Insets(20));

        settingsStage.setScene(new Scene(root, 300, 300));
        settingsStage.show();
    }
}