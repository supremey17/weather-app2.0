package com.weatherapp;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

public class App extends Application {
    @Override
    public void start(Stage stage) {
        Label label = new Label("Weather App — coming soon");
        StackPane root = new StackPane(label);
        stage.setScene(new Scene(root, 400, 300));
        stage.setTitle("Weather App");
        stage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
