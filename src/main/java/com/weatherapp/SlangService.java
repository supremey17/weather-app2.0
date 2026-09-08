package com.weatherapp;

import java.util.List;
import java.util.Map;
import java.util.Random;

public class SlangService {
    private final Random random = new Random();

    private final Map<String, List<String>> phrasesByCondition = Map.of(
            "Clear", List.of("Sunglasses needed :p", "Woah real change of scenery", "touch grass weather fr"),
            "Rain", List.of("it's giving cry baby weather", "the sky said not today", "rainy era, no thoughts"),
            "Snow", List.of("it's giving winter arc", "snow day vibes", "bestie it's freezing fr"),
            "Clouds", List.of("it's giving meh", "kinda mid outside ngl", "gray skies, gray mood"),
            "Thunderstorm", List.of("the sky is not okay rn", "thunder said get inside", "storm era activated")
    );

    private final List<String> defaultPhrases = List.of(
            "weather's weather ig", "it's outside, that's all i know", "no notes"
    );

    public String getPhrase(String condition) {
        List<String> options = phrasesByCondition.getOrDefault(condition, defaultPhrases);
        return options.get(random.nextInt(options.size()));
    }
}