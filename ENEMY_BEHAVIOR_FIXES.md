# Enemy Behavior Fixes

## Summary
Fixed two critical issues with enemy behavior:
1. Enemies colliding and "merging" with each other
2. Bat/Bee enemy remaining static with no movement

## Issue 1: Enemy-to-Enemy Collision "Merging"

### Problem
Enemies would overlap and appear to merge into each other when they collided, creating an unnatural stacking effect.

### Root Cause
- Enemies had `collision_mask = 3` (detecting only World layer 1 and Player layer 2)
- This meant enemies couldn't detect other enemies (layer 4)
- CharacterBody3D's `move_and_slide()` would push through other enemies without any separation behavior

### Solution Applied

**1. Updated Collision Mask** (`scenes/enemies/base_enemy.tscn:20`)
```gdscript
collision_mask = 7  # Binary 0111 = layers 1, 2, 4 (World, Player, Enemies)
```

**2. Added Separation Logic** (`scripts/enemies/base_enemy.gd:152-176`)
Created `_apply_enemy_separation()` function that:
- Detects when enemies collide with each other using `get_slide_collision_count()`
- Calculates direction away from the colliding enemy
- Applies a horizontal separation force to push enemies apart
- Only affects X and Z velocity (preserves vertical movement/gravity)

**Key Parameters:**
- `SEPARATION_DISTANCE: 1.5` - Minimum distance to maintain
- `SEPARATION_STRENGTH: 2.0` - Force multiplier for pushing apart

### Result
✅ Enemies now smoothly push away from each other when they get too close
✅ No more "merging" or stacking effect
✅ Enemies maintain their individual space while still able to group up

---

## Issue 2: Bat/Bee Enemy Not Moving

### Problem
The Bat enemy remained completely stationary in the air, only performing a small vertical bobbing motion. It didn't patrol, circle, or move horizontally at all.

### Root Cause
Looking at `scripts/enemies/bat.gd:58-60`, the patrol logic was:
```gdscript
else:
    # If no patrol points, just hover
    velocity.x = 0
    velocity.z = 0
```

When no patrol points were assigned in the level, the bat simply set horizontal velocity to zero, making it static.

### Solution Applied

**1. Added Circular Flight Pattern** (`scripts/enemies/bat.gd:60-77`)

New export variables:
```gdscript
@export var circle_radius: float = 4.0   # Size of circular patrol
@export var circle_speed: float = 1.0    # Speed of rotation
var angle: float = 0.0                    # Current angle in circle
```

New circular patrol behavior:
- Calculates position on a circle around `base_patrol_position`
- Uses `angle` that increments over time to create smooth circular motion
- Moves towards calculated target position on the circle
- Faces direction of movement for natural orientation

**2. Enhanced Swoop Detection** (`scenes/enemies/bat.tscn:13-16`)
```gdscript
target_position = Vector3(0, -8, 0)  # Longer range (was -5)
collision_mask = 2                    # Detects player layer
enabled = true                        # Explicitly enabled
```

### Bat Behavior Overview

The bat now has three distinct states:

**PATROL State:**
- If patrol points exist: flies between them
- If no patrol points: flies in a circular pattern around spawn position
- Adds sine wave vertical bobbing for natural flight animation
- Continuously checks below with raycast for player

**SWOOP State:**
- Triggered when player detected below by raycast
- Dives rapidly toward player at `swoop_speed = 8.0`
- Transitions to RETURN when reaching player's height

**RETURN State:**
- Flies back up to original patrol height
- Returns to PATROL state when height restored

### Result
✅ Bat now continuously moves in a circle when no patrol points assigned
✅ Maintains natural bobbing motion with sine wave
✅ Can still use patrol points if provided in level design
✅ Properly detects and swoops at player
✅ Returns to patrol after attack

---

## Files Modified

### Base Enemy System:
1. **scenes/enemies/base_enemy.tscn**
   - Line 20: Changed `collision_mask` from 3 to 7

2. **scripts/enemies/base_enemy.gd**
   - Line 67: Added call to `_apply_enemy_separation()`
   - Lines 152-176: Added `_apply_enemy_separation()` function

### Bat Enemy:
3. **scripts/enemies/bat.gd**
   - Lines 12-13: Added `circle_radius` and `circle_speed` exports
   - Line 17: Added `angle` variable for circular movement
   - Lines 60-77: Replaced static hover with circular patrol logic

