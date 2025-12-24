# Phase 4: World 1 Production - Implementation Plan

**Date**: December 24, 2025
**Status**: ⚠️ Planning - Dependency Check Required
**Duration**: 2 weeks (estimated)

---

## ⚠️ CRITICAL: Dependency Analysis

### Phase 4 Requirements vs Current State

**Phase 4 assumes the following systems are complete:**
- ✅ Phase 3: Collectibles & Economy ← **COMPLETE**
- ❌ Phase 2: Combat & Enemy System ← **NOT STARTED**
- ❌ Phase 1: Enhanced Character Controller ← **NOT STARTED**

### Missing Systems for Full Phase 4 Implementation

#### From Phase 1 (Not Implemented):
- ❌ Enhanced movement (acceleration/deceleration)
- ❌ Coyote time
- ❌ Jump buffering
- ❌ Variable jump height
- ❌ **Double jump** (required for Level 1-3 and 1-Bonus)
- ❌ **Ground pound** (planned ability)
- ❌ **Air dash** (planned ability)
- ❌ Run speed modifier

#### From Phase 2 (Not Implemented):
- ❌ **Health system** (hearts instead of death counter)
- ❌ **Enemy types**:
  - Goblin (patrol enemy) - Required for all 4 levels
  - Armored Knight (2-hit enemy) - Required for Level 1-3
  - Cannon Turret (stationary) - Required for Level 1-2, 1-3
  - Flying Enemy (not needed for World 1)
- ❌ **Combat mechanics**:
  - Jump on enemy to defeat
  - Enemy bouncing
  - Combo system
- ❌ **Invincibility frames**
- ❌ **Enemy spawn/placement system**

### Current Available Systems

**What We DO Have:**
- ✅ Basic player movement (WASD + Jump)
- ✅ Camera follow system
- ✅ Full collectible system (coins, crystals, chests, hearts, power-ups)
- ✅ Pause menu + Settings
- ✅ Level select with progression
- ✅ Save/load system
- ✅ 3-star medal system
- ✅ Moving platforms (linear + circular)
- ✅ Hazards: Spikes, bottomless pits
- ✅ Death system (death counter, respawn)
- ✅ Game HUD (timer, deaths, score)
- ✅ Shop system (items to unlock)

---

## Implementation Strategy Options

### Option 1: Simplified World 1 (Recommended for Now)
**Create 4 levels using ONLY existing mechanics**

**Pros**:
- Can start immediately
- Establishes level design pipeline
- Tests collectible systems in real levels
- Gives you playable content to test

**Cons**:
- Levels will need major updates when Phase 1 & 2 are done
- No enemies (or use placeholder static hazards)
- No double jump requirement
- Simpler platforming challenges

**Modified Level Specs**:
- Level 1-1: Tutorial (basic movement + collectibles)
- Level 1-2: Platforming focus (moving platforms, hazards)
- Level 1-3: Advanced platforming (timing challenges)
- Level 1-Bonus: Hard platforming gauntlet

### Option 2: Implement Phase 1 & 2 First (Follows Roadmap Order)
**Go back and build the missing systems before World 1**

**Pros**:
- Proper dependency order
- Levels won't need rework
- Full gameplay experience
- Roadmap sequence maintained

**Cons**:
- 3+ weeks of work before new levels
- Delays visible content
- More complex systems to build

**Timeline**:
- Phase 1: 1 week (enhanced movement + abilities)
- Phase 2: 2 weeks (health system + enemies + combat)
- Phase 4: 2 weeks (World 1 levels)
- Total: ~5 weeks

### Option 3: Hybrid Approach
**Build simplified World 1 now, upgrade later**

**Pros**:
- Immediate progress on levels
- Can test level design pipeline
- Placeholder enemies as static hazards
- Levels get "free upgrade" when Phase 1 & 2 done

**Cons**:
- Double work (build twice)
- May affect design decisions

**Approach**:
1. Create 4 World 1 levels with current mechanics
2. Use colored cubes as "enemy placeholders"
3. Design for future double jump (mark areas)
4. After Phase 1 & 2: Drop in real enemies, enable abilities

