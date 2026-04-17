# Tower Defense Godot

**The TD Ecosystem:** [📱 Kotlin/Android (Flagship)](https://github.com/rogal01/tower-defense-android) | [🎮 Godot (Fast Iteration)](https://github.com/rogal01/tower-defense-godot) | [⚙️ Unity (Code-First)](https://github.com/rogal01/tower-defense-unity-port)

A mobile-first tower defense project built with **Godot 4.3** and focused on gameplay flow, UI clarity, and fast iteration.

Compared with the Kotlin Multiplatform flagship, this version is more engine-driven and lightweight. That makes it a strong portfolio piece for showing how I approach prototyping, onboarding, HUD polish, and gameplay feel inside a modern engine workflow.

> Portfolio note: add a short gameplay GIF or 2-3 screenshots near the top before making the repo public.

## Why This Matters To Clients

- It shows that I can move quickly inside a game engine without losing project structure.
- It demonstrates fast iteration on user-facing systems like menus, HUD flow, tutorials, and save progression.
- It proves I can adapt the same product idea to a different engine and a different development style.
- It translates well to clients who need a playable prototype, stronger UX, or a rapid gameplay validation cycle.

## Highlights

- campaign progression with save support
- wave previews, boss warnings, and terrain alerts
- first-run tutorial overlay and polished HUD flow
- WAV-backed music and sound effects
- improved projectile feedback and stronger combat presentation
- mobile-oriented menu and interface structure

## Technical Focus

- practical Godot 4 project structure
- gameplay iteration in an engine-first workflow
- UI and HUD polish for mobile-friendly interaction
- save and progression systems through autoloads and scene composition
- clearer onboarding and first-run user experience

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

## Why This Version Exists

Within the tower-defense ecosystem, the Godot version is the **fast-iteration build**. It is useful for exploring:

- combat readability and feedback
- mobile-first HUD and menu usability
- tutorial onboarding and first-run experience
- faster gameplay adjustments inside an engine-centered workflow

## Engineering Takeaways

- scene-driven architecture balanced with reusable script structure
- autoload-based state management for save and progression flows
- gameplay/UI iteration with a strong focus on clarity and feel
- adaptation of the same genre space across different technical constraints

## Part Of The Multi-Engine Ecosystem

This repository complements:

- the **Kotlin/Android flagship**, which emphasizes cross-platform native architecture
- the **Unity port**, which emphasizes code-first runtime bootstrap and maintainable systems structure

Together, the three versions demonstrate that I can learn frameworks quickly, separate core gameplay concerns from delivery layers, and choose different architectures depending on the product goals.
