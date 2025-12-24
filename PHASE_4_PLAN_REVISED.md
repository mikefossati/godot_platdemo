# Phase 4: World 1 Production - REVISED Implementation Plan

**Date**: December 24, 2025
**Status**: ✅ Ready to Start
**Dependencies**: ✅ Phases 1-3 COMPLETE
**Duration**: 2 weeks

---

## ✅ Dependency Verification Complete

**All required systems are implemented:**
- ✅ Phase 1: Enhanced movement, double jump, dash, ground pound
- ✅ Phase 2: Health system, 5 enemy types, combat mechanics
- ✅ Phase 3: Full collectibles & economy system

**Existing Assets:**
- ✅ 5 sequential platforming levels (levels 1-5)
- ✅ 1 combat showcase level
- ✅ 1 Phase 3 collectibles showcase level
- ✅ All enemy types ready to place
- ✅ All collectibles ready to place

---

## Phase 4 Goal: Create World 1 "Grassland Plains"

### Strategy: Hybrid Approach (Enhance + Create)

**Repurpose existing levels 1-3 as World 1 core, create new bonus level**

**Why This Approach?**
- Existing levels 1-3 already provide good difficulty curve
- Can enhance them with enemies, collectibles, and theme
- Saves time vs building 4 levels from scratch
- Creates cohesive World 1 experience
- Levels 4-5 can move to World 2 later

---

## Implementation Plan

### New Systems Needed

#### System 1: World Map UI
**File**: `scenes/ui/world_map.tscn`, `scripts/ui/world_map.gd`

**Features**:
- Visual world representation
- Level nodes clickable
- Show lock status
- Show star/medal counts per level
- Smooth camera pan between levels
- World title display

```gdscript
# world_map.gd
extends Control

@export var world_id: String = "world_1"
@export var world_name: String = "Grassland Plains"

var level_nodes: Array[LevelNode] = []

func _ready() -> void:
    load_world_levels()
    update_level_states()

func load_world_levels() -> void:
    # Get all levels for this world from GameManager
    var world_levels = GameManager.get_world_levels(world_id)

    for level_data in world_levels:
        var level_node = create_level_node(level_data)
        level_nodes.append(level_node)

func create_level_node(level_data: LevelData) -> LevelNode:
    # Create visual node for level
    # Show: Level number, name, stars, lock status
    pass

func _on_level_node_clicked(level_id: String) -> void:
    if GameManager.is_level_unlocked(level_id):
        GameManager.load_level_by_id(level_id)
    else:
        show_locked_message()
```

#### System 2: Checkpoint System
**File**: `scenes/props/checkpoint.tscn`, `scripts/checkpoint.gd`

```gdscript
# checkpoint.gd
extends Area3D
class_name Checkpoint

@export var checkpoint_id: int = 0
var is_activated: bool = false

@onready var mesh: MeshInstance3D = $Mesh
@onready var particles: GPUParticles3D = $ActivationParticles
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    # Inactive color
    mesh.get_surface_override_material(0).albedo_color = Color(0.5, 0.5, 0.5)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player") and not is_activated:
        activate()

func activate() -> void:
    is_activated = true

    # Save checkpoint position
    if LevelSession:
        LevelSession.set_checkpoint(global_position)

    # Visual feedback
    mesh.get_surface_override_material(0).albedo_color = Color(0.2, 1.0, 0.2)
    particles.emitting = true
    light.light_energy = 2.0

    # Play sound
    print("Checkpoint %d activated!" % checkpoint_id)
```

#### System 3: Tutorial Sign System
**File**: `scenes/props/tutorial_sign.tscn`, `scripts/tutorial_sign.gd`

```gdscript
# tutorial_sign.gd
extends Node3D
class_name TutorialSign

@export_multiline var message_text: String = "Welcome!"
@export var auto_show: bool = true
@export var show_duration: float = 5.0

var player_in_range: bool = false
var message_shown: bool = false

@onready var detection_area: Area3D = $DetectionArea
@onready var sign_label: Label3D = $SignPost/Label3D
@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
    detection_area.body_entered.connect(_on_player_entered)
    detection_area.body_exited.connect(_on_player_exited)

    sign_label.visible = false
    prompt_label.text = "Press E to read" if not auto_show else ""
    prompt_label.visible = false

func _process(_delta: float) -> void:
    if player_in_range and not message_shown:
        if auto_show:
            show_message()
        elif Input.is_action_just_pressed("interact"):
            show_message()

func _on_player_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        player_in_range = true
        if not message_shown and not auto_show:
            prompt_label.visible = true

func _on_player_exited(body: Node3D) -> void:
    if body.is_in_group("player"):
        player_in_range = false
        prompt_label.visible = false

func show_message() -> void:
    message_shown = true
    sign_label.text = message_text
    sign_label.visible = true
    prompt_label.visible = false

    # Auto-hide after duration
    await get_tree().create_timer(show_duration).timeout
    sign_label.visible = false
```

