package com.weatherapp;

import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.StackPane;

import java.util.List;
import java.net.URL;

public class AvatarView {
    public static StackPane build(List<String> layers) {
        StackPane pane = new StackPane();
        pane.setPrefSize(150, 220);

        addLayer(pane, "casual");

        // order matters: later layers draw on top
        for (String name : List.of("hot", "coat", "boots", "sunglasses", "Jacket")) {
            if (layers.contains(name)) {
                addLayer(pane, name);
            }
        }

        return pane;
    }

    // skips layers that don't have a PNG yet instead of crashing
    private static void addLayer(StackPane pane, String name){
        URL url = AvatarView.class.getResource("/images/" + name + ".png");
        if (url == null) {
            return;
        }
        Image image = new Image(url.toExternalForm());
        ImageView imageView = new ImageView(image);
        imageView.setFitHeight(220);
        imageView.setFitWidth(150);
        imageView.setPreserveRatio(false);
        pane.getChildren().add(imageView);
    }
}