---

## Recommendation: Option 1 (Simplified World 1)

**Rationale**:
1. You've invested heavily in Phase 3 - leverage it in real levels
2. Level design pipeline is valuable regardless
3. Can always enhance levels later (Godot scenes are easy to modify)
4. Gives you 4 playable levels to show progress
5. Tests collectible systems in production environment

**Modified Phase 4 Scope**:
- ✅ Create 4 levels (simplified, no enemies)
- ✅ Establish level design patterns
- ✅ Test all Phase 3 collectibles in levels
- ✅ Create reusable level template
- ✅ Implement tutorial signs system
- ✅ Add checkpoint system
- ⏭️ Defer: Enemy encounters (Phase 2 dependency)
- ⏭️ Defer: Double jump requirement (Phase 1 dependency)

---

## Simplified Phase 4 Implementation Plan

### 4.1: Level Template Creation
**File**: `scenes/levels/level_template.tscn`

**Contents**:
- WorldEnvironment (DirectionalLight3D, sky)
- Ground plane
- Player spawn point
- Camera controller (existing)
- GameUI + GameHUD
- PauseMenu
- Level boundary (kill zone)
- Checkpoint system (new)
- Tutorial sign system (new)

**New Systems Needed**:
1. **Checkpoint System**
   - File: `scripts/checkpoint.gd`
   - On trigger: Save player position
   - On death: Respawn at checkpoint
   - Visual: Glowing marker + activation animation

2. **Tutorial Sign System**
   - File: `scripts/tutorial_sign.gd`
   - Displays text when player nearby
   - Can show controls (WASD, Space, E)
   - Dismisses after reading

### 4.2: World 1 Level 1 "First Steps"
**Focus**: Tutorial + Basic Platforming

**Layout**:
```
[Start] → [Coins Trail] → [Tutorial Sign: Movement] →
[Crystal 1: On obvious platform] → [Checkpoint] →
[Gap Jumps with coin guides] → [Tutorial Sign: Crystals] →
[Moving Platform] → [Crystal 2] →
[Treasure Chest] → [Crystal 3] → [Goal]
```

**Specifications**:
- Time: Gold 45s, Silver 60s, Bronze 90s
- Coins: 50 total (reduced from 100 - no enemies to drop coins)
- Crystals: 3 (standard)
- Treasure: 1 chest (10 coins)
- Hearts: 1 (for tutorial, placed after spike section)
- Hazards: Spikes, bottomless pits
- Power-ups: 1 speed boost (introduce mechanic)
- Platforms: ~15
- Length: 1 minute for new players

**Design Principles**:
- No death possible in first 15 seconds
- Breadcrumb coin trails show the path
- All mechanics introduced with signs
- Forgiving platform spacing

### 4.3: World 1 Level 2 "Leaping Meadows"
**Focus**: Moving Platforms + Platforming Challenges

**Layout**:
```
[Start] → [Linear moving platforms] → [Checkpoint] →
[Circular platforms around Crystal 1] →
[Spike gauntlet with hearts] → [Hidden chest path] →
[Crystal 2: On moving platform] →
[Crumbling platforms] → [Crystal 3] → [Goal]
```

**Specifications**:
- Time: Gold 60s, Silver 90s, Bronze 120s
- Coins: 60 total
- Crystals: 3
- Treasure: 1 chest (15 coins, hidden)
- Hearts: 2 (before/after spike sections)
- Hazards: Spikes, crumbling platforms, bottomless pits
- Power-ups: 1 invincibility star, 1 coin magnet
- Platforms: ~25
- Length: 2 minutes

**New Mechanic**: Crumbling platforms
- File: `scripts/hazards/crumbling_platform.gd`
- Shakes after 0.5s of player contact
- Falls after 1.0s
- Respawns after 3.0s

### 4.4: World 1 Level 3 "Crown Peak"
**Focus**: Vertical Climbing + Challenge

