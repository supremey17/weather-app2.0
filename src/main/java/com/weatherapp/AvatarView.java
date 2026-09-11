package com.weatherapp;

import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.StackPane;

import java.util.List;

public class AvatarView {

    public static StackPane build(List<String> layers) {
        StackPane pane = new StackPane();
        pane.setPrefSize(150, 220);

        pane.getChildren().add(loadLayer("base_body"));

        if (layers.contains("coat")) {
            pane.getChildren().add(loadLayer("coat"));
        }
        if (layers.contains("boots")) {
            pane.getChildren().add(loadLayer("boots"));
        }
        if (layers.contains("sunglasses")) {
            pane.getChildren().add(loadLayer("sunglasses"));
        }
        if (layers.contains("umbrella")) {
            pane.getChildren().add(loadLayer("umbrella"));
        }

        return pane;
    }

    private static ImageView loadLayer(String name) {
        Image image = new Image(AvatarView.class.getResourceAsStream("/images/" + name + ".png"));
        return new ImageView(image);
    }
}