# Collision Debugging Guide for Godot 4.5

## Problem
Character floating above ground or sinking into platforms due to misaligned collision shapes.

## Systematic Debugging Approach

### Step 1: Enable Visual Debugging

**In Godot Editor:**
1. Run the game (F5)
2. Go to **Debug** menu → **Visible Collision Shapes**
   - OR click the collision shapes visibility icon in the toolbar
3. You'll see wireframe boxes/capsules overlaid on your 3D models
4. **Compare visual model surfaces with collision wireframes**

### Step 2: Check Console Output

The `collision_debugger.gd` script prints detailed information:

```
========== COLLISION DEBUG INFO ==========

--- PLAYER ---
Player world position: (0, 2, 0)
Capsule bottom (world): 0
Capsule top (world): 2

--- Platform1 ---
Visual top (world): 1.5
Collision top (world): 1.75
```

**Look for:**
- Mismatches between visual top and collision top
- Character capsule bottom not matching surface tops
- Model AABB sizes and positions

### Step 3: Understanding Coordinates

**Local vs World Coordinates:**
- **Local position**: Relative to parent node
- **World position**: Absolute position in 3D space
- Formula: `world_pos = parent_world_pos + local_pos`

**Example:**
```
Platform1 world pos: (5, 1, 0)
CollisionShape local pos: (0, 0.5, 0)
CollisionShape world pos: (5, 1.5, 0)
```

### Step 4: Calculate Collision Bounds

**For BoxShape3D (platforms):**
```gdscript
# Given:
box_size = Vector3(4, 0.5, 4)  # width, height, depth
box_world_pos = Vector3(5, 1.5, 0)

# Calculate:
bottom_y = box_world_pos.y - (box_size.y / 2)  # 1.5 - 0.25 = 1.25
top_y = box_world_pos.y + (box_size.y / 2)     # 1.5 + 0.25 = 1.75
```

**For CapsuleShape3D (player):**
```gdscript
# Given:
capsule_height = 2.0
capsule_world_pos = Vector3(0, 1, 0)

# Calculate:
bottom_y = capsule_world_pos.y - (capsule_height / 2)  # 1 - 1 = 0
top_y = capsule_world_pos.y + (capsule_height / 2)     # 1 + 1 = 2
```

### Step 5: Calculate Visual Model Bounds

**For scaled models:**
```gdscript
# Given:
model_local_pos = Vector3(0, 0.25, 0)
model_scale = Vector3(2, 0.5, 2)
mesh_aabb_size = Vector3(2, 2, 2)  # Original mesh size
mesh_aabb_center = Vector3(0, 0, 0)  # Usually at origin
parent_world_pos = Vector3(5, 1, 0)

# Calculate visual bounds:
model_world_pos = parent_world_pos + model_local_pos
# = (5, 1, 0) + (0, 0.25, 0) = (5, 1.25, 0)

scaled_height = mesh_aabb_size.y * model_scale.y
# = 2 * 0.5 = 1.0

visual_bottom_y = model_world_pos.y + (mesh_aabb_center.y - mesh_aabb_size.y / 2) * model_scale.y
# = 1.25 + (0 - 1) * 0.5 = 1.25 - 0.5 = 0.75

visual_top_y = model_world_pos.y + (mesh_aabb_center.y + mesh_aabb_size.y / 2) * model_scale.y
# = 1.25 + (0 + 1) * 0.5 = 1.25 + 0.5 = 1.75
```

### Step 6: Alignment Requirements

**For proper collision:**
1. **Platform collision top MUST equal visual top**
   - `collision_top_y == visual_top_y`

2. **Character capsule bottom MUST touch surface**
   - When `is_on_floor()` is true: `capsule_bottom_y == surface_top_y`

3. **Common mistakes:**
   - Collision box too thin (e.g., 0.1 instead of 0.5)
   - Collision position doesn't account for parent transform
   - Model origin at center but treating it as bottom
   - Forgetting to apply scale to calculations

## Practical Testing Method

### Test 1: Simple Shapes First

Before using imported models, test with basic shapes:

1. Create a test scene with:
   - StaticBody3D with BoxShape3D (4x1x4) at world Y=0
   - CharacterBody3D with CapsuleShape3D (height=2) spawned at Y=5

2. The character should:
   - Fall due to gravity
   - Stop at Y=1 (capsule bottom at Y=0, top at Y=2)
   - `is_on_floor()` returns true

3. If this doesn't work, there's a fundamental physics issue

### Test 2: Add Visual Mesh

1. Add CSGBox3D to StaticBody3D:
   - Size: (4, 1, 4)
   - Position: (0, 0, 0)

2. Visual and collision should align perfectly
3. Character should appear to stand ON the box, not in it

### Test 3: Add Imported Model

1. Replace CSGBox3D with imported GLTF model
2. Check model's AABB in inspector
3. Adjust collision shape to match AABB size
4. Adjust collision position to match AABB center

## Quick Fix Checklist

**If character floats above ground:**
- [ ] Collision shape is too low
- [ ] Increase collision Y position
- [ ] Check ground collision top matches visual top

**If character sinks into platforms:**
- [ ] Collision shape is too thin or too low
- [ ] Increase collision box height
- [ ] Increase collision Y position
- [ ] Verify visual top and collision top match

**If character falls through floor:**
- [ ] Collision layers/masks incorrect
- [ ] Collision shape not set
- [ ] Physics material issue (check for infinite slide)

## Formula Reference Card

```
BOX COLLISION (centered):
  bottom_y = position_y - (size_y / 2)
  top_y = position_y + (size_y / 2)

CAPSULE COLLISION (centered):
  bottom_y = position_y - (height / 2)
  top_y = position_y + (height / 2)

WORLD POSITION:
  world_y = parent_world_y + local_y

SCALED MODEL BOUNDS:
  scaled_size_y = original_size_y * scale_y
  bottom_y = center_y - (scaled_size_y / 2)
  top_y = center_y + (scaled_size_y / 2)

CORRECT ALIGNMENT:
  collision_top_y == visual_top_y
  character_bottom_y == surface_top_y (when on floor)
```

## Using the Debug Script

1. The `collision_debugger.gd` is attached to MainLevel
2. Run the game and check the console output
3. Compare collision tops vs visual tops
4. Adjust positions until they match
5. Verify character lands correctly

## Next Steps After Debugging

1. **Record measurements** from debug output
2. **Calculate required positions** using formulas above
3. **Update scene file** with correct values
4. **Test in-game** with visible collision shapes
5. **Verify** character stands on surfaces correctly
6. **Remove or disable** debug script when done