**Layout**:
```
[Start] → [Path Choice: Easy/Hard] →
    Easy: [More platforms] → [Merge]
    Hard: [Precision jumps, chest] → [Merge]
[Merge] → [Checkpoint] →
[Vertical climbing section] → [Crystal 1] →
[Moving platform gauntlet] → [Crystal 2] →
[Final challenge: spike + platform timing] → [Crystal 3] → [Goal]
```

**Specifications**:
- Time: Gold 90s, Silver 120s, Bronze 180s
- Coins: 80 total (50 easy path, 30 hard path)
- Crystals: 3
- Treasure: 2 chests (1 on hard path)
- Hearts: 2
- Hazards: All types
- Power-ups: 2 (double coins, speed boost)
- Platforms: ~35
- Length: 3 minutes

**Design Note**: This level WOULD unlock double jump in full version,
but for simplified version, just completes World 1.

### 4.5: World 1 Bonus "Grassland Gauntlet"
**Focus**: Hard Platforming Challenge

**Layout**:
```
[Start] → [Precision jump section] → [Checkpoint] →
[Speed run section with tight timing] → [Crystal 1] →
[Crumbling platform maze] → [Crystal 2] → [Checkpoint] →
[Moving platform + spike combo] → [Crystal 3] → [Goal]
```

**Specifications**:
- Time: Gold 120s, Silver 150s, Bronze 200s
- Coins: 100 total (many hidden)
- Crystals: 3
- Treasure: 2 chests (costume pieces)
- Hearts: 3 (strategically placed)
- Hazards: All types, maximum difficulty
- Power-ups: 1 of each type
- Platforms: ~40
- Length: 4 minutes
- **Unlocked by**: Collecting 6+ stars in first 3 World 1 levels

---

## New Systems to Implement

### System 1: Checkpoint System
**Files**:
- `scripts/checkpoint.gd`
- `scenes/props/checkpoint.tscn`

```gdscript
extends Area3D
class_name Checkpoint

@export var checkpoint_id: int = 0
var is_activated: bool = false

@onready var visual: MeshInstance3D = $Visual
@onready var particles: GPUParticles3D = $ActivationParticles

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player") and not is_activated:
        activate(body)

func activate(player: Node3D) -> void:
    is_activated = true

    # Save checkpoint in GameManager
    GameManager.set_checkpoint_position(global_position)

    # Visual feedback
    particles.emitting = true
    visual.modulate = Color(0.3, 1.0, 0.3)  # Green glow

    # Play sound
    print("Checkpoint activated at: %s" % global_position)
```

### System 2: Tutorial Sign System
**Files**:
- `scripts/tutorial_sign.gd`
- `scenes/props/tutorial_sign.tscn`

```gdscript
extends Area3D
class_name TutorialSign

@export_multiline var sign_text: String = "Press E to read"
@export var auto_show: bool = true  # Show on approach vs press E

var player_nearby: bool = false
var has_been_read: bool = false

@onready var label: Label3D = $SignLabel
@onready var prompt: Label3D = $Prompt

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    label.visible = false
    prompt.text = "Press E to read"

func _process(_delta: float) -> void:
    if player_nearby and not has_been_read:
        if auto_show:
            show_message()
        elif Input.is_action_just_pressed("interact"):
            show_message()

func show_message() -> void:
    has_been_read = true
    label.text = sign_text
    label.visible = true
    prompt.visible = false

    # Auto-hide after 5 seconds
    await get_tree().create_timer(5.0).timeout
    label.visible = false
```

### System 3: Crumbling Platform
**Files**:
- `scripts/hazards/crumbling_platform.gd`
- `scenes/hazards/crumbling_platform.tscn`

