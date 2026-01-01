# Changelog

Keep a short, plain-English list of major changes.

## Unreleased
- Added pause menu with settings for volume, base speed, and spawn rate (with reset defaults).
- Added music playlist cycling `sound/1.mp3`, `sound/2.mp3`, and `sound/3.mp3`.
- Updated background/tank alignment and viewport stretch settings to fill the game window.
- Updated fish art assets, collision shapes, and sprite behavior (glow and facing).
- Tuned tier-based speed scaling for player and NPC fish.
- Rebuilt Windows export binaries.

## 2026-01-01
- Added tier objectives and on-screen prompts for progression and status feedback.
- Added new NPC behaviors (schooling, skittish prey, ambush predators) for more variety.
- Added camera shake feedback on bites and hits.
- Moved tip messages to the bottom of the screen and added edge avoidance so fish don't crowd the borders.
- Showed main menu and win screens as overlays so gameplay animates behind them.
- Fixed game-over buttons by enabling HUD input when not paused.

## How to update
- Add a new bullet under "Unreleased" for each major change.
- When you ship or share a version, copy "Unreleased" into a dated section and clear "Unreleased".
