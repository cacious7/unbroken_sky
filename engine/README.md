# The Unbroken Sky: Godot project

Godot 4.7.2 (standard build), GDScript, Compatibility renderer, 960×540 design canvas, landscape. Story canon lives in `../Game Concept/`; the release plan is `../Game Concept/development/LAUNCH_PLAN.md`.

## Layout

| Path | Contents |
| --- | --- |
| `scenes/` | `main.tscn` (title screen), `well_yard.tscn` (SC02) |
| `scripts/` | `game_state.gd` (autoload: flags, input map, versioned local save), `player.gd`, `interactable.gd`, `block.gd`, `placeholder.gd` (greybox drawing), `dialogue_box.gd`, `hud.gd`, `touch_controls.gd`, `well_yard.gd` |
| `data/dialogue/` | One JSON file per scene. Stable line ids. `"system": true` marks lines that are not from FINAL_SCRIPT.md |
| `tests/` | Headless checks for dialogue data, save recovery and the SC02 sequence |
| `build/` | Export output, ignored by Godot (`.gdignore`) and git |

## Commands

Godot is installed by winget at `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\`. Run these from this folder with `Godot_v4.7.2-stable_win64_console.exe` as `godot`:

```
godot --path .                                      # play
godot -e --path .                                   # open the editor
godot --headless --path . res://tests/test_runner.tscn               # tests
godot --headless --path . --export-debug "Android" build/android/unbroken_sky_debug.apk
godot --headless --path . --export-release "Web" build/web/index.html
```

Controls (all work together; any direct movement cancels a tap-walk):
- Keyboard: WASD or arrow keys to move; E, Space or Enter to interact and advance dialogue.
- Mouse: click the ground to walk there; click an object or person to walk to it and use it.
- Touch: tap the ground or an object as with the mouse; press and drag on the left half for a floating stick; USE button bottom right; tap anywhere to advance dialogue.

## Toolchain on this machine

- JDK: Eclipse Temurin 17 (`C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot`)
- Android SDK: `%LOCALAPPDATA%\Android\Sdk` with platform-tools, build-tools 35.0.1 and 36.1.0, platforms 35 and 36, NDK 28.1, CMake 3.10 (NDK/CMake are for the Gradle build needed for Play AABs)
- Debug keystore: `%APPDATA%\Godot\keystores\debug.keystore`. The Play **upload** keystore, when created, must live outside this folder and outside OneDrive, with a backup.
- On this PC Godot switches to ANGLE (OpenGL ES over Direct3D 11) for the Intel HD 530. That is expected.

## Before the first Play upload

- Confirm the package name. `com.unbrokensky.game` is a placeholder and **cannot be changed after the first upload**.
- Switch the Android preset to Gradle build and export an AAB, signed with the upload keystore.

## Progress log

### 27 October 2026: session 1

- Built: SC02 well yard as a greybox (title screen, movement, interaction, dialogue from JSON, objectives, local save with resume, touch controls, end card).
- Verified: 19 headless checks pass (dialogue ids and references, corrupt/old/edited saves, pin-before-pump order, no early exit, reveal on the third pull, pump count capped, interrupted reveal resumes). The game runs on desktop without errors. The Android debug APK (28 MB, arm64, target SDK 36) and the web build (≈10 MB compressed) export successfully.
- Not yet verified: running on the phone; touch controls have only been checked in code, not by hand. Nobody else has played it yet.
- Phone check by owner: controls acceptable. Requested tap-to-move and tap-to-use alongside the stick; added the same session (tap vs. drag decided by a 14 px slop, straight-line walking with stuck detection, padded tap targets). 23 headless checks pass.
- Known limit: tap-walking goes in a straight line and stops if blocked; it does not path around obstacles yet. Add Godot navigation when rooms get more cluttered (Ash Road, Reed Gate).

### 27 October 2026: session 1, continued (week 2 scope)

- Built: `StoryScene` base class (shared wiring; each scene overrides `_dialogue_file`, `_start`, `_on_used`, `_objective`). `Settings` autoload (text size Normal/Large/Largest, text speed Normal/Fast/Instant; saved apart from story progress). Pause menu (II button, Escape, Android back) with a backdrop that blocks taps behind it. Dialogue choices with plain-language previews, `effects` applied through `GameState.apply_effects`, and `if` conditions so branches reconverge in one conversation. Scene routing via `scene_id` (Continue resumes the right scene; SC02's exit now leads to SC03).
- SC03 "The last clean water": arrival, choice C1 (reserve 12 jars / share 6 / joint 10), joint path's shared pipe-and-spring repair setting `water_compact`, Mera reading Eren's seal, exit to an end-of-build card. Interrupted scenes resume correctly.
- Verified: 49 headless checks pass (adds dialogue schema checks for choices and conditions, illegal saved policies, settings, all three C1 paths, SC03 resume). Screenshots of choices and pause menu reviewed at Normal and Largest text: no clipping. New tool: `tests/screenshot.tscn` (needs a window) renders those UI states to PNG.
- Not yet verified on the phone: choices by touch, the Android back button, Largest text on the phone's screen.
- Needed soon: a project icon (Android export currently uses Godot's default).
- Next: phone test of SC02→SC03; then week 3 (husk combat and eagle flight greyboxes).

### 27 October 2026: session 1, continued (week 3 scope)

- Combat: `Husk` (approach → windup with growing glow and "!" → strike lunge → recovery with the copper connector exposed). Hammer hits deflect, interrupt (during windup) or damage the connector (during recovery); three connector hits break a husk. Tavo has 3 health, a dodge with brief protection, and a grace period after a hit. Captions mirror every tell and result. Keys J/F strike, K/Shift dodge; E strikes when nothing is in reach. Touch: the action button becomes STRIKE in combat and a DODGE button appears. Husks freeze during dialogue and pause.
- SC04 home (Mera's warnings, Sena's key and bird, the age-seven admission, Daru at the gate). SC05 Ash Road: one husk on first contact, the second only after the first breaks; defeat returns Tavo to the encounter entrance with full health and resets only the current husk; then the merchant, way station and Nali. Chain now runs SC02 → SC03 → SC04 → SC05 → end card.
- Eagle flight (`Eagle`, `Perch`, `Gust`): SC09 greybox with three links (safe; gust with an updraft "to the left"; release wheel), airtime bar, return to the last perch on failure, human landing that unlocks the eagle. Steering by keys or by holding a finger/mouse where you want to go. Pause-menu "Flight assist" widens landings ×1.5, extends airtime and halves gusts. Reachable from the title screen's test-room buttons (debug builds only; they use a separate save).
- Verified: 87 headless checks pass, including a real-time check that a husk's full attack lands on a player who stands still. Screenshots of windup, exposed connector and flight reviewed; the eagle was enlarged after review.
- Not yet verified: how combat and flight *feel* on the phone (timings are first guesses: windup 0.85 s, recovery 1.2 s, airtime 3.5 s). These numbers are constants at the top of `husk.gd`, `player.gd` and `fortress_flight.gd`.
- Next: phone feel-test of the husk fight and flight, then week 4–5 greybox content (SC06 water figure, SC07–SC08 Reed Gate and flood escape, SC10), which connects SC05 to SC09 and completes Act One in shapes.

### 27 October 2026: session 1, continued (weeks 4–5 scope)

- Act One is playable end to end in greybox: SC02 → SC10, ending on the "End of Chapter One" card. New: SC06 culvert (reflection, question, `WaterRope` with a marked sweep ring and an exposed copper hook), SC07 Reed Gate (drain → brace → key, with explanations for wrong order), SC08 keeper room (Eren, then a `FloodWater` escape up a marked zig-zag stair; being caught restarts only the climb), SC09 now in the chain, SC10 wheel and the news of Mera's detention. Hammer targets are now any node in the `hammer_target` group.
- Verified: 117 headless checks pass, including a full-chapter run that plays every scene in order on one save and confirms the C1 choice, water compact, key and eagle are remembered at the end. All scenes start in a window without errors.
- Art and sound sample (owner asked for real art instead of shapes): original SVG sprites for Tavo, a husk and the eagle (fish-eagle colouring) and five synthesised sound effects in `assets/`, recorded in `assets/ASSET_REGISTER.md`. `tests/showcase.tscn` renders greybox vs. sample. Not yet wired into the game, pending the owner's choice of art direction.
- Not included yet: SC01 prologue (under 40 seconds, no play; optional per M1).

### 27 October 2026: session 1, continued (first art and sound pass)

- Art direction chosen: flat vector (SVG). The whole cast is generated from one template (`tools/generate_characters.gd`); 31 hand-drawn props in `assets/art/props/`; sprites are assigned by node name in `data/art_catalog.json` (`ArtCatalog`), so scenes don't need editing to add or swap art. Tavo faces his walking direction and bobs as he walks; husk tells (windup glow, red strike, ringed connector) are drawn on its sprite; the eagle banks to its heading with wingbeats and a shadow.
- Scenes are depth-sorted by y, so characters pass in front of and behind props. Ground surfaces get subtle texture (pebbles, dry grass; ripples on water) via `ground_detail.gd`; walls draw as mud-brick; perches look like stone ledges.
- Sound: `Sfx` autoload plays the synthesised effects (hammer by result, husk windup, water sweep, pump squeak, the whispered "Present" via a dialogue line's `"sfx"` field). Pause menu has Sound On/Off.
- App icon: `assets/icon.svg`.
- Verified: 119 headless checks pass (adds art catalog and sound-name checks). Visual review of all nine scenes via `tests/tour.tscn`.
- Next: phone check of the art at real size; SC01 prologue; title screen art; portraits for dialogue.

### 27 October 2026: session 1, continued (prologue, title, portraits)

- SC01 prologue (`prologue.tscn`): darkness, scraping metal, two children's hands either side of the copper channel, the moving line of daylight, three lines, the sleeve (in Mera's colour, unstated), the door, hard cut, "SEVENTEEN YEARS LATER. RED HOLLOW." Captions for both sounds; Skip button. New games now start here.
- Title screen: original dawn backdrop with the eagle, outlined title.
- Dialogue portraits: the speaker's head is cut from their character sprite (characters now import at 3× so close-ups stay sharp); voices without a sprite (WHISPER, VOICE, CHILD ONE) show none. Eren has a generated sprite for his portrait.
- Verified: 127 headless checks pass (adds prologue play-through and skip, portraits, SC01 in the full-chapter run). Title, prologue and portrait reviewed as screenshots.

### 27 October 2026: session 1, continued (controls and combat feel)

- Owner feedback: synthesised audio is poor (replace with real recorded/licensed sound later); current art is good enough for now; focus on gameplay and controls.
- Tap-to-walk now pathfinds around walls and solid objects (`NavGrid`, an AStarGrid2D rebuilt from the scene's solid rectangles at each tap, so appearing characters are respected). Partial paths end as close as possible to an unreachable point.
- Combat: tapping a husk walks up to it and swings. Hits now have hit-stop (0.06 s, 0.12 s on a break), a small husk knockback (~12 px, stays in hammer reach), view-only screen shake, phone vibration and a red damage flash. Pause menu: "Shake & vibration: On/Off". Android vibrate permission added.
- Touch: the action button names its action from the object's prompt (TALK, SEARCH, LOOK, LIFT…), STRIKE in combat; buttons highlight when pressed.
- Verified: 134 headless checks pass (adds zig-zag stair pathfinding, walking round the well, tap-to-attack, knockback, hit-stop recovery, shake reset, action verbs).