#### System 4: LevelSession Checkpoint Support
**File**: `scripts/level_session.gd` (modify existing)

```gdscript
# Add to LevelSession autoload
var checkpoint_position: Vector3 = Vector3.ZERO
var has_checkpoint: bool = false

func set_checkpoint(position: Vector3) -> void:
    checkpoint_position = position
    has_checkpoint = true
    print("LevelSession: Checkpoint saved at %s" % position)

func respawn_at_checkpoint(player: Player) -> void:
    if has_checkpoint:
        player.global_position = checkpoint_position + Vector3(0, 1, 0)
        print("LevelSession: Respawning at checkpoint")
        return true
    return false

func clear_checkpoint() -> void:
    has_checkpoint = false
    checkpoint_position = Vector3.ZERO
```

---

## Level Enhancement Plan

### World 1-1: "First Steps" (Existing Level 1)
**Current State**: Basic platforming tutorial
**Enhancements Needed**:

**Add**:
- ✅ 3 tutorial signs:
  - "Use WASD to move, Space to jump!"
  - "Collect Crown Crystals to progress!"
  - "Jump on enemies to defeat them!"
- ✅ 1 checkpoint (midway through level)
- ✅ 2-3 Goblins (introduce enemy combat)
- ✅ 50 coins → 100 coins (add more coin trails)
- ✅ 1 treasure chest (10 coins)
- ✅ 1 heart pickup (before enemy section)
- ✅ 1 speed boost power-up (introduce mechanic)
- ✅ Grassland theme:
  - Change platform materials to grass-topped
  - Add tree models
  - Add flower decorations
  - Green/brown color palette

**Layout Updates**:
```
[Start] → [Tutorial Sign: Movement] → [Coin Trail] →
[Crystal 1] → [Checkpoint] → [Tutorial Sign: Enemies] →
[Goblin Enemy] → [Heart Pickup] → [Goblin x2] →
[Crystal 2] → [Hidden Chest] → [Power-up] →
[Moving Platform] → [Crystal 3] → [Goal]
```

**Time Targets**: Keep current (Gold 20s, Silver 30s, Bronze 45s)

---

### World 1-2: "Leaping Meadows" (Existing Level 2)
**Current State**: Medium platforming
**Enhancements Needed**:

**Add**:
- ✅ 2 checkpoints
- ✅ 5-6 Goblins (enemy encounters)
- ✅ 1 Armored Knight (introduce 2-hit enemy)
- ✅ Increase to 100 coins
- ✅ 1 treasure chest (hidden, 15 coins)
- ✅ 2 heart pickups (strategic placement)
- ✅ 2 power-ups (invincibility star, coin magnet)
- ✅ Spike hazards (add danger)
- ✅ Grassland theme elements

**Layout Updates**:
```
[Start] → [Linear moving platforms] → [Goblin encounter] →
[Checkpoint 1] → [Spike gauntlet + hearts] →
[Enemy group: 2 goblins] → [Crystal 1] →
[Hidden path → Chest] ← OR → [Main path] →
[Checkpoint 2] → [Armored Knight] → [Crystal 2] →
[Moving platform sequence] → [Crystal 3] → [Goal]
```

**Time Targets**: Increase (Gold 45s, Silver 60s, Bronze 90s) - more content

---

### World 1-3: "Crown Peak" (Existing Level 3)
**Current State**: Hard platforming
**Enhancements Needed**:

**Add**:
- ✅ 2 checkpoints
- ✅ 8 Goblins, 2 Armored Knights, 1 Cannon Turret
- ✅ Mini-boss encounter (3 enemies at once)
- ✅ Increase to 100 coins
- ✅ 2 treasure chests (1 hidden on hard path)
- ✅ 3 heart pickups
- ✅ 2 power-ups (double coins, speed boost)
- ✅ Path choice (easy vs hard)
- ✅ Vertical climbing section
- ✅ Grassland → mountaintop theme transition