```gdscript
extends StaticBody3D
class_name CrumblingPlatform

@export var shake_delay: float = 0.5
@export var fall_delay: float = 1.0
@export var respawn_delay: float = 3.0

var player_on_platform: bool = false
var time_stepped_on: float = 0.0
var is_falling: bool = false
var original_position: Vector3

@onready var mesh: MeshInstance3D = $Mesh
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var detection: Area3D = $DetectionArea

func _ready() -> void:
    original_position = global_position
    detection.body_entered.connect(_on_body_entered)
    detection.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
    if player_on_platform and not is_falling:
        time_stepped_on += delta

        if time_stepped_on > shake_delay:
            # Shake visual
            mesh.position = Vector3(
                randf_range(-0.05, 0.05),
                0,
                randf_range(-0.05, 0.05)
            )

        if time_stepped_on > fall_delay:
            start_falling()

func start_falling() -> void:
    is_falling = true
    collision.disabled = true

    # Fall animation
    var tween = create_tween()
    tween.tween_property(self, "global_position", global_position + Vector3(0, -10, 0), 1.0)
    tween.tween_callback(respawn_platform)

func respawn_platform() -> void:
    await get_tree().create_timer(respawn_delay).timeout
    global_position = original_position
    mesh.position = Vector3.ZERO
    collision.disabled = false
    is_falling = false
    time_stepped_on = 0.0
```

### System 4: Checkpoint Integration in GameManager
**File**: `scripts/game_manager.gd` (modify)

```gdscript
# Add to GameManager
var current_checkpoint_position: Vector3 = Vector3.ZERO
var checkpoint_active: bool = false

func set_checkpoint_position(position: Vector3) -> void:
    current_checkpoint_position = position
    checkpoint_active = true
    print("Checkpoint saved: %s" % position)

func respawn_at_checkpoint() -> void:
    if checkpoint_active:
        var player = _find_player()
        if player:
            player.global_position = current_checkpoint_position + Vector3(0, 1, 0)
            print("Respawned at checkpoint")

func clear_checkpoint() -> void:
    checkpoint_active = false
    current_checkpoint_position = Vector3.ZERO
```

---

## Implementation Order

### Week 1: Foundation + 2 Levels
1. **Day 1-2**: New systems
   - ✅ Checkpoint system
   - ✅ Tutorial sign system
   - ✅ Crumbling platform
   - ✅ Level template

2. **Day 3-4**: Level 1-1 "First Steps"
   - ✅ Layout design
   - ✅ Platform placement
   - ✅ Collectible placement
   - ✅ Tutorial signs
   - ✅ Playtesting + polish

3. **Day 5-7**: Level 1-2 "Leaping Meadows"
   - ✅ Layout design
   - ✅ Moving platform patterns
   - ✅ Hidden areas
   - ✅ Crumbling platforms
   - ✅ Playtesting + polish

### Week 2: Final 2 Levels + Polish
1. **Day 8-10**: Level 1-3 "Crown Peak"
   - ✅ Vertical section design
   - ✅ Path choice implementation
   - ✅ Advanced platforming
   - ✅ Playtesting + polish

2. **Day 11-13**: Level 1-Bonus "Grassland Gauntlet"
   - ✅ Hard challenge sections
   - ✅ Unlock condition
   - ✅ Secret areas
   - ✅ Playtesting + polish

3. **Day 14**: Final polish
   - ✅ Balance pass on all 4 levels
   - ✅ Update GameManager level registry
   - ✅ Test progression flow
   - ✅ Documentation

---

## Success Criteria

### Phase 4 Complete When:
- ✅ 4 World 1 levels fully playable
- ✅ All Phase 3 collectibles used in levels
- ✅ Checkpoint system functional
- ✅ Tutorial signs guide new players
- ✅ Difficulty curve feels good
- ✅ All levels registered in GameManager
- ✅ Level progression unlocks work
- ✅ Time targets are achievable but challenging
- ✅ Collectible counts are correct (coins, crystals, chests)

### Known Limitations (To Address in Future):
- ⏭️ No enemies (placeholder for Phase 2)
- ⏭️ No double jump requirement (Phase 1)
- ⏭️ No heart healing system (Phase 2)
- ⏭️ Simpler combat-free design

---

## Next Steps

**Immediate Actions**:
1. Create checkpoint system
2. Create tutorial sign system
3. Create crumbling platform
4. Create level template
5. Build Level 1-1 "First Steps"

**Question for User**:
Ready to proceed with **Option 1: Simplified World 1** approach?
- 4 levels using existing mechanics
- Can be enhanced when Phase 1 & 2 are complete
- Immediate playable content

Or would you prefer **Option 2**: Go back and implement Phase 1 & 2 first?
