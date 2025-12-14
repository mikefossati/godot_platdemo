# Game Design Documentation

## 1. THE SUBJECT (Who/What You Control)

### The Player Character
- **Visual Representation**: A white capsule (cylinder with rounded ends) that is 2 units tall
- **Identity**: An abstract character - intentionally simple to focus on mechanics rather than narrative
- **Size**:
  - Height: 2 units (meters in Godot units)
  - Radius: 0.5 units
  - Total collision capsule is about human-sized
- **Starting Position**: Spawns at coordinates (0, 2, 0) - in the center of the level, 2 units above ground

### Character Properties
The player is a **physics-enabled character** with these attributes:
```
Speed: 5 units/second (walking speed)
Jump Power: 10 units/second (initial upward velocity)
Rotation Speed: 10 radians/second (how fast they turn)
Mass: Affected by gravity (20 units/second²)
```

## 2. THE PURPOSE (Game Objective)

### Primary Goal
**Collect all 5 collectibles** scattered throughout the level while avoiding falling off the platforms.

### Collectible System
- **Total Items**: 5 collectibles (golden rotating toruses/rings)
- **Points per Item**: 10 points each
- **Maximum Score**: 50 points (if all collectibles are gathered)
- **Visual Feedback**: Each collectible rotates and bobs up/down to attract attention
- **Collection Method**: Walk into them (overlap detection, not collision)

### Win/Loss Conditions

**Implicit Win State**:
- Collect all 5 collectibles (5/5 shown on screen)
- No formal "victory screen" - this is a prototype focused on mechanics
- You can continue playing after collecting all items

**Loss Condition**:
- Fall below Y position of -10 (10 units below the ground level)
- Triggers "Game Over" screen
- Shows final score and collectibles gathered
- Options: Retry or return to Main Menu

### Gameplay Loop
```
Main Menu → Start Game → Explore Level → Collect Items
                              ↓
                         Fall Off Level?
                              ↓
                        Game Over Screen → Retry or Menu
```

## 3. THE DYNAMICS (Gameplay Mechanics)

### Movement System

#### Horizontal Movement (WASD)
- **W**: Move forward (negative Z direction in 3D space)
- **A**: Move left (negative X direction)
- **S**: Move backward (positive Z direction)
- **D**: Move right (positive X direction)
- **Speed**: Constant 5 units/second when keys are pressed
- **Acceleration**: Instant (arcade-style, not realistic)
- **Deceleration**: Gradual friction when no input (moves toward zero velocity)

#### Rotation Behavior
- **Auto-rotation**: Character automatically rotates to face the direction of movement
- **Smooth Interpolation**: Uses `lerp_angle` for fluid turning (not instant snapping)
- **Turn Speed**: 10 radians/second
- **Purpose**: Visual feedback showing which way the player is moving

#### Vertical Movement (Jumping)
- **Jump Button**: Spacebar
- **Jump Force**: Instant upward velocity of 10 units/second
- **Jump Restriction**: Can ONLY jump when touching the ground
  - Uses `is_on_floor()` detection
  - Prevents double-jumping or air-jumping
  - Creates classic platformer "feel"
- **Jump Arc**: Natural parabolic curve created by gravity

#### Wall Sliding
- When moving into a wall or obstacle, the player **slides along** the surface
- Built into `move_and_slide()` function
- Allows for smooth navigation around corners

### Level Design

#### Platform Layout
```
Ground Floor (Y=0):
  - Main platform: 20x20 units (large square base)

Elevated Platforms:
  - Platform 1: 4x4 units at position (5, 1, 0) - height 1 unit
  - Platform 2: 4x4 units at position (-5, 2, 3) - height 2 units
  - Platform 3: 4x4 units at position (0, 3, -5) - height 3 units
  - Platform 4: 4x4 units at position (3, 1.5, 6) - height 1.5 units
```

#### Collectible Placement
Each collectible is placed **above** its corresponding platform:
```
Collectible 1: Above Platform 1 at height 2.5
Collectible 2: Above Platform 2 at height 3.5
Collectible 3: Above Platform 3 at height 4.5
Collectible 4: Above Platform 4 at height 3.0
Collectible 5: On ground at position (-3, 1, -3)
```

