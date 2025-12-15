# Multi-Level System Implementation

## Overview

The game now supports multiple levels with progression tracking, save/load functionality, and a level select screen.

## Features Implemented

### 1. Level Management System
- **LevelData Resource Class** (`scripts/resources/level_data.gd`)
  - Defines metadata for each level (name, difficulty, scene path, etc.)
  - Allows easy addition of new levels

- **Level Registry** (in GameManager)
  - Centralized list of all available levels
  - Currently includes 3 levels:
    - **Level 1 "First Steps"**: Tutorial/Easy (5 collectibles, 4 platforms)
    - **Level 2 "Rising Challenge"**: Medium (7 collectibles, 6 platforms)
    - **Level 3 "Sky High"**: Hard (9 collectibles, 8 platforms)

### 2. Progression System
- **Unlock Mechanism**
  - Linear progression: completing a level unlocks the next
  - Level 1 unlocked by default
  - Progress persists across game sessions

- **Statistics Tracking** (per level)
  - Completion status
  - Best score
  - Times played

### 3. Save/Load System
- Uses Godot's `ConfigFile` for persistence
- Saved to `user://game_save.cfg`
- Stores:
  - Unlocked levels array
  - Level statistics dictionary
  - Metadata (version, last played timestamp)
- Auto-saves after completing each level

### 4. User Interface

#### Level Select Screen
- Grid display of all available levels
- Visual indicators:
  - **Locked levels**: Grayed out with 🔒 icon
  - **Unlocked levels**: "Start Level" button
  - **Completed levels**: Green tint + best score display
- Difficulty shown as star rating (★ ★ ★)
- Back to Main Menu button

#### Level Complete Screen
- Shows level name and completion message
- Displays final score and collectibles gathered
- Dynamic button options:
  - **Next Level**: Appears if there's a next level (auto-focused)
  - **Replay Level**: Restart current level
  - **Level Select**: Return to level select screen
- No "Next Level" button on final level

### 5. Game Flow

```
Main Menu
    ↓ [Play]
Level Select
    ↓ [Select Level]
Level Gameplay
    ↓ [Collect All Stars]
Level Complete
    ↓ [Next Level / Replay / Level Select]
Level Select (or next level)
```

## File Structure

```
scenes/
  levels/
    level_1.tscn          # Tutorial (formerly main_level.tscn)
    level_2.tscn          # Medium difficulty
    level_3.tscn          # Hard difficulty
  ui/
    level_select.tscn     # Level selection screen
    level_complete.tscn   # Updated with progression buttons

scripts/
  resources/
    level_data.gd         # LevelData resource class
  game_manager.gd         # Extended with level management
  level_select.gd         # Level select screen logic
  level_complete.gd       # Updated completion screen
```

## How to Add New Levels

### Method 1: Code-based (Current Approach)

1. **Create the level scene**
   - Duplicate an existing level (e.g., `level_1.tscn`)
   - Rename to `level_4.tscn`
   - Modify platform positions and collectibles
   - Change background color if desired

2. **Register in GameManager**
   - Open `scripts/game_manager.gd`
   - Add new level definition in `_initialize_levels()`:
   ```gdscript
   var level_4 = LevelData.new(
       "level_4",
       "Expert Trial",
       "res://scenes/levels/level_4.tscn",
       4,  # difficulty
       "Ultimate platforming challenge.",
       "level_3",  # unlock requirement
       90.0  # par time
   )
   level_registry.append(level_4)
   ```

### Method 2: Resource-based (Future Enhancement)

Create `.tres` resource files for each level to avoid hardcoding in GameManager.

## Save File Location

- **Windows**: `%APPDATA%\Godot\app_userdata\3D Platformer Prototype\game_save.cfg`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/3D Platformer Prototype/game_save.cfg`
- **Linux**: `~/.local/share/godot/app_userdata/3D Platformer Prototype/game_save.cfg`

## Testing the System

1. **First Launch**: Only Level 1 should be unlocked
2. **Complete Level 1**: Level 2 unlocks
3. **Complete Level 2**: Level 3 unlocks
4. **Restart Game**: Progress should persist (levels remain unlocked)
5. **Replay Levels**: Can replay any unlocked level, best score updates

## Level Differences

### Level 1 - "First Steps" (Easy)
- 4 platforms at comfortable heights
- 5 collectibles
- Easy jumps
- Platform heights: 1-3 units
- Sky blue background

### Level 2 - "Rising Challenge" (Medium)
- 6 platforms with varied spacing
- 7 collectibles
- Some longer jumps required
- Platform heights: 1.5-4.5 units
- Slightly purple-tinted sky

### Level 3 - "Sky High" (Hard)
- 8 platforms with challenging gaps
- 9 collectibles
- Precision jumps needed
- Platform heights: 2-8 units
- Purple sky for dramatic effect

## API Reference

### GameManager Functions

```gdscript
# Load a level by index (0, 1, 2, etc.)
GameManager.load_level(level_index: int)

# Load a level by ID ("level_1", "level_2", etc.)
GameManager.load_level_by_id(level_id: String)

# Load the next level in sequence
GameManager.load_next_level()

# Check if a level is unlocked
GameManager.is_level_unlocked(level_id: String) -> bool

# Manually unlock a level (useful for cheats/debug)
GameManager.unlock_level(level_id: String)

# Save progress manually (auto-saves on level complete)
GameManager.save_game()

# Load saved progress manually (auto-loads on game start)
GameManager.load_game()

# Navigate to level select
GameManager.return_to_level_select()
```

### Signals

```gdscript
# Emitted when a level is unlocked
GameManager.level_unlocked(level_id: String)

# Emitted when level is completed
GameManager.level_complete
```

## Future Enhancements

### Potential Additions
1. **Time Trials**: Track completion time, compare to par time
2. **Star Rating System**: 3-star rating based on score/time/collectibles
3. **Leaderboards**: Local high scores per level
4. **Bonus Levels**: Secret unlockable levels
5. **World Map**: Visual hub for level selection
6. **Level Editor**: In-game level creation tool
7. **Challenge Mode**: Modifier options (low gravity, speed run, etc.)
8. **Achievements**: Cross-level goals

### Technical Improvements
1. Convert to `.tres` resource files for levels
2. Add level thumbnails/preview images
3. Transition animations between scenes
4. More detailed statistics (deaths, time played, etc.)
5. Cloud save support
6. Level sharing/export system

## Notes

- The collision debugger is included in all levels for development
- Camera position adjusts for Level 3 due to higher platforms
- Each level has slightly different ambient lighting/glow for variety
- Save file is human-readable ConfigFile format (could switch to JSON later)
