# Tower Defense Godot

Mobile-first tower defense prototype built with Godot 4.3.

## Highlights

- Campaign progression with save support
- Wave previews, boss warnings, and terrain alerts
- First-run tutorial overlay and HUD polish
- WAV-backed music and sound effects
- Stronger projectile feedback and tower combat presentation

## Getting Started

1. Install Godot 4.3.
2. Open this folder in the Godot editor.
3. Run the project from `project.godot`.

The game starts from `res://scenes/main_menu.tscn`.

## Project Layout

- `scenes/` contains game scenes and UI scenes
- `scripts/autoloads/` contains save, audio, and progression singletons
- `scripts/core/` contains campaign, map, and run flow logic
- `scripts/entities/` contains enemies, towers, and player entities
- `scripts/ui/` contains the menu, HUD, pause, and game-over interfaces
