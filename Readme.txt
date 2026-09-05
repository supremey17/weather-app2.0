Things to-do:
    1: Design UI
        //not how it looks more like the search bar, error messages.. Ex. No internet or not a real place
        1a) what is needed:
            - Search bar (for location purposes)
            - Settings
                * Unit Metrics
                * Widgets?
                * Perhaps premium features
    2. Clothing recommendations
        2a) take into consideration:
            -UV : recommend either darker colors or lighter
            -Humidity: recommend which fabrics
            -Percepitation: Umbrella, raincoat, boots, snow
    3. Gen z Slang sayings to give the users a chuckle



    I pulled the search logic out into a runSearch(city, resultLabel) helper method, since both the search button and
    the unit toggle now need to trigger the exact same "fetch weather, handle errors" flow — this avoids duplicating
     that whole try/catch block twice

     Clicking the unit toggle re-fetches from the API rather than just relabeling the number — this is necessary because
     imperial vs metric changes the actual numeric value OpenWeatherMap returns, not just the unit label