**Layout Updates**:
```
[Start] → [Choice Point] →
    Easy Path: [More platforms, goblins] → [50 coins] → [Merge]
    Hard Path: [Precision jumps, chest] → [30 coins] → [Merge]
[Merge] → [Checkpoint 1] →
[Vertical section with knight] → [Crystal 1] →
[Checkpoint 2] → [Moving platforms + cannon] → [Crystal 2] →
[Mini-Boss Arena: 2 knights + 3 goblins] →
[Crystal 3] → [Goal]
```

**Time Targets**: Increase (Gold 90s, Silver 120s, Bronze 180s)

**Special**: On completion, show popup "Double Jump Unlocked!"
(Note: Player already has double jump from shop, but this is story unlock)

---

### World 1-Bonus: "Grassland Gauntlet" (NEW LEVEL)
**Build from scratch**
**Goal**: Extra-hard challenge for completionists

**Requirements**:
- Unlocked by: Collecting 6+ stars from World 1-1, 1-2, 1-3
- Recommended: Double jump (helps but not required)

**Design**:
```
[Start] → [Precision platforming gauntlet] →
[Checkpoint 1] → [Enemy rush: 6 goblins] → [Crystal 1] →
[Checkpoint 2] → [Vertical challenge with moving platforms] →
[Knights + Cannon combo] → [Crystal 2] →
[Checkpoint 3] → [Final gauntlet: All hazards] →
[Crystal 3] → [Goal]
```

