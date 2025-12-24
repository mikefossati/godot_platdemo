# Treasure Chest Animation Fix

## Issue
The treasure chests were appearing with lids already open, and when interacted with, the entire chest would rotate backward instead of just the lid opening.

## Root Cause
The script was rotating the entire `chest_model` node instead of using the built-in animations that come with the GLTF model.

## Solution

### Built-in Animations Discovered
The Chest.gltf model includes two animations:
- **"Chest_Close"** - Closes the chest lid
- **"Chest_Open"** - Opens the chest lid

These animations properly animate the armature bones (`Chest_Top` and `Chest_Bottom`) rather than rotating the entire model.

### Changes Made

1. **Added AnimationPlayer Reference**
   ```gdscript
   @onready var animation_player: AnimationPlayer = $ChestModel/AnimationPlayer
   ```

2. **Initialize Closed State**
   ```gdscript
   # In _ready()
   if animation_player and animation_player.has_animation("Chest_Close"):
       animation_player.play("Chest_Close")
       animation_player.seek(0.0, true)  # Fully closed position
   ```

3. **Use Proper Open Animation**
   ```gdscript
   # In _play_open_animation()
   if animation_player and animation_player.has_animation("Chest_Open"):
       animation_player.play("Chest_Open")
   else:
       # Fallback to old rotation method if needed
   ```

4. **Handle Already-Opened State**
   ```gdscript
   # In _check_persistence()
   if is_opened:
       if animation_player and animation_player.has_animation("Chest_Open"):
           animation_player.play("Chest_Open")
           animation_player.seek(animation_player.current_animation_length, true)
   ```

## How It Works Now

### Initial State (Closed)
1. Chest spawns
2. Plays "Chest_Close" animation
3. Seeks to frame 0 (fully closed)
4. Lid is down, chest looks closed

### Opening Sequence
1. Player approaches chest
2. "Press E to open" prompt appears
3. Player presses E
4. "Chest_Open" animation plays
5. Lid smoothly opens upward
6. Coins spawn from chest
7. State saved as opened

### Already Opened (Persistence)
1. Chest spawns
2. Checks if previously opened
3. If yes: Plays "Chest_Open" and seeks to end
4. Chest appears with lid already open
5. No interaction prompt shown

## Fallback Behavior
If the AnimationPlayer or animations aren't found:
- Falls back to the old rotation method
- Rotates entire chest_model -60 degrees on X axis
- Still functional but less polished

## Model Structure
```
ChestModel (GLTF Instance)
├── AnimationPlayer
│   ├── Chest_Close (animation)
│   └── Chest_Open (animation)
└── Chest_Armature
    ├── Chest_Bottom (base)
    └── Chest_Top (lid)
```

## Benefits
- ✅ Proper lid-only animation
- ✅ Smooth open/close transitions
- ✅ Uses built-in GLTF animations
- ✅ Maintains fallback for compatibility
- ✅ Clear visual feedback
- ✅ Professional appearance

## Testing Checklist
- [ ] Chest starts fully closed
- [ ] Lid opens smoothly when E is pressed
- [ ] Only the lid moves (not entire chest)
- [ ] Coins spawn correctly
- [ ] Opened state persists across level reloads
- [ ] Previously opened chests appear open
- [ ] No rotation issues
- [ ] Animation plays at correct speed
