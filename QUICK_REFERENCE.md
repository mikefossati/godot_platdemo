# Quick Reference Guide

## Game at a Glance

```
┌─────────────────────────────────────────────────────────┐
│  3D PLATFORMER PROTOTYPE - QUICK REFERENCE              │
└─────────────────────────────────────────────────────────┘

WHO:     White capsule character (2 units tall)
WHAT:    Collect 5 golden rotating rings
WHERE:   Multi-level platform arena with floating platforms
HOW:     Jump between platforms, avoid falling
WHY:     Score points (10 per collectible, 50 max)
```

## Controls
```
┌──────────┬─────────────────────────────┐
│   Key    │          Action             │
├──────────┼─────────────────────────────┤
│    W     │  Move Forward               │
│    A     │  Move Left                  │
│    S     │  Move Backward              │
│    D     │  Move Right                 │
│  SPACE   │  Jump (only when grounded)  │
└──────────┴─────────────────────────────┘
```

## Physics Values
```
┌─────────────────────┬─────────────┬───────────────────┐
│     Parameter       │    Value    │   Godot Unit      │
├─────────────────────┼─────────────┼───────────────────┤
│  Movement Speed     │     5.0     │  units/second     │
│  Jump Velocity      │    10.0     │  units/second     │
│  Gravity            │    20.0     │  units/second²    │
│  Rotation Speed     │    10.0     │  radians/second   │
│  Death Zone         │   -10.0     │  Y position       │
│  Physics FPS        │    60       │  frames/second    │
└─────────────────────┴─────────────┴───────────────────┘
```

## Level Layout (Top-Down View)
```
                    North (-Z)
                        ↑
                        │
              ╔═════════╗
              ║ Plat 3  ║  Y=3.0, Collectible @ 4.5
              ║  (4x4)  ║
              ╚═════════╝
                   │
                   │
West (-X) ←────────┼────────→ East (+X)
                   │
    ╔═════════╗    │         ╔═════════╗
    ║ Plat 2  ║    │         ║ Plat 1  ║
    ║  (4x4)  ║    │         ║  (4x4)  ║
    ╚═════════╝  GROUND      ╚═════════╝
    Y=2.0        (20x20)      Y=1.0
    Coll @ 3.5    Y=0         Coll @ 2.5
                   │
                   │    ╔═════════╗
                   │    ║ Plat 4  ║
                   │    ║  (4x4)  ║
                   ↓    ╚═════════╝
                        Y=1.5, Coll @ 3.0
                    South (+Z)
```

## Character Physics Model

```
                 ╭─────╮
                 │  O  │  ← Capsule Mesh (visual)
                 │  │  │     Height: 2 units
                 │  │  │     Radius: 0.5 units
                 ╰─────╯
                    │
            ┌───────┴───────┐
            │  Velocity (V) │
            │               │
            │  V.x ← WASD   │  Horizontal movement
            │  V.y ← Jump   │  Vertical movement
            │  V.z ← WASD   │  Horizontal movement
            └───────────────┘
                    │
            ┌───────┴────────┐
            │ move_and_slide │  Every frame (60 FPS)
            └────────────────┘
                    │
        ┌───────────┴───────────┐
        ↓                       ↓
    Collision                 Update
    Detection              Position
```

## Game State Machine

```
┌─────────────┐
│ MAIN MENU   │
│             │
│ [Start][Quit]
└──────┬──────┘
       │ Start Game
       ↓
┌─────────────────────────────────┐
│     GAMEPLAY                    │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Collect Items (0/5)     │   │
│  │ Score: 0                │   │
│  └─────────────────────────┘   │
│                                 │
│  Player moving, jumping...      │
│                                 │
│  Collectibles: ●●●●●            │
└────────┬───────────┬────────────┘
         │           │
         │ Fall      │ (Continue)
         │ Y < -10   │
         ↓           ↓
┌─────────────┐  ┌──────────────┐
│ GAME OVER   │  │  Collect all │
│             │  │  items = WIN │
│ Score: XX   │  │  (implicit)  │
│ Items: X/5  │  └──────────────┘
│             │
│ [Retry]     │
│ [Menu]      │
└─────────────┘
```

## Physics Breakdown

### Every Physics Frame (1/60 second):

```
1. READ INPUT
   ├─ WASD pressed? → Set horizontal velocity
   └─ SPACE pressed + on_ground? → Set jump velocity

2. APPLY GRAVITY
   └─ Not on floor? → velocity.y -= 20 * delta

3. MOVEMENT
   └─ move_and_slide() → Move + handle collisions

4. ROTATION
   └─ Smoothly rotate to face movement direction

5. CHECKS
   ├─ Position.y < -10? → Trigger death
   └─ Touching collectible? → Add points, remove item
```

## Collectible Properties