**Specifications**:
- Time: Gold 120s, Silver 180s, Bronze 240s
- Coins: 100 (many hidden in side paths)
- Enemies: 10 goblins, 3 knights, 2 cannons
- Treasure: 2 chests (costume pieces)
- Hearts: 4 (you'll need them)
- Power-ups: 1 of each type
- Hazards: Spikes, crumbling platforms, moving platforms, cannons
- Length: 4-6 minutes

**Challenge Sections**:
1. **Precision Jumps**: Tight platform spacing, requires timing
2. **Enemy Gauntlet**: Continuous enemy waves
3. **Vertical Climb**: Moving platforms going upward
4. **Hazard Combo**: Spikes + enemies + moving platforms
5. **Final Test**: All mechanics combined

---

## World Structure Updates

### GameManager Changes
**File**: `scripts/game_manager.gd`

```gdscript
# Add world system
var worlds: Dictionary = {
    "world_1": {
        "name": "Grassland Plains",
        "levels": ["world1_level1", "world1_level2", "world1_level3", "world1_bonus"],
        "unlocked": true
    },
    "world_2": {
        "name": "Crystal Caverns",
        "levels": [], # Future
        "unlocked": false
    }
}

func get_world_levels(world_id: String) -> Array[LevelData]:
    var world_levels: Array[LevelData] = []
    if worlds.has(world_id):
        for level_id in worlds[world_id].levels:
            var level = get_level_by_id(level_id)
            if level:
                world_levels.append(level)
    return world_levels

func is_world_unlocked(world_id: String) -> bool:
    return worlds.get(world_id, {}).get("unlocked", false)
```

### Level Registry Updates
**Reorganize levels**:

```gdscript
# World 1 Levels
var world1_level1 = LevelData.new(
    "world1_level1",
    "World 1-1: First Steps",
    "res://scenes/levels/level_1.tscn",  # Reuse existing
    1,
    "Welcome to the Grassland Plains! Learn the basics.",
    "",  # No prerequisite
    20.0, 30.0, 45.0,
    true, false
)

var world1_level2 = LevelData.new(
    "world1_level2",
    "World 1-2: Leaping Meadows",
    "res://scenes/levels/level_2.tscn",  # Reuse existing
    2,
    "Navigate the sunny meadows and defeat your foes!",
    "world1_level1",
    45.0, 60.0, 90.0,
    true, false
)

var world1_level3 = LevelData.new(
    "world1_level3",
    "World 1-3: Crown Peak",
    "res://scenes/levels/level_3.tscn",  # Reuse existing
    3,
    "Climb to the peak and claim your prize!",
    "world1_level2",
    90.0, 120.0, 180.0,
    true, false
)

var world1_bonus = LevelData.new(
    "world1_bonus",
    "World 1-Bonus: Grassland Gauntlet",
    "res://scenes/levels/world1_bonus.tscn",  # NEW
    5,
    "The ultimate grassland challenge!",
    "",  # Unlocked by stars, not prerequisite
    120.0, 180.0, 240.0,
    true, false
)
```

---

## Implementation Timeline

### Week 1: Systems + Enhancements (Days 1-7)

**Day 1-2: New Systems**
- ✅ Checkpoint system (scene + script)
- ✅ Tutorial sign system (scene + script)
- ✅ LevelSession checkpoint integration
- ✅ Test systems in Phase 3 showcase level

**Day 3: World Map UI**
- ✅ World map scene structure
- ✅ Level node visuals
- ✅ Navigation system
- ✅ Lock/unlock display
- ✅ Star count display

**Day 4-5: Enhance Level 1 (World 1-1)**
- ✅ Add grassland theme assets
- ✅ Place 3 tutorial signs
- ✅ Add 1 checkpoint
- ✅ Place 3 goblins
- ✅ Expand coins to 100
- ✅ Add treasure chest
- ✅ Add heart pickup
- ✅ Add power-up
- ✅ Playtest and balance

**Day 6-7: Enhance Level 2 (World 1-2)**
- ✅ Add grassland theme
- ✅ Place 2 checkpoints
- ✅ Add 6 enemies (5 goblins + 1 knight)
- ✅ Expand coins to 100
- ✅ Add treasure chest (hidden)
- ✅ Add 2 hearts
- ✅ Add 2 power-ups
- ✅ Add spike hazards
- ✅ Playtest and balance

### Week 2: Final Content + Polish (Days 8-14)

**Day 8-9: Enhance Level 3 (World 1-3)**
- ✅ Add peak theme
- ✅ Place 2 checkpoints
- ✅ Add 11 enemies (multi-type)
- ✅ Create path choice
- ✅ Add vertical section
- ✅ Expand coins to 100
- ✅ Add 2 treasure chests
- ✅ Add 3 hearts
- ✅ Add 2 power-ups
- ✅ Create mini-boss arena
- ✅ Playtest and balance

**Day 10-12: Create World 1-Bonus**
- ✅ Build level from scratch
- ✅ Design gauntlet sections
- ✅ Place all 100 coins
- ✅ Place 15 enemies
- ✅ Place 4 hazard types
- ✅ Add 3 checkpoints
- ✅ Add 2 chests, 4 hearts
- ✅ Add power-ups
- ✅ Intensive playtesting

**Day 13: Integration**
- ✅ Update GameManager level registry
- ✅ Implement world map
- ✅ Set up world unlock logic
- ✅ Configure bonus level unlock (6+ stars)
- ✅ Test progression flow (1-1 → 1-2 → 1-3 → Bonus)

**Day 14: Polish & Documentation**
- ✅ Balance pass on all 4 levels
- ✅ Visual consistency check
- ✅ Performance testing
- ✅ Bug fixes
- ✅ Create World 1 completion assessment
- ✅ Documentation update

---

## Success Criteria

### Phase 4 Complete When:
- ✅ 4 World 1 levels fully playable and polished
- ✅ All levels have grassland visual theme
- ✅ All levels use Phase 1-3 features:
  - Enemies from Phase 2
  - Collectibles from Phase 3
  - Movement abilities from Phase 1
- ✅ Checkpoint system functional in all levels
- ✅ Tutorial signs guide new players (level 1-1)
- ✅ World map UI works and looks good
- ✅ Progression unlocks correctly (1-1 → 1-2 → 1-3 → Bonus)
- ✅ Bonus level unlocks at 6+ stars
- ✅ Difficulty curve feels appropriate
- ✅ All 4 levels are fun and balanced
- ✅ Time targets are achievable
- ✅ 100 coins per level

---

## Assets Needed

### 3D Models (Grassland Theme)
- Grass-topped platform material
- Tree models (3-4 varieties)
- Flower models (decorative)
- Grass clumps
- Rock formations
- Fence/sign posts
- Mountain peak assets (for level 1-3)

### UI Elements
- World map background
- Level node icon
- Star/medal icons
- Lock icon
- Path/trail connectors

### Particle Effects (Already have most)
- Checkpoint activation burst
- Tutorial sign sparkle (optional)

---

## Next Steps

1. **Immediate**: Create checkpoint system
2. **Then**: Create tutorial sign system
3. **Then**: Build world map UI
4. **Then**: Start enhancing Level 1

**Ready to begin Phase 4 implementation?**