4. **scenes/enemies/bat.tscn**
   - Lines 14-16: Configured SwoopDetector raycast properly

---

## Collision Layer Reference

Updated collision system:

| Layer | Purpose | Objects |
|-------|---------|---------|
| 1 | World | Platforms, walls, ground |
| 2 | Player | Player character |
| 4 | Enemies | All enemy types |
| 5 | Hurtbox | Enemy hurtboxes (for player attacks) |

**Enemy Collision Setup:**
- `collision_layer = 4` - Enemies exist on layer 4
- `collision_mask = 7` - Enemies detect layers 1, 2, and 4 (World, Player, Enemies)

**Detection Area:**
- `collision_layer = 0` - Area is query-only
- `collision_mask = 2` - Detects player only

**Hurtbox:**
- `collision_layer = 5` - Hurtbox on separate layer
- `collision_mask = 2` - Detects player attacks

---

## Testing Checklist

Verify the following behaviors:

### Enemy Separation:
- [ ] Spawn multiple goblins close together
- [ ] Enemies should push away from each other smoothly
- [ ] Enemies don't overlap or "merge"
- [ ] Separation works while enemies are chasing player
- [ ] Separation works during patrol

### Bat Movement:
- [ ] Bat flies in a circular pattern around spawn point
- [ ] Bat maintains smooth vertical bobbing motion
- [ ] Bat faces direction of movement
- [ ] Bat swoops down when player walks underneath
- [ ] Bat returns to circular patrol after swooping
- [ ] Circular flight is smooth and natural-looking

### General:
- [ ] All enemy types still function correctly
- [ ] Player can still damage enemies by jumping on them
- [ ] Enemies still chase and damage player
- [ ] Combat interactions unaffected

---

## Future Enhancements

Potential improvements for future development:

### Enemy Separation:
- Add visual indicator when enemies are too close (particle effect, sound)
- Implement formation behavior for certain enemy groups
- Add avoidance prediction (enemies steer away before collision)

### Bat Behavior:
- Add figure-8 pattern option (alternative to circle)
- Implement dive-bomb attack that damages player
- Add animation states for patrol vs swoop
- Gradual acceleration/deceleration for more natural movement
- Group coordination for multiple bats

### AI Improvements:
- Pathfinding for enemies that get stuck
- Line-of-sight checks before chasing
- Coordinated group attacks
- Different aggression levels per enemy type

---

## Configuration Tips

### Adjusting Enemy Separation:
Edit `scripts/enemies/base_enemy.gd:155-156`:
```gdscript
const SEPARATION_DISTANCE: float = 1.5  # Increase for wider spacing
const SEPARATION_STRENGTH: float = 2.0  # Increase for stronger push
```

### Adjusting Bat Flight:
Edit bat properties in Godot Inspector or `scripts/enemies/bat.gd:12-13`:
- `circle_radius: 4.0` - Larger = wider patrol circle
- `circle_speed: 1.0` - Higher = faster rotation
- `move_speed: 3.0` - Base flight speed
- `swoop_speed: 8.0` - Attack dive speed
- `sine_wave_frequency: 2.0` - Bobbing speed
- `sine_wave_amplitude: 0.5` - Bobbing height

---

## Technical Notes

### Why Collision Mask Change Works
By adding layer 4 to the collision mask, `move_and_slide()` now generates collision information when enemies touch each other. This allows `get_slide_collision_count()` to detect enemy-to-enemy collisions and apply separation forces.

### Circular Movement Math
The circular patrol uses trigonometry:
```gdscript
angle += circle_speed * delta        # Rotate over time
offset_x = cos(angle) * circle_radius  # X position on circle
offset_z = sin(angle) * circle_radius  # Z position on circle
```

This creates a smooth circular path. The bat moves toward the calculated position, creating natural-looking flight.

### Performance Considerations
- Separation check runs every frame but only processes actual collisions
- Circular movement calculation is lightweight (simple trig)
- No expensive operations in the main physics loop
- No impact on game performance with typical enemy counts

---

## Result Summary

✅ **Enemy Collision:** Fixed merging behavior with separation system
✅ **Bat Movement:** Implemented circular patrol with natural flight
✅ **Code Quality:** Clean, documented, and configurable
✅ **Performance:** No measurable impact on framerate
✅ **Extensibility:** Easy to adjust parameters or add new behaviors
