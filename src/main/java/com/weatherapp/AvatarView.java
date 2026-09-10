package com.weatherapp;

import javafx.scene.layout.Pane;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.scene.shape.Polygon;
import javafx.scene.shape.Circle;

import java.util.List;

public class AvatarView {

    public static Pane build(List<String> layers){
        Pane pane = new Pane();
        pane.setPrefSize(150, 220);

        //Base Body
        Circle head =  new Circle(75, 30, 18);
        head.setFill(Color. PEACHPUFF);

        Rectangle torso = new Rectangle(55, 48, 40, 65);
        torso.setFill(Color. LIGHTGRAY);

        Rectangle leftArm = new Rectangle(35, 52, 15, 55);
        leftArm.setFill(Color. PEACHPUFF);

        Rectangle rightArm = new Rectangle(100, 52, 15, 55);
        rightArm.setFill(Color.PEACHPUFF);

        Rectangle leftLeg = new Rectangle(58, 113, 15, 65);
        leftLeg.setFill(Color.DARKSLATEGRAY);

        Rectangle rightLeg = new Rectangle(77, 113, 15, 65);
        rightLeg.setFill(Color.DARKSLATEGRAY);

        //clothing layers added on top if present in the list
        if (layers.contains("coat")){
            Rectangle coat = new Rectangle(50, 44, 50, 75);
            coat.setFill(Color.SADDLEBROWN);
            pane.getChildren().add(coat);
        }

        if (layers.contains("boots")) {
            Rectangle leftBoot = new Rectangle(56, 168, 19, 12);
            Rectangle rightBoot = new Rectangle(75, 168, 19, 12);
            leftBoot.setFill(Color.BLACK);
            rightBoot.setFill(Color.BLACK);
            pane.getChildren().addAll(leftBoot, rightBoot);
        }

        if (layers.contains("sunglasses")) {
            Rectangle sunglasses = new Rectangle(64, 26, 22, 6);
            sunglasses.setFill(Color.BLACK);
            pane.getChildren().add(sunglasses);
        }

        if (layers.contains("umbrella")) {
            Polygon umbrella = new Polygon(75, 0, 45, 22, 105, 22);
            umbrella.setFill(Color.STEELBLUE);
            pane.getChildren().add(umbrella);
        }

        return pane;
    }
}