**Challenge Design**: Players must jump between platforms of varying heights to collect all items.

### Camera System

#### Third-Person Perspective
- **Position**: Behind and above the player
- **Offset**: 8 units back, 5 units up from player position
- **Follow Speed**: Smooth interpolation (lerp) at 5 units/second
- **Look Target**: Always points at player, 1 unit above their feet
- **Behavior**: Camera "chases" the player with slight delay for cinematic feel

### UI Feedback

#### Real-time Display (Top-left corner)
```
Score: [current score]
Collectibles: [gathered]/[total]
```

Updates immediately when:
- A collectible is picked up (score increases by 10)
- Total collectibles count is set (when level loads)

## 4. THE PHYSICS (How the Physics System Works)

### Physics Engine: Godot 4.x Physics Server

This game uses **kinematic character physics** (not rigid body dynamics).

### Gravity System

#### Gravity Value
- **Strength**: 20 units/second² (double Earth's gravity for snappier platforming)
- **Direction**: Downward (negative Y-axis)
- **Application**:
  ```gdscript
  if not is_on_floor():
      velocity.y -= gravity * delta
  ```
  - Only applied when **not touching ground**
  - Accumulates each frame (creates acceleration)
  - `delta` ensures frame-rate independence

#### Why 20 instead of 9.8?
- Standard Earth gravity (9.8 m/s²) feels "floaty" in platformers
- Doubled gravity creates:
  - Faster falling speed
  - Tighter jump arcs
  - More responsive controls
  - Classic platformer "feel"

### Velocity System

The player has a **velocity vector** with 3 components:
```
velocity.x = horizontal movement (left/right)
velocity.y = vertical movement (up/down - affected by gravity/jumps)
velocity.z = horizontal movement (forward/backward)
```

#### Velocity Application
Every physics frame (60 FPS):
1. **Gravity** modifies `velocity.y` (if airborne)
2. **Jump input** sets `velocity.y = 10` (if on ground)
3. **Movement input** sets `velocity.x` and `velocity.z` (based on WASD)
4. **Friction** reduces horizontal velocity toward zero (when no input)
5. **move_and_slide()** applies the velocity and handles collisions

### Collision Detection

#### Collision Layers (Physics Filtering)
```
Layer 1 (World): Platforms, ground, static obstacles
Layer 2 (Player): The player character
Layer 3 (Collectibles): Items to pick up
```

**How it works**:
- Player (Layer 2) **collides with** Layer 1 (World)
  - Stands on platforms
  - Cannot pass through walls
- Player (Layer 2) **overlaps with** Layer 3 (Collectibles)
  - Doesn't physically collide
  - Triggers collection event via Area3D

#### Collision Shapes
- **Player**: CapsuleShape3D (smooth sliding on edges, doesn't get stuck on corners)
- **Platforms**: BoxShape3D (simple rectangular collision volumes)
- **Collectibles**: SphereShape3D (easy to touch from any angle)

### CharacterBody3D vs RigidBody3D

This game uses **CharacterBody3D**, not RigidBody3D. Here's why:

| Aspect | CharacterBody3D (Used Here) | RigidBody3D (Not Used) |
|--------|----------------------------|----------------------|
| **Control** | Direct velocity control | Force-based (indirect) |
| **Rotation** | Manual control | Physics engine rotates it |
| **Predictability** | Precise, arcade-style | Realistic but unpredictable |
| **Use Case** | Player characters | Boxes, balls, physics objects |
| **Advantages** | Responsive controls, no tipping over | Realistic interactions |

**Why CharacterBody3D for this game**:
- Players expect **responsive** controls in platformers
- Don't want character to tip over or tumble
- Need **precise** jump heights and distances
- Want **predictable** movement (not momentum-based)

### move_and_slide() Explained

This is the **core physics function** called every frame:

```gdscript
move_and_slide()
```

**What it does**:
1. Takes the current `velocity` vector
2. Attempts to move the character in that direction
3. **Detects collisions** with Layer 1 objects
4. **Slides along surfaces** instead of stopping dead
5. Updates `global_position` to new location
6. Sets `is_on_floor()` flag if touching ground below

**Sliding Behavior**:
- If you run into a wall at 45°, you slide along it
- If you land on a slope, you don't stick to it (gravity pulls you down)
- Prevents character from getting "stuck" on geometry

### Ground Detection

#### is_on_floor() Function
- **Purpose**: Determines if character can jump
- **Method**: Checks if there's a collision below the character
- **Threshold**: Small tolerance angle (default ~46°)
- **Updates**: Automatically set by `move_and_slide()`

**Why it matters**:
```gdscript
if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = jump_velocity
```
Without `is_on_floor()` check:
- Could jump infinitely in mid-air (no skill required)
- Would break platforming challenge

### Frame-Rate Independence (Delta Time)

**The Problem**: Different computers run at different speeds (30 FPS vs 144 FPS)

**The Solution**: `delta` parameter
```gdscript
func _physics_process(delta: float):
    velocity.y -= gravity * delta  # gravity * time elapsed
    rotation.y = lerp_angle(rotation.y, target, speed * delta)
```

**What is delta?**
- Time (in seconds) since last physics frame
- At 60 FPS: delta ≈ 0.0167 seconds
- At 30 FPS: delta ≈ 0.0333 seconds

**Result**: Game plays at same speed regardless of frame rate
- Character falls at same speed on all computers
- Jumps same height on all computers
- Movement speed identical on all systems

### Death/Fall Detection

```gdscript
const DEATH_Y: float = -10.0

if global_position.y < DEATH_Y:
    die()
```

**How it works**:
- Checks player's Y position every frame
- If below -10 (10 units below ground floor at Y=0)
- Triggers game over sequence
- Prevents player from falling forever into void

### Collectible Physics

Collectibles use **Area3D** (not collision):

```gdscript
func _on_body_entered(body: Node3D):
    if body.has_method("collect_item"):
        body.collect_item()
        queue_free()  # Remove from scene
```

**How it differs**:
- **No collision**: Player passes through collectibles
- **Overlap detection**: Triggered when player enters Area3D
- **Signal-based**: Uses `body_entered` signal
- **Duck typing**: Checks if body has `collect_item()` method

**Animation** (not physics, just visual):
- Rotation: `rotate_y(speed * delta)` - spins around vertical axis
- Bobbing: `sin(time) * height` - smooth up/down motion

## Physics Summary

```
Player Physics Pipeline (Every Frame):

1. Read Input (WASD, Spacebar)
   ↓
2. Calculate Direction Vector
   ↓
3. Apply Gravity (if airborne)
   ↓
4. Handle Jump (if on ground)
   ↓
5. Set Horizontal Velocity (from input)
   ↓
6. Update Rotation (face movement direction)
   ↓
7. Call move_and_slide()
   ↓
8. Check Collisions (with platforms)
   ↓
9. Update Position (slide along surfaces)
   ↓
10. Check Fall Death (Y < -10)
    ↓
11. Check Collectible Overlaps
```

## Key Physics Parameters

| Parameter | Value | Effect on Gameplay |
|-----------|-------|-------------------|
| Gravity | 20 m/s² | Fast falling, tight jumps |
| Jump Velocity | 10 m/s | Can reach ~5 units height |
| Speed | 5 m/s | Moderate, controllable pace |
| Rotation Speed | 10 rad/s | Quick turning |
| Death Boundary | Y = -10 | Grace period when falling |

## Design Philosophy

This game uses **arcade physics** over **realistic physics**:

✅ **Arcade Approach** (Used):
- Instant acceleration
- Precise control
- Predictable jumps
- No momentum
- Player-friendly

❌ **Realistic Approach** (Not Used):
- Gradual acceleration
- Momentum-based
- Variable jump height
- Inertia
- Simulation-focused

**Result**: Tight, responsive platformer controls similar to classic 3D platformers like Super Mario 64 or Crash Bandicoot.
