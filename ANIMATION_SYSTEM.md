# Character Animation System Documentation

## Overview

The character uses an **AnimationTree with State Machine** for smooth, responsive animations. All animations are built into the Quaternius Character.gltf model and controlled via code.

## Architecture

### Component Structure

```
Player (CharacterBody3D)
  ├─ CharacterModel (GLTF Instance)
  │    ├─ AnimationPlayer (auto-generated from GLTF)
  │    └─ AnimationTree (manually added)
  │         └─ State Machine (root node)
  │              ├─ Idle state
  │              ├─ Walk state
  │              ├─ Jump state
  │              ├─ Airborne state
  │              └─ Land state
  └─ CollisionShape3D
```

### Animation Flow

```
Idle ⇄ Walk (0.2s blend)
  ↓
Jump (0.1s blend)
  ↓
Airborne (0.15s blend, auto-transition)
  ↓
Land (0.1s blend, on ground contact)
  ↓
Idle (0.15s blend, auto after animation completes)
```

## Available Animations

The Character.gltf model includes **18 animations**:

### Currently Used:
- **Idle** - Standing still, looking around
- **Walk** - Walking animation
- **Jump** - Jump takeoff
- **Jump_Idle** - Airborne pose (mid-air)
- **Jump_Land** - Landing animation

### Available for Future Use:
- Run - Faster movement animation
- Death - Death animation
- HitReact - Taking damage
- Duck - Crouching
- Punch - Melee attack
- Wave, Yes, No - Emotive animations
- Idle_Gun, Walk_Gun, Run_Gun, Run_Shoot, Idle_Shoot - With weapon

## State Machine

### States

**1. Idle**
- Plays: "Idle" animation
- Triggered: When not moving and on ground
- Transitions to: Walk, Jump

**2. Walk**
- Plays: "Walk" animation
- Triggered: When moving and on ground
- Transitions to: Idle, Jump

**3. Jump**
- Plays: "Jump" animation
- Triggered: When leaving ground (upward velocity)
- Auto-transitions: To Airborne after animation
- Blend time: 0.1s (fast, responsive feel)

**4. Airborne**
- Plays: "Jump_Idle" animation (looping)
- Triggered: Automatically after Jump completes
- Stays: While in air
- Transitions to: Land (when touches ground)

**5. Land**
- Plays: "Jump_Land" animation
- Triggered: When touching ground after being airborne
- Auto-transitions: To Idle after animation completes
- Blend time: 0.15s

### Conditions

The state machine uses these boolean conditions (set by player.gd):

```gdscript
parameters/conditions/is_moving     # True when horizontal velocity > 0.1
parameters/conditions/is_idle       # True when not moving
parameters/conditions/is_jumping    # True when airborne with upward velocity
parameters/conditions/has_landed    # True for one frame when landing
```

### Transition Timings

**Blend Times:**
- Idle ↔ Walk: 0.2s (smooth, natural)
- To Jump: 0.1s (responsive, snappy)
- Jump → Airborne: 0.15s
- Airborne → Land: 0.1s
- Land → Idle: 0.15s

**Rationale:**
- Fast transitions for jumps (responsive gameplay)
- Slower transitions for walk/idle (smooth, natural)
- Auto-transitions use switch_mode = 2 (at end of animation)

## Code Integration

### Player Script (scripts/player.gd)

**References:**
```gdscript
@onready var animation_tree: AnimationTree = $CharacterModel/AnimationTree
var was_on_floor: bool = true  # Track landing
```

**Animation Update:**
```gdscript
func update_animation() -> void:
    # Determine state
    var horizontal_velocity := Vector2(velocity.x, velocity.z)
    var is_moving := horizontal_velocity.length() > 0.1
    var is_grounded := is_on_floor()
    var is_jumping := not is_grounded and velocity.y > 0
    var just_landed := is_grounded and not was_on_floor

    # Set conditions
    animation_tree.set("parameters/conditions/is_moving", is_moving)
    animation_tree.set("parameters/conditions/is_idle", not is_moving)
    animation_tree.set("parameters/conditions/is_jumping", is_jumping)
    animation_tree.set("parameters/conditions/has_landed", just_landed)

    # Update tracking
    was_on_floor = is_grounded
```

Called every frame in `_physics_process()` after `move_and_slide()`.

### Why After move_and_slide()?

The animation system needs accurate `is_on_floor()` and `velocity` values, which are only correct after physics calculations complete.

## Tuning Guide

### Adjusting Responsiveness

**Make animations more responsive (snappier):**
- Decrease xfade_time values (e.g., 0.1 → 0.05)
- Good for: Action games, fast-paced gameplay

**Make animations smoother (more natural):**
- Increase xfade_time values (e.g., 0.2 → 0.3)
- Good for: Cinematic feel, slower-paced games

### Current Tuning Philosophy

**Responsive jumps + Smooth movement**
- Jump transitions: Fast (0.1s) for tight controls
- Walk/Idle transitions: Moderate (0.2s) for natural feel
- Land transitions: Medium (0.15s) balancing both

### Testing Different Animations

To test other animations (e.g., Run instead of Walk):

1. Open `scenes/player/player.tscn`
2. Find `[sub_resource type="AnimationNodeAnimation" id="AnimationNodeAnimation_walk"]`
3. Change `animation = &"Walk"` to `animation = &"Run"`
4. Adjust movement speed in player.gd to match

