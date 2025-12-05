# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Legend of Shadowtail** — A Godot 4.5 2D action game where a ninja squirrel infiltrates a dungeon to retrieve a stolen magical acorn. The player uses shurikens, a katana, and rolling to navigate and fight enemies.

## Running the Game

Open the project in Godot 4.5 and press F5, or run from command line:
```bash
godot --path .
```

## Architecture

### Autoload Singletons
- **AudioManager** (`scenes/AudioManager/audio_manager.gd`) — Plays positional SFX via `AudioManager.PlaySFX(stream, node)`
- **InventoryManager** (`code/InventoryManager.gd`) — Manages collected items (keys, health, story items). Uses signals: `item_added`, `item_removed`, `item_collected`

### Player State Machine
The Player (`scenes/Player/player.gd`) uses a state machine with three states:
- **Move** — Normal movement, can transition to Roll or Action
- **Roll** — Dodge roll with invincibility frames
- **Action** — Executes an ActionState (katana swing or shuriken throw)

Actions use the **Strategy Pattern** via `ActionState` base class. Concrete implementations:
- `KatanaActionState` — Melee attack, plays animation
- `ShurikenActionState` — Ranged projectile with cooldown

### Combat System
Uses a bidirectional HitBox/HurtBox pattern:
- **HitBox** (`code/HitBox.gd`) — Deals damage. Has `damage` and `knockback` properties. Emits `hit(hurtbox)` when hitting something
- **HurtBox** (`code/HurtBox.gd`) — Receives damage. Emits `hurt(hitbox)` when hit

Both defer signal emission to avoid physics query conflicts.

### Enemy AI
Enemies like `PatrollingEnemy` use state machines with states: IDLE, PATROL, CHASE, STUN. They use raycasting for line-of-sight player detection.

### Scene Management
`GameManager` (`scenes/Main/game_manager.gd`) is a singleton pattern (not autoload) that handles scene transitions via `GameManager.change_scene(path)`.

## Physics Layers
1. **World** — Environment collision
2. **Player** — Player collision
3. **Enemy** — Enemy collision

## Project Structure
- `scenes/` — Feature-organized scenes with their scripts (Player, Enemies, UI, Items, etc.)
- `code/` — Shared reusable scripts (HitBox, HurtBox, InventoryManager)
- `temp assets/` — Placeholder assets

## Input Actions
Defined in `project.godot`:
- Movement: `move_left`, `move_right`, `move_up`, `move_down` (WASD/Arrows/Gamepad)
- `roll` (K/Z/Gamepad A)
- `action_1` (L/X/Gamepad B) — Primary action (katana)
- `action_2` (J/C/Gamepad Y) — Secondary action (shuriken)
- `pause` (P/Gamepad Start)
