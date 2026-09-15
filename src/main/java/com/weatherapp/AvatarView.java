package com.weatherapp;

import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.StackPane;

import java.util.List;
import java.util.Objects;

public class AvatarView {
    public static StackPane build(List<String> layers) {
        StackPane pane = new StackPane();
        pane.setPrefSize(150, 220);

        pane.getChildren().add(loadLayer("casual"));

        if (layers.contains("hot")){
            pane.getChildren().addAll(loadLayer("hot"));
        }

        if (layers.contains("coat")) {
            pane.getChildren().add(loadLayer("coat"));
        }
        if (layers.contains("boots")) {
            pane.getChildren().add(loadLayer("boots"));
        }
        if (layers.contains("sunglasses")) {
            pane.getChildren().add(loadLayer("sunglasses"));
        }
        if (layers.contains("Jacket")) {
            pane.getChildren().add(loadLayer("Jacket"));
        }

        return pane;
    }

    private static ImageView loadLayer(String name){
        Image image = new Image(Objects.requireNonNull(
                AvatarView.class.getResource("/images/" + name + ".png")).toExternalForm());
        ImageView imageView = new ImageView(image);
        imageView.setFitHeight(220);
        imageView.setFitWidth(150);
        imageView.setPreserveRatio(false);
        return imageView;
    }
}