# Collision System Guide

## Overview

This document explains the collision system architecture, validation framework, and how to use the constants system for maintaining consistent collision shapes.

## Architecture

### GameConstants (scripts/game_constants.gd)

Centralized location for all measurements and magic numbers. This file serves as the single source of truth for:
- Model dimensions (measured from GLTF files)
- Common scale configurations
- Collision shape sizes
- Positioning offsets
- Validation tolerances

**Key Benefits:**
- No more magic numbers scattered in scene files
- Easy to adjust globally
- Self-documenting code
- Foundation for automated platform builder tool

### CollisionDebugger (scripts/collision_debugger.gd)

Development tool that validates collision alignment at runtime.

**Features:**
- Prints detailed collision information
- Validates alignment between visual models and collision shapes
- Configurable strictness (warnings vs errors)
- Can halt execution on errors (strict mode)

## Current Configuration

### Platform Standard Setup

**Visual Model:**
- Base size: 2×2×2 units (Quaternius cube)
- Scale: (2.0, 0.5, 2.0)
- Position Y offset: 0.25
- **Resulting visual size:** ~4.47×1.0×4.47 units

**Collision Shape:**
- Type: BoxShape3D
- Size: (4.5, 1.0, 4.5) units
- Position Y offset: 0.25 (matches model)

**Why 4.5 instead of 4.0?**
The actual mesh AABB is (2.233, 1.996, 2.233), not (2.0, 2.0, 2.0).
When scaled by 2.0, this becomes 4.466 ≈ 4.5 units.

### Ground Setup

**Visual Model:**
- 9 tiles in 3×3 grid
- Each tile: 2×2×2 base, scaled (5.0, 0.5, 5.0)
- Each tile size: 10×1×10 units
- **Total coverage:** 30×1×30 units

**Collision Shape:**
- Type: BoxShape3D
- Size: (30.0, 1.0, 30.0) units
- Position Y offset: 0.25

### Player Setup

**Visual Model:**
- Character model at Y=0 (feet at origin)
- Scaled: 0.8

**Collision Shape:**
- Type: CapsuleShape3D
- Radius: 0.5 units
- Height: 2.0 units
- Center at Y=1.0
- **Capsule spans:** Y=0 to Y=2

## Using the Validation System

### Basic Usage

The collision debugger runs automatically in every level. Look for the validation report in the console output:

```
========== VALIDATION REPORT ==========
✓ All validation checks passed!
==========================================
```

Or if there are issues:

```
========== VALIDATION REPORT ==========
✗ Found 2 validation ERROR(S)
⚠ Found 1 validation WARNING(S)
==========================================
```

### Validation Levels

**WARNINGS (Yellow):**
- Dimensions slightly off from constants
- Non-critical misalignments
- Won't break gameplay but should be reviewed
- Example: Platform Y offset is 0.26 instead of 0.25

**ERRORS (Red):**
- Visual and collision bounds don't align
- Missing collision shapes
- Wrong collision shape types
- Will cause gameplay issues (falling through platforms, etc.)
- Example: Collision bottom at Y=1.0, visual bottom at Y=0.75

### Configuration Options

In the CollisionDebugger node (Inspector):

**Debug Options:**
- `debug_player`: Print player collision info
- `debug_platforms`: Print platform collision info
- `debug_ground`: Print ground collision info
- `enable_validation`: Run validation checks
- `strict_mode`: Assert/halt on validation errors

**Recommended Settings:**
- **Development:** All debug ON, validation ON, strict mode OFF
- **Testing:** Debug OFF, validation ON, strict mode ON
- **Production:** All OFF (remove CollisionDebugger node)

## Creating New Platforms

### Method 1: Manual (Current)

1. Add StaticBody3D node
2. Add PlatformModel child (instance Cube_Grass_Single.gltf)
3. Add CollisionShape3D child with BoxShape3D
4. Set transforms:
   ```
   PlatformModel:
     Scale: (2.0, 0.5, 2.0)
     Position: (0, 0.25, 0)

   CollisionShape3D:
     Shape Size: (4.5, 1.0, 4.5)
     Position: (0, 0.25, 0)
   ```
5. Run level and check validation report

### Method 2: Using Constants (Recommended)

Use the helper functions in GameConstants:

```gdscript
# In a script or tool script
var model_scale = Vector3(2, 0.5, 2)
var collision_size = GameConstants.calculate_platform_collision_size(model_scale)
var collision_pos = GameConstants.calculate_platform_collision_position(model_scale)

print("Collision should be: ", collision_size)
print("At position: ", collision_pos)
```

### Method 3: Platform Builder Tool (Future)

Planned tool that will:
1. Place visual model
2. Auto-calculate collision from model
3. Validate alignment
4. Save scene with correct values

**Coming in future update!**

## Common Issues & Solutions

### Issue: Player falls through platform

**Symptoms:**
- Player doesn't land on platform
- Passes through without collision

**Causes:**
- Collision shape too small
- Collision shape positioned below visual
- Wrong collision layer/mask

