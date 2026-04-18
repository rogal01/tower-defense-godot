# 🏰 Tower Defense: Godot Edition

[![Godot Engine](https://img.shields.io/badge/Godot-4.3-blue.svg)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/Platform-PC%20%2F%20Mobile-green.svg)](https://godotengine.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A feature-rich, high-performance Tower Defense engine built in **Godot 4.3**. This project emphasizes a **data-driven architecture**, separating mission specifications from runtime logic to allow for rapid campaign scaling and cross-platform parity.

---

## 🎮 Key Features

### ⚔️ Combat & Strategy
- **Advanced Tower Arsenal**: Multiple tower types (Arrow, Magic, Cannon, etc.) with unique targeting logic, recoil animation, and fire-rate scaling.
- **Three-Tier Upgrade System**: Granular tower progression with persistent stat modifiers.
- **Active Power-Ups**: Global abilities like Fireball and Freeze to shift the tide of battle.
- **Wave Preview System**: Real-time HUD indicators for upcoming enemy types, boss alerts, and terrain modifiers.

### 🗺️ Dynamic Environments
- **Terrain Effects**: Map-specific modifiers including lava damage, snow slowdowns, and enchanted buffs.
- **Snapped Placement**: Precise tower construction with build-site markers and obstruction detection.
- **Visual Feedback**: Enemy health bars, status indicators, and wave-start animation banners.

### 📈 Campaign & Progression
- **20-Level Master Campaign**: Fully scripted missions with escalating difficulty and unique star-based victory rewards.
- **Data-Driven Missions**: Level configurations (waves, starting gold, multipliers) are managed via a centralized registry for easy balancing.
- **Save Management**: Persistent campaign progress, star tracking, and unlockable levels.

---

## 🏗️ Architecture

The project follows a modular design for high maintainability:

```text
scripts/
├── core/         # Engine logic (GameManager, Campaign Registry)
├── entities/     # Game objects (Towers, Creeps, Projectiles)
├── ui/           # HUD, Menus, and Tutorial Overlays
└── autoloads/    # Global State & Save Management
```

### Engineering Highlights
- **Performance Optimized**: Efficient handling of hundreds of active projectiles and entities using Godot's node-based system.
- **Clean Separation**: UI logic is decoupled from game state using signals and event-driven patterns.
- **Cross-Engine Parity**: Campaign data and multipliers are synchronized with a parallel Kotlin/Android implementation to ensure consistent gameplay across platforms.

---

## 🛠️ Tech Stack

- **Engine**: Godot 4.3
- **Language**: GDScript (Type-Safe)
- **Audio**: WAV-backed SFX and dynamic music management
- **Visuals**: Animated Sprite-based entities with custom shader-ready indicators

---

## 📥 Getting Started

1. Download [Godot 4.3](https://godotengine.org/download).
2. Clone the repository.
3. Open `project.godot` in the engine.
4. Press **F5** to run the campaign.

---

## ⚙️ Development & Design

- **Scene Composition**: Heavy use of scene inheritance and composition for entity variety.
- **Signal-Driven UI**: Robust HUD updates using Godot's observer pattern.
- **Procedural Animations**: Programmatic recoil and aim feedback for game feel.

---

## 📜 License
This project is licensed under the MIT License.