## Common Adjustments

### Add Run Animation (Speed-Based)

**Option 1: Replace Walk with Run**
```gdscript
# In state machine, change Walk node animation to "Run"
```

**Option 2: Add Separate Run State (Future Enhancement)**
- Add Run state to state machine
- Transition: Walk → Run when speed > threshold
- Requires: Speed parameter in state machine

### Add Death Animation

**When player dies:**
```gdscript
func die() -> void:
    # Play death animation
    animation_tree.set("parameters/conditions/is_dead", true)
    # Wait for animation
    await get_tree().create_timer(1.0).timeout
    # Then game over
    GameManager.trigger_game_over()
```

**State machine:**
- Add Death state with "Death" animation
- Add transition from any state to Death
- Condition: `is_dead`

### Celebration on Level Complete

```gdscript
func celebrate() -> void:
    animation_tree.set("parameters/conditions/is_celebrating", true)
```

Add state for "Wave" or "Yes" animation.

## Troubleshooting

### Animation Not Playing

**Check:**
1. AnimationTree is `active = true`
2. AnimationPlayer path is correct: `NodePath("../AnimationPlayer")` (sibling reference)
3. Animation names match GLTF exactly (case-sensitive)
4. Conditions are being set in update_animation()

**Debug:**
```gdscript
print(animation_tree.get("parameters/playback").get_current_node())
```

### Wrong Animation Playing

**Check:**
1. Condition logic in update_animation()
2. Transition priorities (earlier transitions take precedence)
3. Auto-transitions might be activating

**Debug:**
```gdscript
print("Moving: ", is_moving, " Jumping: ", is_jumping, " Grounded: ", is_grounded)
```

### Animations Not Blending Smoothly

**Solutions:**
1. Increase xfade_time values
2. Check that animations have similar poses at start/end
3. Use AnimationTree blend space for complex blending

### Character Facing Wrong Direction

The character model rotates with the player automatically via:
```gdscript
rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
```

This rotates the entire Player node, including CharacterModel.

## Performance Notes

- AnimationTree is very efficient
- All 18 animations loaded in memory (~minimal impact)
- State machine has near-zero overhead
- No performance concerns for this setup

## Future Enhancements

### Planned Features

1. **Run Animation**
   - Speed-based transition: Walk → Run
   - Separate state or speed-scaled Walk

2. **Combat Animations**
   - Punch animation on attack input
   - HitReact on taking damage

3. **Emotive Animations**
   - Wave on level start
   - Celebration (Yes) on level complete
   - Death on fall

4. **Advanced Blending**
   - Blend walk direction with aim direction
   - Upper body / lower body split
   - Procedural head look-at

### Easy Additions

**Add an animation in 3 steps:**

1. **Add state to AnimationTree**
```gdscript
# In .tscn file, add new AnimationNodeAnimation
[sub_resource type="AnimationNodeAnimation" id="AnimationNodeAnimation_wave"]
animation = &"Wave"
```

2. **Add to state machine**
```gdscript
# Add state and transitions in StateMachine
states/Wave/node = SubResource("AnimationNodeAnimation_wave")
```

3. **Trigger from code**
```gdscript
animation_tree.set("parameters/conditions/is_waving", true)
```

## Best Practices

### DO:
✅ Use conditions for automatic transitions
✅ Keep blend times short for responsive gameplay
✅ Test all state transitions
✅ Use descriptive state names
✅ Document animation timing decisions

### DON'T:
❌ Call animation_tree.set() every frame for same value
❌ Mix AnimationPlayer.play() with AnimationTree
❌ Create too many states (keep it simple)
❌ Use very long blend times (>0.5s)
❌ Forget to reset one-shot conditions

## Animation Reference

### Full Animation List

```
Animation Name    | Duration | Loop  | Use Case
------------------|----------|-------|---------------------------
Idle              | 2.0s     | Yes   | Standing still
Walk              | 1.0s     | Yes   | Normal movement
Run               | 0.8s     | Yes   | Fast movement
Jump              | 0.4s     | No    | Jump start
Jump_Idle         | 1.0s     | Yes   | In air
Jump_Land         | 0.3s     | No    | Landing
Death             | 2.0s     | No    | Player dies
HitReact          | 0.5s     | No    | Taking damage
Duck              | 1.5s     | Yes   | Crouching
Punch             | 0.6s     | No    | Melee attack
Wave              | 1.5s     | No    | Greeting/celebration
Yes               | 1.0s     | No    | Positive emote
No                | 1.0s     | No    | Negative emote
Idle_Gun          | 2.0s     | Yes   | Idle with weapon
Walk_Gun          | 1.0s     | Yes   | Walking with weapon
Run_Gun           | 0.8s     | Yes   | Running with weapon
Idle_Shoot        | 1.5s     | Yes   | Shooting while standing
Run_Shoot         | 1.0s     | Yes   | Shooting while running
```

*Note: Durations are approximate. Check in AnimationPlayer for exact values.*

## Resources

- Godot AnimationTree docs: https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- Quaternius asset pack: https://quaternius.com/packs/platformerpack.html

## Summary

The animation system provides:
- ✅ Smooth animation blending
- ✅ Responsive controls
- ✅ Easy to extend
- ✅ Production-quality feel
- ✅ Minimal code complexity
- ✅ 18 animations ready to use

The character now feels alive and responsive to player input!
