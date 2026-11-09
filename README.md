# Penguin-Kun Wars — 3D arcade prototype

A Godot 4.7 Android-oriented game with original procedural 3D models. Official arcade screenshots inform the table, palette, crowd, and characters; see [REFERENCES.md](REFERENCES.md).

## Play

Open project.godot in Godot 4.7 and press F5, or select the project in Godot's Project Manager and click Run.

- Tap PLAY to begin a 60-second round.
- Move with the on-screen arrows, Left/Right or A/D, or drag across the arena.
- Press Space or PICK UP near a resting ball to hold it. Move while carrying it, then press Space or THROW again to release it from your new position. Holding Space does not repeat the action.
- Opposing moving balls bounce back toward their senders when they collide.
- Incoming balls stun a character briefly if they hit it.
- Clear your side completely to win early, or have fewer balls at the buzzer. Five each is a draw.
- Win to advance to a faster rival; the best accumulated score is stored locally.
- Use the pause button or Escape to pause/resume. Changing focus pauses the match.

The game uses ten shared balls, five on each side initially. The scoreboard counts the side each ball currently occupies, including moving balls; a carried ball still counts on your side. Models and materials are generated in main.gd; no external art packages are needed.

## Android

Install Godot's matching export templates, configure Android SDK/JDK paths in Editor Settings, and add an Android preset in Project > Export. Set a package identifier and signing configuration, then export an APK for device testing or a signed AAB for Google Play. Keep signing keys outside source control. This version uses a portrait viewport; landscape layout and real-device performance still need review.

## Current limits

This is a stylized 3D reinterpretation with simplified arcade rules and a penguin/bear matchup. Detailed original timing, full opponent roster, audio, settings, and Android device testing are not yet implemented. Original-name/character rights must be confirmed before publishing. No ROM data, original sprites, screenshots, or music are bundled.