```
Visual:  Golden torus (ring shape)
Size:    Inner radius: 0.3, Outer radius: 0.5
Physics: Area3D (no collision, overlap detection)
Value:   10 points each
Total:   5 in level (50 points max)

Animation:
  - Rotation: 2 radians/second around Y-axis
  - Bobbing:  0.3 units up/down at 2 Hz frequency
  - Formula:  Y = start_y + sin(time * 2) * 0.3
```

## Camera Behavior

```
Player Position: (X, Y, Z)
Camera Offset:   (0, 5, 8)  ← 8 units back, 5 units up
Camera Position: Player + Offset (smoothed)

Look Target: Player position + (0, 1, 0)  ← Slightly above feet

Follow Speed: 5 units/second (lerp interpolation)
Result: Smooth, cinematic third-person view
```

## Collision Matrix

```
           ┌─────────┬─────────┬──────────────┐
           │  World  │ Player  │ Collectibles │
           │ (Layer1)│(Layer2) │  (Layer 3)   │
├──────────┼─────────┼─────────┼──────────────┤
│ World    │    -    │  BLOCK  │      -       │
│ (Layer1) │         │         │              │
├──────────┼─────────┼─────────┼──────────────┤
│ Player   │  BLOCK  │    -    │   OVERLAP    │
│ (Layer2) │         │         │  (trigger)   │
├──────────┼─────────┼─────────┼──────────────┤
│Collect   │    -    │ OVERLAP │      -       │
│ (Layer3) │         │(trigger)│              │
└──────────┴─────────┴─────────┴──────────────┘

BLOCK = Physical collision (can't pass through)
OVERLAP = Trigger event (passes through)
- = No interaction
```

## Jump Arc Calculation

```
Jump Physics:
  Initial velocity: 10 m/s upward
  Gravity: 20 m/s² downward

Time to peak: v₀ / g = 10 / 20 = 0.5 seconds
Max height: v₀² / (2g) = 100 / 40 = 2.5 units

Total jump arc:
  ↑ 0.5s rising
  ↓ 0.5s falling
  = ~1 second total air time

Horizontal distance (at 5 m/s):
  5 * 1 = 5 units forward per jump
```

## File Structure Reference

```
plat_godot/
│
├── project.godot          ← Engine config, inputs, physics
├── icon.svg               ← Project icon
│
├── scripts/               ← All game logic (GDScript)
│   ├── game_manager.gd    ← Global state (Autoload)
│   ├── player.gd          ← Movement + physics
│   ├── collectible.gd     ← Item behavior
│   ├── camera_follow.gd   ← Camera system
│   ├── game_ui.gd         ← HUD controller
│   ├── main_menu.gd       ← Menu controller
│   └── game_over.gd       ← Game over controller
│
└── scenes/                ← Visual scenes (.tscn)
    ├── player/
    │   └── player.tscn    ← Player w/ mesh + collision
    ├── collectibles/
    │   └── collectible.tscn  ← Collectible w/ Area3D
    ├── level/
    │   └── main_level.tscn   ← Full game level
    └── ui/
        ├── main_menu.tscn    ← Start screen
        ├── game_over.tscn    ← End screen
        └── game_ui.tscn      ← In-game HUD
```

## Key Game Development Concepts

```
┌─────────────────────────────────────────────────────┐
│  CONCEPT           │  IMPLEMENTATION                │
├────────────────────┼────────────────────────────────┤
│ Player Control     │ CharacterBody3D + velocity     │
│ Gravity            │ velocity.y -= gravity * delta  │
│ Jumping            │ velocity.y = jump_velocity     │
│ Collision          │ move_and_slide() built-in      │
│ Collection         │ Area3D overlap detection       │
│ Camera             │ Lerp follow with offset        │
│ UI Update          │ Signal-based observer pattern  │
│ Game State         │ Singleton autoload (GameMgr)   │
│ Scene Transition   │ change_scene_to_file()         │
│ Frame Independence │ Multiply by delta time         │
└────────────────────┴────────────────────────────────┘
```

## Common Questions

**Q: Why can't I jump in mid-air?**
A: `is_on_floor()` check prevents jumping unless grounded.

**Q: Why does gravity feel fast?**
A: Set to 20 m/s² (vs Earth's 9.8) for tight platformer feel.

**Q: Why does the player auto-rotate?**
A: Creates visual feedback showing movement direction.

**Q: Why can't I walk through collectibles?**
A: They use Area3D (overlap) not StaticBody3D (collision).

**Q: What happens if I collect all items?**
A: Game continues - this is a prototype (no formal win state).

**Q: Can I change jump height?**
A: Yes! Edit `jump_velocity` in player.gd (currently 10.0).

**Q: What are "units" in the game?**
A: Godot uses meters. 1 unit = 1 meter conceptually.
