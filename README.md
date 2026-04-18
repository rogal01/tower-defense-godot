# Tower Defense Godot

This repository is the Godot 4 port of the Kotlin tower defense game.

For the portfolio release, this project is being presented as a Kotlin-first port: the same campaign contract, progression model, tower and power roster, and general gameplay feel, implemented with Godot-native scene and script structure.

## Port Goal

This repository is not meant to be a separate reinterpretation of the game. It is meant to show how the original Kotlin version translates into Godot while still feeling natural inside the engine.

## Public Parity Target

- 6 towers
- 4 powers
- 5 maps
- 8 wave modifiers
- 20 campaign levels
- 39 achievements
- 16 skill nodes

Important rule:

- campaign map selection remains separate from campaign level selection

## Technical Highlights

- Godot 4 scene-driven runtime
- Autoload singletons for shared data, saves, audio, and achievements
- Kotlin-aligned campaign and content definitions
- Save schema reset to keep incompatible legacy progress out of the public parity mode

## Run

1. Install Godot 4.3 or newer in the 4.x line used for this project.
2. Open this folder in Godot.
3. Run `project.godot`.

The intended entry point is `res://scenes/main_menu.tscn`.

## Key Files

- `scripts/autoloads/GameData.gd`: canonicalized tower, power, map, and modifier data for the port
- `scripts/core/CampaignData.gd`: 20-level campaign contract
- `scripts/core/GameManager.gd`: gameplay flow, waves, combat, and progression
- `scripts/autoloads/AchievementManager.gd`: achievement behavior aligned to the Kotlin contract
- `scripts/autoloads/SaveManager.gd`: schema-versioned save handling
- `scripts/ui/`: menu, HUD, pause, and game-over flow

## Relationship To Kotlin

This port should match the Kotlin version in:

- content catalog
- campaign structure
- save concepts
- achievement meaning
- UI wording where that wording communicates the game contract

It intentionally keeps Godot-native implementation details such as scene structure and autoload organization.

## Public Release Notes

- Non-canonical content should stay removed or hidden from the public shipped experience.
- The public branch should land on the parity-focused version, not on an unfinished feature branch.
- The final README should ship with screenshots so employers can assess both presentation and gameplay clarity quickly.

## Media

Add final public screenshots under `media/` before publishing the repository.

Recommended captures:

- `media/main-menu.png`
- `media/gameplay.png`
- `media/hud.png`
- `media/meta-progression.png`
