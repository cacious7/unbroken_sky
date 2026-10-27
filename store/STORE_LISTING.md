# Store listing kit: The Unbroken Sky, Chapter One

Draft text and answers for Google Play and itch.io. Graphics are in `store/graphics/` (regenerate with `engine/tests/store_shots.tscn`). Review every line before submitting; Google's forms change, so answer from the live form, using this as the starting point.

## Google Play text

**App name** (30 max): The Unbroken Sky

**Short description** (80 max, 78 used):
A courier, a dying river kingdom and a secret older than him. Chapter One free.

**Full description** (4,000 max):

> The well in Red Hollow gives clear water, then black silt, then a whisper that says your name.
>
> Tavo is a courier and repair hand from a dry upland town. When the last clean water runs out, he sets off for the fortress at Reed Gate to bring back the wheel that could make it flow again. On the road he meets a healer who won't let her people's suffering excuse what their rulers did, a mother who has kept a secret for seventeen years, and something in the water that knows his voice.
>
> The Unbroken Sky is a story-led fantasy adventure inspired by Zambia: its landscapes, its eagle and its questions about who pays for a kingdom's prosperity.
>
> CHAPTER ONE INCLUDES
> - The complete first act: ten scenes, from a broken pump to a fortress in the flood
> - Choices that matter: decide who gets the last clean water, and live with it
> - Readable, forgiving combat against abandoned covenant husks: strike, dodge, interrupt
> - The first flight: learn to fly as an eagle above a drowned fortress
> - Tap-to-move or on-screen stick controls, designed for phones
>
> MADE TO BE PLAYED ANYWHERE
> - Fully offline. No account, no ads, no in-app purchases
> - Small download for mobile data
> - Large text, adjustable text speed, captions for important sounds, flight assist, and an option to turn off shake and vibration
>
> Chapter One is free. Tell us what you think. Your feedback shapes Chapter Two.

**Category**: Game › Adventure (alternative: Role Playing)

**Tags** (pick from Play's list): Adventure, Story-driven, Fantasy, Offline, Single player

## Graphics checklist (Google Play)

| Asset | Requirement | File |
| --- | --- | --- |
| App icon | 512×512 PNG, 32-bit | `store/graphics/icon_512.png` |
| Feature graphic | 1024×500 PNG/JPG | `store/graphics/feature_graphic.png` |
| Phone screenshots | 2–8, 16:9 landscape, at least 1080 px on the short side recommended | `store/graphics/screenshot_*.png` (1920×1080) |

## App content answers (draft; confirm against the live forms)

- **Ads**: No ads.
- **App access**: All functionality is available without special access or login.
- **Target audience**: 18 and over (the story has supernatural horror, peril and violence). Not designed for children.
- **Content rating (IARC questionnaire)**, expected answers:
  - Violence: yes, fantasy violence against non-human creatures (husks, a water creature). No blood or gore. A character dies off-screen in a flood (not shown graphically).
  - Fear/horror: yes, mild supernatural horror (a figure imitating a mother's voice, whispers).
  - Sexual content, nudity, profanity, drugs, alcohol, gambling: none.
  - User interaction, sharing location, digital purchases: none.
- **Data safety**: The app collects no data and shares no data. No data is transmitted off the device. (Saves are stored locally only.) Encryption in transit: not applicable. Data deletion: uninstalling removes all data.
- **Privacy policy URL**: required even with no data collection. Host `docs/privacy-policy.html` (for example with GitHub Pages) and fill in the contact address first.
- **Government app / financial features / health**: No.
- **News app**: No.

## itch.io

- Kind of project: HTML (playable in browser), plus a downloadable APK.
- Upload `engine/build/unbroken_sky_web.zip` and tick "This file will be played in the browser". Viewport 960×540, enable "Mobile friendly" and the fullscreen button.
- Upload the APK as a downloadable for Android.
- Genre: Adventure. Tags: story-rich, fantasy, africa, eagle, choices-matter, singleplayer, offline.
- Pricing: free (optionally "No payments" or "Donate").
- Use the same short and full description and screenshots.

## Before the first Play upload

1. Choose the permanent package name and set it in both Android presets in `engine/export_presets.cfg` (currently the placeholder `com.unbrokensky.game`).
2. Fill in the contact address in `docs/privacy-policy.html` and publish it.
3. Build with `bash engine/tools/build_release.sh` and upload `engine/build/android/unbroken_sky.aab` to a **closed testing** track.
4. Enrol in Play App Signing (default for new apps). The key in `%USERPROFILE%\.unbroken_sky_keys\` is the upload key; back it up.
