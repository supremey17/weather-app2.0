package com.weatherapp;

import java.util.prefs.Preferences;

public class PreferencesService {
    private final Preferences prefs;
    private static final String CITY_KEY = "last_city";

    public PreferencesService() {
        prefs = Preferences.userNodeForPackage(this.getClass());
    }

    public String getSavedCity() {
        return prefs.get(CITY_KEY, null);
    }

    public void saveCity(String city){
        prefs.put(CITY_KEY, city);
    }
}