**Solution:**
1. Check validation report for errors
2. Compare collision bounds to visual bounds in debug output
3. Ensure collision Y position matches model Y position
4. Verify collision size includes mesh extents

### Issue: Player stuck under platform

**Symptoms:**
- Player's head touches platform from below
- Can't jump past platform edge

**Causes:**
- Collision shape too tall
- Collision extends above visual

**Solution:**
1. Check collision top vs visual top in debug output
2. Reduce collision height to match visual
3. Ensure Y offset is correct

### Issue: Player appears to "float" above platform

**Symptoms:**
- Gap between player feet and platform surface
- Looks like hovering

**Causes:**
- Collision positioned too high
- Collision top doesn't match visual top

**Solution:**
1. Check collision top in validation report
2. Adjust collision Y position downward
3. Ensure collision height matches visual height

## Camera Positioning

### Camera Offset Guidelines

Camera offset should be set based on maximum platform height:

```gdscript
# Level 1 - max platform Y=3
camera.offset = GameConstants.CAMERA_OFFSET_EASY  # (0, 5, 8)

# Level 2 - max platform Y=4.5
camera.offset = GameConstants.CAMERA_OFFSET_MEDIUM  # (0, 6, 10)

# Level 3 - max platform Y=8
camera.offset = GameConstants.CAMERA_OFFSET_HARD  # (0, 8, 12)
```

**Rule of thumb:**
- Camera Y should be ~2 units above highest collectible
- Camera Z should be (Camera Y) + 2-4 units back
- This ensures full level visibility

### Setting Camera Offset

The camera follow script has an `offset` export parameter:

```gdscript
# In level scene file (.tscn)
[node name="Camera3D" type="Camera3D" parent="."]
script = ExtResource("camera_follow")
offset = Vector3(0, 6, 10)  # Override default (0, 5, 8)
```

## Best Practices

### DO:
✅ Use constants from GameConstants whenever possible
✅ Run validation after modifying collision shapes
✅ Check validation report before committing level changes
✅ Keep collision and visual Y offsets identical
✅ Document any deviations from standard platform sizes

### DON'T:
❌ Hardcode magic numbers in scene files
❌ Disable validation in development
❌ Ignore validation warnings (they become errors later)
❌ Modify collision without updating visual (or vice versa)
❌ Create collision shapes by eye-balling

## Future Improvements

### Planned Features

1. **Platform Builder Tool**
   - Editor plugin or script tool
   - Auto-generates collision from visual
   - Validates before saving
   - Presets for common configurations

2. **Automated Tests**
   - Unit tests for constant calculations
   - Integration tests for level loading
   - Regression tests for collision alignment

3. **Resource-Based Platforms**
   - PlatformPreset resource type
   - Instantiate platforms from presets
   - Guarantees consistency

4. **Visual Debug Rendering**
   - Draw collision shapes in-game
   - Color-coded validation status
   - Toggle with hotkey

## Reference

### Important Files

- `scripts/game_constants.gd` - All constants and helper functions
- `scripts/collision_debugger.gd` - Validation and debug tool
- `COLLISION_DEBUG_GUIDE.md` - Original debug documentation
- `MULTI_LEVEL_SYSTEM.md` - Level architecture overview

### Key Constants

```gdscript
# Platform
GameConstants.PLATFORM_SCALE_STANDARD = Vector3(2, 0.5, 2)
GameConstants.PLATFORM_COLLISION_SIZE_STANDARD = Vector3(4.5, 1, 4.5)
GameConstants.PLATFORM_MODEL_Y_OFFSET = 0.25

# Ground
GameConstants.GROUND_COLLISION_SIZE = Vector3(30, 1, 30)
GameConstants.GROUND_COLLISION_Y_OFFSET = 0.25

# Validation
GameConstants.POSITION_TOLERANCE = 0.1
GameConstants.SIZE_TOLERANCE = 0.2
```

### Helper Functions

```gdscript
# Calculate collision size from model scale
GameConstants.calculate_platform_collision_size(scale: Vector3) -> Vector3

# Calculate collision position from model scale
GameConstants.calculate_platform_collision_position(scale: Vector3) -> Vector3

# Get camera offset for level difficulty
GameConstants.get_camera_offset_for_difficulty(difficulty: int) -> Vector3

# Validate position/size matches
GameConstants.positions_match(pos1: Vector3, pos2: Vector3) -> bool
GameConstants.sizes_match(size1: Vector3, size2: Vector3) -> bool
```

## Troubleshooting

If validation fails:

1. **Read the error message** - it tells you exactly what's wrong
2. **Check the debug output** - see actual vs expected values
3. **Compare to constants** - are you using the right values?
4. **Use helper functions** - calculate instead of guessing
5. **Enable strict mode** - halt on first error for debugging

If stuck, check:
- Is the model scaled correctly?
- Is the collision size matching the scaled model?
- Are both at the same Y offset?
- Is the collision layer/mask correct?

## Questions?

The collision system is designed to be self-validating. If something doesn't work:
1. Check the validation report
2. Compare to this guide
3. Use the constants and helper functions
4. The tool will tell you what's wrong!
