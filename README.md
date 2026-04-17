# Tower Defense Godot

A mobile-first tower defense prototype built with **Godot 4.3**.

This project focuses on gameplay flow, UI clarity, and fast iteration. Compared with the Kotlin Multiplatform version, this repo is lighter and more engine-driven, which makes it useful for experimenting with combat feel, onboarding, HUD polish, and content pacing inside Godot.

## Highlights

- Campaign progression with save support
- Wave previews, boss warnings, and terrain alerts
- First-run tutorial overlay and polished HUD flow
- WAV-backed music and sound effects
- Improved projectile feedback and stronger combat presentation
- Mobile-oriented menu and interface structure

## What This Repo Shows

- practical Godot 4 project structure
- gameplay iteration in an engine-first workflow
- UI/HUD polish work for mobile-friendly interaction
- save/progression systems through autoloads and scene composition

## Project Structure

```text
scenes/                # gameplay scenes and interface scenes
scripts/autoloads/     # save, audio, and progression singletons
scripts/core/          # run flow, campaign, maps, and game state
scripts/entities/      # enemies, towers, and gameplay actors
scripts/ui/            # menus, HUD, pause, tutorial, and game-over UI
```

## Getting Started

1. Install **Godot 4.3**.
2. Open this repository in the Godot editor.
3. Run the project from `project.godot`.

The game starts from `res://scenes/main_menu.tscn`.

## Current Focus Areas

- campaign progression and save flow
- combat readability and feedback
- mobile-first HUD and menu usability
- tutorial onboarding and first-run experience

## Why It Belongs in the Portfolio

This repository complements the larger tower-defense projects by showing the same genre through a different engine and development style. It helps demonstrate that I can adapt the same product space across multiple technology stacks, not just build one implementation.
