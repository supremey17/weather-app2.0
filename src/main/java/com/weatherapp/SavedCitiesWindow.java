package com.weatherapp;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ListCell;
import javafx.scene.control.ListView;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

import java.util.function.Consumer;

public class SavedCitiesWindow {

    public static void show(PreferencesService prefsService, Consumer<String> onCitySelected) {
        Stage stage = new Stage();
        stage.setTitle("Saved Cities");

        ObservableList<String> cities = FXCollections.observableArrayList(prefsService.getSavedCities());
        ListView<String> listView = new ListView<>(cities);

        listView.setCellFactory(lv -> new ListCell<>() {
            private final Button selectButton = new Button();
            private final Button deleteButton = new Button("✕");
            private final HBox row = new HBox(10, selectButton, deleteButton);

            {
                selectButton.setOnAction(event -> {
                    String city = getItem();
                    if (city != null) {
                        onCitySelected.accept(city);
                        stage.close();
                    }
                });
                deleteButton.setOnAction(event -> {
                    String city = getItem();
                    if (city != null) {
                        prefsService.removeSavedCity(city);
                        cities.remove(city);
                    }
                });
            }

            @Override
            protected void updateItem(String city, boolean empty) {
                super.updateItem(city, empty);
                if (empty || city == null) {
                    setGraphic(null);
                } else {
                    selectButton.setText(city);
                    setGraphic(row);
                }
            }
        });

        Label title = new Label("Saved Cities");
        VBox root = new VBox(10, title, listView);
        root.setAlignment(Pos.CENTER);
        root.setPadding(new Insets(20));

        stage.setScene(new Scene(root, 300, 350));
        stage.show();
    }
}