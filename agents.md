# Penguin-Kun Wars — Android Arcade Port Plan

## Summary

Build a free, single-player Android MVP in Godot that recreates the 1985 *Penguin-Kun Wars* arcade experience, using newly created art and audio based on gameplay references. The original was released by UPL in 1985. [Nintendo’s game listing](https://www.nintendo.com/us/store/products/arcade-archives-penguin-kun-wars-switch/) confirms the title and year.

## Implementation Changes

- **Verify the reference and rights:** Gather gameplay footage and other lawful references; document the original rules, timing, character roster, scoring, and any regional differences. Identify the rights holder and review permission to use the game’s name, characters, and branding before public release.
- **Build the arcade loop in Godot:** Implement the player-versus-CPU match, opponent behavior, scoring, round flow, and original-inspired visuals and audio. Use touch controls designed for portrait and landscape phone play; settle orientation after checking reference footage and usability.
- **Complete the Android app:** Add menus, pause and resume, settings, local high scores, and Android build configuration. Prepare a free Google Play release with no ads or in-app purchases in the MVP.
- **Keep the MVP focused:** Defer multiplayer, online services, extra modes, and progression until the core match is playable and reviewed.

## Test Plan

- Check that match rules, scoring, timing, and character behavior match the documented references.
- Test touch input, CPU play, match completion, pause/resume, and high-score persistence.
- Check layout and performance on a range of Android screen sizes and aspect ratios.
- Produce a signed release build and complete Play Store listing and device compatibility review.

## Assumptions

- “Faithful port” means recreating the arcade gameplay with new assets, not embedding the original ROM or copying its original art and audio.
- The MVP targets solo play against the CPU.
- Detailed rules and public use of the title or character designs remain subject to reference research and rights review.
- No public API or backend is required for the MVP.
