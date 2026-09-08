package com.weatherapp;

import java.util.prefs.Preferences;

public class PreferencesService {
    private final Preferences prefs;
    private static final String CITY_KEY = "last_city";
    private static final String HOME_CITY_KEY = "home_city";
    private static final String UNITS_KEY = "default_units";
    private static final String SLANG_KEY = "slang_enabled";
    private static final String ADVICE_KEY = "advice_enabled";


    public PreferencesService() {
        prefs = Preferences.userNodeForPackage(this.getClass());
    }

    public String getSavedCity() {
        return prefs.get(CITY_KEY, null);
    }

    public void saveCity(String city){
        prefs.put(CITY_KEY, city);
    }

    public String getHomeCity() {
        return prefs.get(HOME_CITY_KEY, null);
    }

    public void saveHomeCity(String city){
        prefs.put(HOME_CITY_KEY, city);
    }

    public String getDefaultUnits() {
        return prefs.get(UNITS_KEY, "imperial");
    }

    public void saveDefaultUnits(String units){
        prefs.put(UNITS_KEY, units);
    }

    public boolean isSlangEnabled() {
        return prefs.getBoolean(SLANG_KEY, true);
    }

    public void saveSlangEnabled(boolean enabled){
        prefs.putBoolean(SLANG_KEY, enabled);
    }

    public boolean isAdviceEnabled() {
        return prefs.getBoolean(ADVICE_KEY, true);
    }
    
    public void saveAdviceEnabled(boolean selected) {
        prefs.putBoolean(ADVICE_KEY, selected);
    }
}
