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

     Add spf sunscreen recommendations for different uv levels.

     API limiter (iOS): every OpenWeatherMap call now goes through RequestGate.swift. It caches results for
     10 min (OWM only updates about that often), merges duplicate requests that are already running, and caps
     each phone at 20 real calls a minute. Hitting the limit (or an HTTP 429) shows a "slow down" message
     instead of the wifi error. Adding a plain delay wouldn't help: it just makes every request slower without
     sending fewer. Since everyone shares one key, a server proxy (e.g. Cloudflare Worker) is the next step
     if the app gets lots of users. See ios/README.md.


     Search autocomplete (iOS): typing a city now shows suggestions (CitySuggester.swift). Saved
     cities that match are shown first with no network call; the rest come from Apple's MapKit
     place search, not OpenWeatherMap, so typing never touches the shared API key or RequestGate's
     limit. Waits for 2+ characters, debounces 250ms, caps at 5 results. Nothing typed is logged
     or saved. Picking a suggestion runs the normal search (still through RequestGate). Added a
     WeatherAppTests target (Swift Testing) covering this and RequestGate; 25 tests passing.
     See ios/README.md.


     Full weather details (iOS): below the avatar/advice there's now a "Right now" / "Air quality" /
     "Next 24 hours" / "5-day forecast" section (WeatherDetails.swift for the logic, WeatherDetailsView.swift
     for the UI). Current-conditions tiles (feels like, pressure, wind, visibility, sunrise/sunset, UV, etc.)
     cost 0 extra API calls -- that data was already in the /weather response, just unused before. Air
     quality and the 5-day forecast are new endpoints, so each search now makes 4 calls instead of 2; they
     run in parallel with UV and go through the same RequestGate cache/rate-limit as everything else, so a
     failed or rate-limited extra just hides that section instead of breaking the search. Sunrise/sunset and
     forecast times use the searched city's own time zone. Weather icons are local SF Symbols, not OWM's
     icon URLs, to avoid a third-party request per icon and work from the cache. Covered by
     WeatherAppTests/WeatherDetailsTests.swift (40 tests passing total). See ios/README.md.


     Avatar photo (iOS): tapping the avatar now opens a page to pick a photo of yourself and use it
     as your avatar instead of the generic silhouette. Removed the old per-weather clothing-layer PNGs
     (coat/Jacket/hot) and ClothingAdvisor.outfitLayers -- the uploaded photo IS the outfit now, so there's
     nothing left to overlay. Everything stays on the device: no network call, no server, no other user ever
     sees it. The photo is downscaled and pixelated (style choice, matching the pixel-art look, NOT a privacy/
     anonymization measure -- pixelation is weak/reversible) and saved via FileManager, excluded from iCloud
     backup. Vision's on-device body-pose detector suggests "arms at your sides, facing the camera" for a
     cleaner result, but it's only ever a suggestion -- "Use This Photo" always works regardless, since a hard
     block would exclude people the detector misreads or who can't physically pose that way. 55 tests passing
     total. See ios/README.md.

     Future idea noted (not built yet): adding friends and showing off avatars, possibly having them roam
     around the app after a friend request is accepted. This would need its own privacy/safety pass before
     building (this app currently has no backend/accounts/sharing at all) -- plan separately when ready.


     Avatar background removal (iOS): the avatar photo's background is now cut to transparent
     before pixelating (AvatarBackgroundRemoval.swift), using Vision's on-device person-segmentation
     model as the "contrast" signal between avatar and background -- its per-pixel person-confidence
     map gets a hard 50% threshold applied, splitting the photo cleanly: above it stays opaque in its
     original color, below it goes fully transparent. Considered and rejected a plain RGB-contrast/edge
     threshold instead, since there's no dependable background color to measure against in an arbitrary
     photo and it fails on exactly the hard cases (dark hair on a dark background, busy backgrounds).
     Falls back to the untouched original if no person is found. Also fixed: photos are now orientation-
     normalized before Vision ever sees them (AvatarImageProcessing.normalizingOrientation), used by both
     the background-removal pipeline and the arms/pose check added last session -- EXIF-rotated photos
     (most portrait shots from the Photos library) were previously read sideways by the pose check. Runs
     off the main actor so a large photo doesn't freeze the UI. 63 tests passing total. See ios/README.md.
