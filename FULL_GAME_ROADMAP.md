# Kingdom Hearts: The Lost Treasures
## Full Game Implementation Roadmap

**Project Status**: Demo Phase Complete → Production Phase
**Demo Assets Reusable**: ~40% of final game architecture
**Estimated Total Implementation**: 8-12 weeks for solo developer

---

## Executive Summary

Transform the current 5-level platformer demo into a complete 20-level adventure game with enhanced mechanics, combat system, multiple worlds, and full progression system.

### What We Already Have (Reusable)
✅ Core player movement (WASD + Jump)
✅ Camera follow system with smooth tracking
✅ Collectible system framework (stars)
✅ Level structure with .tscn scenes
✅ Pause menu + Settings system
✅ Game HUD (timer, collectibles, deaths)
✅ Level select with unlock progression
✅ Save/load system with JSON persistence
✅ 3-star rating based on completion time
✅ Moving platforms (linear + circular)
✅ Basic hazards (spikes)
✅ Game manager singleton architecture
✅ Collision debugging tools

### What Needs Building
🔨 Enhanced movement (double jump, roll, ground pound)
🔨 Health system (hearts instead of death counter)
🔨 Combat mechanics (jump attacks, enemy bouncing)
🔨 Enemy AI system (4 types + boss)
🔨 Expanded collectibles (coins, crystals, chests, power-ups)
🔨 NPC rescue missions
🔨 Shop system with unlockables
🔨 15 new levels across 5 themed worlds
🔨 World map UI
🔨 Checkpoint system
🔨 Interactive objects (crates, springs, switches)
🔨 Environmental hazards (beyond spikes)
🔨 Audio system (music + SFX)
🔨 Particle effects and polish
🔨 Boss battle mechanics

---

## Phase Structure Overview

| Phase | Focus | Duration | Prerequisites |
|-------|-------|----------|---------------|
| **Phase 1** | Enhanced Character Controller | 1 week | Demo complete |
| **Phase 2** | Combat & Enemy System | 2 weeks | Phase 1 |
| **Phase 3** | Collectibles & Economy | 1 week | Phases 1-2 |
| **Phase 4** | World 1 Production (4 levels) | 2 weeks | Phases 1-3 |
| **Phase 5** | UI & Progression Systems | 1 week | Phase 4 |
| **Phase 6** | Worlds 2-4 Production (12 levels) | 3 weeks | Phase 5 |
| **Phase 7** | World 5 & Boss Battle | 2 weeks | Phase 6 |
| **Phase 8** | Audio & Polish | 1 week | Phase 7 |
| **Phase 9** | Testing & Balancing | 1 week | Phase 8 |

---

## PHASE 1: Enhanced Character Controller
**Duration**: 1 week
**Status**: Not Started
**Reuses**: Existing player.gd, player.tscn

### Goals
Transform basic movement into responsive, "juicy" platformer controls with new abilities.

### Implementation Tasks

#### 1.1: Movement Refinement
**Files**: `scripts/player.gd`, `scripts/player_state_machine.gd` (new)

**Current State**:
```gdscript
# player.gd has basic movement
var speed = 5.0
var jump_velocity = 4.5
```

**Enhancements Needed**:
- [ ] Add acceleration/deceleration curves (not instant speed)
- [ ] Add "coyote time" (6-frame jump buffer after leaving platform)
- [ ] Add jump buffering (can press jump 3 frames before landing)
- [ ] Add variable jump height (hold = higher, tap = lower)
- [ ] Add run speed modifier (hold Shift for 1.5x speed)
- [ ] Add momentum preservation on landing

**Implementation**:
```gdscript
# Enhanced movement variables
const ACCELERATION = 20.0
const DECELERATION = 25.0
const MAX_SPEED = 5.0
const RUN_MULTIPLIER = 1.5
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.05

var current_speed = 0.0
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var is_running = false

func _physics_process(delta):
    handle_coyote_time(delta)
    handle_jump_buffering(delta)
    handle_movement(delta)
```

**Testing Criteria**:
- Movement feels "bouncy" and responsive
- Jumps feel fair (coyote time prevents frustrating edge falls)
- Run speed noticeably different from walk

#### 1.2: Double Jump System
**Files**: `scripts/player.gd`, `scripts/game_manager.gd`

- [ ] Add double jump counter (max 1 extra jump)
- [ ] Reset counter on landing
- [ ] Add particle effect on second jump (different color)
- [ ] Add "whoosh" sound effect
- [ ] Store unlock status in GameManager save data

**Implementation**:
```gdscript
var double_jump_unlocked = false
var jumps_available = 1

func handle_jump():
    if Input.is_action_just_pressed("jump"):
        if is_on_floor():
            jump()
            jumps_available = 2 if double_jump_unlocked else 1
        elif jumps_available > 0:
            jump()
            jumps_available -= 1
            emit_double_jump_particles()
```

**Unlock Condition**: Completing World 1-3

#### 1.3: Roll/Dash Ability
**Files**: `scripts/player.gd`

- [ ] Add dash state to state machine
- [ ] Dash distance: 3 units in facing direction
- [ ] Dash duration: 0.3 seconds
- [ ] Cooldown: 0.5 seconds
- [ ] Make player invulnerable during dash
- [ ] Add trail effect particles
- [ ] Disable mid-air dashing initially (unlock later)

**Implementation**:
```gdscript
var dash_cooldown_timer = 0.0
const DASH_SPEED = 10.0
const DASH_DURATION = 0.3
var is_dashing = false

func handle_dash():
    if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
        start_dash()

func start_dash():
    is_dashing = true
    velocity = forward_direction * DASH_SPEED
    dash_cooldown_timer = 0.5
    # Add invulnerability
    # Spawn trail particles
```

#### 1.4: Ground Pound (Unlockable)
**Files**: `scripts/player.gd`, `shop_system.gd` (new)

- [ ] Input: Hold jump then release while in air
- [ ] Slam downward at 2x fall speed
- [ ] Create shockwave on impact (damage nearby enemies)
- [ ] Slight bounce after landing
- [ ] Can break special crates
- [ ] Costs 150 coins to unlock

**Implementation**:
```gdscript
var ground_pound_unlocked = false
var is_ground_pounding = false
const GROUND_POUND_SPEED = -15.0

func handle_ground_pound():
    if not is_on_floor() and Input.is_action_pressed("jump"):
        # Charge ground pound
        if Input.is_action_just_released("jump"):
            is_ground_pounding = true
            velocity.y = GROUND_POUND_SPEED

func on_ground_pound_land():
    create_shockwave(position, 3.0)  # 3 unit radius
    camera_shake(0.3, 5.0)
```

#### 1.5: Animation State Machine
**Files**: `scripts/player_animation.gd` (new), `scenes/player/player.tscn`

**States Needed**:
- Idle (standing still, subtle breathing)
- Walk (slow movement)
- Run (fast movement)
- Jump (rising, peak, falling - 3 separate animations)
- Land (impact frame + recovery)
- Roll/Dash (forward motion)
- Ground Pound (charge + slam)
- Victory Dance (level complete)
- Death (knocked back)

**Current State**: Player uses basic character model, may need animation setup

**Implementation**:
```gdscript
# player_animation.gd
extends Node

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var model: Node3D = $"../CharacterModel"

enum State {IDLE, WALK, RUN, JUMP, FALL, LAND, DASH, GROUND_POUND, VICTORY, DEATH}
var current_state = State.IDLE

func update_animation(velocity: Vector3, is_on_floor: bool, is_dashing: bool):
    var new_state = determine_state(velocity, is_on_floor, is_dashing)
    if new_state != current_state:
        transition_to(new_state)
```

**Note**: If Quaternius models don't have animations, use simple model transforms:
- Idle: Gentle bob up/down
- Walk: Tilt forward, rotate model
- Jump: Stretch vertically
- Land: Squash briefly

### Phase 1 Deliverables
✅ Player controller feels responsive and "juicy"
✅ All movement abilities implemented and working
✅ Ability unlock system integrated with GameManager
✅ Animation system (or placeholder transforms) functional

### Phase 1 Testing Checklist
- [ ] Coyote time prevents frustrating edge deaths
- [ ] Jump buffering makes combat feel fair
- [ ] Dash has satisfying feel with proper cooldown
- [ ] Double jump unlocks after World 1-3
- [ ] Ground pound only available after shop purchase
- [ ] All animations transition smoothly
- [ ] Movement feels better than original demo

---

## PHASE 2: Combat & Enemy System
**Duration**: 2 weeks
**Status**: Not Started
**Dependencies**: Phase 1 (need character controller)

### Goals
Implement health system, enemy AI, combat mechanics, and boss battle framework.

### Implementation Tasks

#### 2.1: Health System
**Files**: `scripts/health_component.gd` (new), `scripts/player.gd`, `scripts/game_hud.gd`

**Replace Current System**:
```gdscript
// OLD: Death counter in demo
GameManager.death_count += 1

// NEW: Heart-based health
player.take_damage(1)
```

- [ ] Create reusable HealthComponent node
- [ ] Player starts with 3 hearts (max_health = 3)
- [ ] Display hearts in HUD (filled/empty sprites)
- [ ] Damage = flashing invincibility (1 second)
- [ ] Death = 0 hearts → respawn at checkpoint
- [ ] Heart pickups restore 1 heart

**Implementation**:
```gdscript
# health_component.gd
class_name HealthComponent
extends Node

signal health_changed(new_health, max_health)
signal died

@export var max_health: int = 3
var current_health: int = max_health
var invulnerable: bool = false

func take_damage(amount: int):
    if invulnerable:
        return

    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)

    if current_health <= 0:
        died.emit()
    else:
        start_invulnerability(1.0)

func heal(amount: int):
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
```

**HUD Update**:
```gdscript
# game_hud.gd - add heart display
@onready var hearts_container: HBoxContainer = $TopLeft/HeartsContainer

func update_hearts(current: int, max: int):
    # Clear existing
    for child in hearts_container.get_children():
        child.queue_free()

    # Add heart sprites
    for i in range(max):
        var heart = TextureRect.new()
        heart.texture = heart_full if i < current else heart_empty
        hearts_container.add_child(heart)
```

#### 2.2: Base Enemy System
**Files**: `scripts/base_enemy.gd` (new), `scenes/enemies/base_enemy.tscn` (new)

**Enemy Components**:
- [ ] HealthComponent (1-3 HP depending on type)
- [ ] PatrolComponent (waypoint-based movement)
- [ ] DetectionArea (Area3D to detect player)
- [ ] AttackComponent (damage player on contact)
- [ ] AnimationComponent
- [ ] Drop coins on death

**Base Enemy Structure**:
```gdscript
# base_enemy.gd
class_name BaseEnemy
extends CharacterBody3D

@export var max_health: int = 1
@export var move_speed: float = 2.0
@export var patrol_points: Array[Vector3] = []
@export var coins_dropped: int = 3
@export var damage_to_player: int = 1

@onready var health_component: HealthComponent = $HealthComponent
@onready var detection_area: Area3D = $DetectionArea
@onready var hurtbox: Area3D = $Hurtbox

var current_patrol_index = 0
var player_detected = false
var player_reference = null

func _ready():
    health_component.died.connect(_on_died)
    detection_area.body_entered.connect(_on_player_detected)
    hurtbox.body_entered.connect(_on_hurtbox_entered)

func _physics_process(delta):
    if player_detected:
        ai_chase_player(delta)
    else:
        ai_patrol(delta)

    move_and_slide()

func _on_hurtbox_entered(body):
    if body.is_in_group("player"):
        # Check if player is jumping on head
        if body.global_position.y > global_position.y + 0.5:
            take_jump_damage(body)
        else:
            damage_player(body)

func take_jump_damage(player):
    health_component.take_damage(1)
    player.bounce_on_enemy()  # Give player upward velocity

func _on_died():
    spawn_coins(coins_dropped)
    play_death_animation()
    queue_free()
```

#### 2.3: Enemy Types

##### 2.3.1: Goblin (Basic Enemy)
**File**: `scenes/enemies/goblin.tscn`

- [ ] Extends BaseEnemy
- [ ] Health: 1 HP
- [ ] Speed: 2.0
- [ ] Patrol between waypoints
- [ ] Drops: 3 coins
- [ ] Color: Green character model
- [ ] Detection range: 5 units

**Patrol Behavior**:
```gdscript
# goblin.gd
extends BaseEnemy

func ai_patrol(delta):
    if patrol_points.size() < 2:
        return

    var target = patrol_points[current_patrol_index]
    var direction = (target - global_position).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed

    if global_position.distance_to(target) < 0.5:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
```

##### 2.3.2: Armored Knight (Tank Enemy)
**File**: `scenes/enemies/knight.tscn`

- [ ] Extends BaseEnemy
- [ ] Health: 2 HP (requires 2 jumps to defeat)
- [ ] Speed: 1.5 (slower than goblin)
- [ ] Patrol between waypoints
- [ ] Drops: 5 coins
- [ ] Color: Dark blue/gray character model
- [ ] Detection range: 4 units (shorter sight)
- [ ] Visual: Show damage state (cracks appear after first hit)

##### 2.3.3: Cannon Turret (Stationary Hazard)
**File**: `scenes/enemies/cannon.tscn`

- [ ] Does not extend BaseEnemy (not character-based)
- [ ] Cannot be defeated
- [ ] Rotates to face player when in range (8 units)
- [ ] Fires cannonball every 2 seconds
- [ ] Cannonball: Projectile with Area3D damage
- [ ] Visual: Cannon model with rotation animation

**Implementation**:
```gdscript
# cannon.gd
extends Node3D

const Cannonball = preload("res://scenes/projectiles/cannonball.tscn")

@export var detection_range: float = 8.0
@export var fire_rate: float = 2.0

var fire_timer: float = 0.0
var player: Node3D = null

func _process(delta):
    fire_timer -= delta

    # Find player
    if player == null:
        player = get_tree().get_first_node_in_group("player")

    if player and global_position.distance_to(player.global_position) < detection_range:
        look_at_player()

        if fire_timer <= 0:
            fire_cannonball()
            fire_timer = fire_rate

func fire_cannonball():
    var ball = Cannonball.instantiate()
    ball.global_position = $CannonBarrel.global_position
    ball.direction = -global_transform.basis.z
    get_tree().root.add_child(ball)
```

##### 2.3.4: Flying Bat (Aerial Enemy)
**File**: `scenes/enemies/bat.tscn`

- [ ] Extends BaseEnemy
- [ ] Health: 1 HP
- [ ] Flies in sine wave pattern
- [ ] Swoops down when player beneath it
- [ ] Returns to patrol after swoop
- [ ] Drops: 3 coins
- [ ] Can be defeated by jump or dash

**Swoop Behavior**:
```gdscript
# bat.gd
extends BaseEnemy

enum State {PATROL, SWOOP, RETURN}
var state = State.PATROL
var swoop_start_position: Vector3

func ai_patrol(delta):
    # Sine wave movement
    var time = Time.get_ticks_msec() / 1000.0
    velocity.y = sin(time * 2.0) * 0.5

    # Check if player below
    if player_reference and is_player_below():
        state = State.SWOOP
        swoop_start_position = global_position

func ai_chase_player(delta):
    if state == State.SWOOP:
        # Dive toward player
        velocity.y = -5.0
        if global_position.y <= player_reference.global_position.y:
            state = State.RETURN
```

#### 2.4: Jump Combat System
**Files**: `scripts/player.gd`, `scripts/player_combat.gd` (new)

- [ ] Detect enemy collision while jumping
- [ ] Apply upward bounce velocity to player
- [ ] Damage enemy (via their HealthComponent)
- [ ] Combo system: chain bounces increase coin multiplier
- [ ] Visual/audio feedback

**Implementation**:
```gdscript
# player_combat.gd
extends Node

var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_TIMEOUT = 2.0

func bounce_on_enemy(player: CharacterBody3D):
    player.velocity.y = 6.0  # Bounce height
    combo_count += 1
    combo_timer = COMBO_TIMEOUT

    # Show combo UI
    if combo_count > 1:
        display_combo_text(combo_count)

    # Coin multiplier bonus
    var coin_multiplier = 1.0 + (combo_count * 0.5)
    GameManager.set_coin_multiplier(coin_multiplier)

func _process(delta):
    if combo_timer > 0:
        combo_timer -= delta
        if combo_timer <= 0:
            combo_count = 0
            GameManager.set_coin_multiplier(1.0)
```

#### 2.5: Boss Battle Framework
**Files**: `scripts/boss_base.gd` (new), `scenes/bosses/goblin_king.tscn` (new)

**Goblin King Boss**:
- [ ] Health: 10 HP (displayed as boss health bar)
- [ ] 3 Phases (triggers at 7 HP, 4 HP, 0 HP)
- [ ] Arena: Locked camera, enclosed space
- [ ] Attacks vary per phase

**Boss Structure**:
```gdscript
# boss_base.gd
class_name Boss
extends CharacterBody3D

signal phase_changed(phase_number)
signal boss_defeated

@export var max_health: int = 10
@export var phase_thresholds: Array[int] = [7, 4]

var current_phase: int = 1
var health_component: HealthComponent

func _ready():
    health_component = $HealthComponent
    health_component.max_health = max_health
    health_component.health_changed.connect(_on_health_changed)
    health_component.died.connect(_on_defeated)

func _on_health_changed(new_health, _max):
    # Check phase transitions
    for i in range(phase_thresholds.size()):
        if new_health <= phase_thresholds[i] and current_phase == i + 1:
            current_phase = i + 2
            phase_changed.emit(current_phase)
            transition_to_phase(current_phase)

func transition_to_phase(phase: int):
    # Override in specific boss classes
    pass
```

**Goblin King Phases**:

Phase 1 (10-8 HP):
- Throws bombs (projectiles) every 3 seconds
- Summons 2 goblin minions
- Walks slowly around arena

Phase 2 (7-5 HP):
- Jumps to random positions
- Creates shockwave on landing (player must jump to avoid)
- Summons 3 goblin minions
- Bombs throw faster (every 2 seconds)

Phase 3 (4-1 HP):
- Platforms in arena start disappearing randomly
- Fast movement + jump attacks
- Continuous goblin minion spawns (1 every 5 seconds)
- Throws 2 bombs at once

**Implementation**:
```gdscript
# goblin_king.gd
extends Boss

const Bomb = preload("res://scenes/projectiles/bomb.tscn")
const GoblinMinion = preload("res://scenes/enemies/goblin.tscn")

@export var arena_platforms: Array[Node3D] = []

var attack_timer: float = 0.0
var current_attack: String = ""

func transition_to_phase(phase: int):
    match phase:
        2:
            attack_timer = 2.0
            move_speed = 4.0
        3:
            start_platform_despawn()
            attack_timer = 1.5

func _physics_process(delta):
    attack_timer -= delta

    match current_phase:
        1:
            if attack_timer <= 0:
                throw_bomb()
                attack_timer = 3.0
        2:
            if attack_timer <= 0:
                jump_attack()
                attack_timer = 4.0
        3:
            if attack_timer <= 0:
                throw_double_bombs()
                attack_timer = 1.5
```

### Phase 2 Deliverables
✅ Health system replacing death counter
✅ 4 enemy types functional with AI
✅ Jump combat with combo system
✅ Goblin King boss battle
✅ Enemy spawn/placement system for levels

### Phase 2 Testing Checklist
- [ ] Health depletes and restores correctly
- [ ] Invincibility frames prevent rapid damage
- [ ] All enemy types patrol and attack properly
- [ ] Jump attacks feel satisfying with good bounce
- [ ] Combo system rewards chaining kills
- [ ] Cannon turrets fire predictably
- [ ] Boss phases transition at correct HP thresholds
- [ ] Boss attacks are fair but challenging
- [ ] Performance: 20+ enemies on screen at 60fps

---

## PHASE 3: Collectibles & Economy System
**Duration**: 1 week
**Status**: Not Started
**Dependencies**: Phases 1-2

### Goals
Expand collectible types, implement coin economy, add shop system, create loot drops.

### Implementation Tasks

#### 3.1: Coin System
**Files**: `scripts/collectibles/coin.gd` (new), `scenes/collectibles/coin.tscn` (new)

**Reuse**: Current collectible.gd as template

- [ ] Create coin collectible (small, yellow, rotating)
- [ ] 100 coins per level (placed in designer-friendly positions)
- [ ] Auto-collect with magnetic pull when near player (1.5 units)
- [ ] Different coin values: Regular (1), Big (5), Hidden (10)
- [ ] Particle effect on collection
- [ ] "Pling" sound effect
- [ ] Update HUD coin counter

**Implementation**:
```gdscript
# coin.gd
extends Area3D

@export var coin_value: int = 1
@export var attract_radius: float = 1.5
@export var attract_speed: float = 10.0

var being_attracted: bool = false
var player: Node3D = null

func _ready():
    body_entered.connect(_on_body_entered)

func _physics_process(delta):
    # Rotate for visual appeal
    rotate_y(delta * 3.0)

    # Magnetic pull toward player
    if player and global_position.distance_to(player.global_position) < attract_radius:
        being_attracted = true

    if being_attracted and player:
        var direction = (player.global_position - global_position).normalized()
        global_position += direction * attract_speed * delta

func _on_body_entered(body):
    if body.is_in_group("player"):
        collect(body)

func collect(player):
    GameManager.add_coins(coin_value)
    spawn_particle_effect()
    play_sound("coin_collect")
    queue_free()
```

**Coin Placement Tool** (Editor script for level design):
```gdscript
# coin_placer_tool.gd (EditorScript)
# Place coins in breadcrumb trails, reward exploration
# Tool provides:
# - Snap to grid
# - Line tool (place coins in path)
# - Circle tool (place coins in circle)
# - Copy/paste coin patterns
```

#### 3.2: Crown Crystal System
**Files**: `scripts/collectibles/crown_crystal.gd` (new)

**Reuse**: Current star collectible system

- [ ] 3 Crown Crystals per level (primary objective)
- [ ] Large, pink gem with glow particles
- [ ] Emit pillar of light visible from distance
- [ ] Dramatic collection: freeze frame, camera zoom, fanfare
- [ ] Required to unlock next level
- [ ] Track collection in GameManager

**Current System Mapping**:
```gdscript
// OLD: Generic "collectible"
func _on_collectible_collected():
    GameManager.collectibles_gathered += 1

// NEW: Crown Crystal (main objective)
func _on_crown_crystal_collected(crystal_id: int):
    GameManager.collect_crown_crystal(current_level, crystal_id)
    if GameManager.are_all_crystals_collected(current_level):
        unlock_next_level()
```

**Enhanced Collection**:
```gdscript
# crown_crystal.gd
func collect(player):
    # Dramatic collection sequence
    freeze_game(1.0)
    camera_zoom_to(global_position, 0.5)
    play_crystal_fanfare()
    spawn_burst_particles()

    GameManager.collect_crown_crystal(
        GameManager.current_level_data.level_id,
        crystal_id
    )

    await get_tree().create_timer(1.5).timeout
    unfreeze_game()

    queue_free()
```

#### 3.3: Star Medal System
**Files**: `scripts/level_session.gd` (extend existing), `scripts/game_hud.gd`

**Reuse**: Current 3-star time-based system

**Enhancement**: Add new medal types
- ⭐ Medal 1: Complete level (collect all 3 crystals)
- ⭐ Medal 2: Collect all 100 coins
- ⭐ Medal 3: Complete under target time

**Update Display**:
```gdscript
# game_hud.gd - star display
@onready var star_medals: HBoxContainer = $TopRight/StarMedals

func update_medals():
    var medals = {
        "complete": GameManager.are_all_crystals_collected(current_level),
        "coins": GameManager.get_coins_collected() >= 100,
        "time": LevelSession.elapsed_time <= target_time
    }

    for i in range(3):
        var star = star_medals.get_child(i) as TextureRect
        match i:
            0: star.texture = star_filled if medals.complete else star_outline
            1: star.texture = star_filled if medals.coins else star_outline
            2: star.texture = star_filled if medals.time else star_outline
```

#### 3.4: Treasure Chest System
**Files**: `scripts/collectibles/treasure_chest.gd` (new), `scenes/collectibles/treasure_chest.tscn` (new)

- [ ] 1-2 hidden chests per level
- [ ] Require finding secret paths
- [ ] Interaction prompt ("Press E to open")
- [ ] Opening animation (lid opens, items fly out)
- [ ] Contains: 10 coins OR costume piece
- [ ] Track opened chests in save data (don't respawn)

**Implementation**:
```gdscript
# treasure_chest.gd
extends Node3D

@export var chest_id: String  # Unique per level
@export var contents: Array[Resource] = []  # Coin items or costume unlocks
@export var coin_value: int = 10

var is_opened: bool = false
var player_nearby: bool = false

func _ready():
    # Check if already opened
    if GameManager.is_chest_opened(GameManager.current_level_data.level_id, chest_id):
        is_opened = true
        $Mesh.frame = 1  # Show open sprite
        $InteractionArea.queue_free()

func _process(_delta):
    if player_nearby and Input.is_action_just_pressed("interact") and not is_opened:
        open_chest()

func open_chest():
    is_opened = true
    play_open_animation()
    spawn_contents()
    GameManager.mark_chest_opened(GameManager.current_level_data.level_id, chest_id)

func spawn_contents():
    if contents.size() > 0:
        # Spawn costume or item
        pass
    else:
        # Spawn coins
        for i in range(coin_value):
            spawn_coin_with_arc(i)
```

#### 3.5: Heart Pickup System
**Files**: `scripts/collectibles/heart_pickup.gd` (new)

- [ ] Restores 1 heart to player
- [ ] Placed before difficult sections
- [ ] Respawns on level restart (not persistent)
- [ ] Glows/pulses to draw attention

**Implementation**:
```gdscript
# heart_pickup.gd
extends Area3D

func _on_body_entered(body):
    if body.is_in_group("player"):
        if body.health_component.current_health < body.health_component.max_health:
            body.health_component.heal(1)
            play_heal_sound()
            spawn_heal_particles()
            queue_free()
```

#### 3.6: Power-Up System
**Files**: `scripts/powerups/powerup_base.gd` (new)

**Temporary Power-Ups** (10-30 second duration):
- [ ] Speed Boost (yellow): 1.5x movement speed
- [ ] Invincibility Star (rainbow): No damage
- [ ] Coin Magnet (purple): Auto-collect all visible coins
- [ ] Double Coins (gold): Coins worth 2x

**Implementation**:
```gdscript
# powerup_base.gd
class_name PowerUp
extends Area3D

@export var duration: float = 10.0
@export var powerup_type: String = "speed"

func _on_body_entered(body):
    if body.is_in_group("player"):
        activate_powerup(body)
        queue_free()

func activate_powerup(player):
    match powerup_type:
        "speed":
            player.apply_speed_boost(duration, 1.5)
        "invincibility":
            player.health_component.invulnerable = true
            await get_tree().create_timer(duration).timeout
            player.health_component.invulnerable = false
        "magnet":
            player.enable_coin_magnet(duration)
        "double_coins":
            GameManager.set_coin_multiplier(2.0)
            await get_tree().create_timer(duration).timeout
            GameManager.set_coin_multiplier(1.0)
```

#### 3.7: Shop System
**Files**: `scripts/shop_system.gd` (new), `scenes/ui/shop_menu.tscn` (new)

**Unlockables**:
- Extra heart container (+1 max HP): 200 coins
- Ground Pound ability: 150 coins
- Spin Attack ability: 150 coins
- Costume: Blue Pip: 100 coins
- Costume: Red Pip: 100 coins
- Costume: Gold Pip: 150 coins
- Trail Effect - Sparkles: 50 coins
- Trail Effect - Stars: 75 coins
- Faster Respawn: 100 coins

**Implementation**:
```gdscript
# shop_system.gd
extends Control

var shop_items = {
    "extra_heart": {"cost": 200, "name": "Extra Heart", "purchased": false},
    "ground_pound": {"cost": 150, "name": "Ground Pound", "purchased": false},
    "spin_attack": {"cost": 150, "name": "Spin Attack", "purchased": false},
    # ... more items
}

func _ready():
    load_purchased_items()
    populate_shop_ui()

func purchase_item(item_id: String):
    var item = shop_items[item_id]
    if GameManager.total_coins >= item.cost and not item.purchased:
        GameManager.spend_coins(item.cost)
        item.purchased = true
        apply_unlock(item_id)
        save_purchase(item_id)

func apply_unlock(item_id: String):
    match item_id:
        "extra_heart":
            GameManager.player_max_health += 1
        "ground_pound":
            GameManager.ground_pound_unlocked = true
        # ... etc
```

### Phase 3 Deliverables
✅ Full coin economy system
✅ Crown Crystals as main objective
✅ Enhanced star medal system
✅ Treasure chests with loot
✅ Power-up system
✅ Functional shop with unlockables

### Phase 3 Testing Checklist
- [ ] Coins attract to player smoothly
- [ ] Crown Crystal collection feels dramatic/rewarding
- [ ] Star medals track all 3 completion types
- [ ] Treasure chests stay opened after reload
- [ ] Power-ups provide noticeable advantages
- [ ] Shop purchases persist across sessions
- [ ] Cannot purchase same item twice
- [ ] Coin counter updates everywhere correctly

---

## PHASE 4: World 1 Production (4 Levels)
**Duration**: 2 weeks
**Status**: Not Started
**Dependencies**: Phases 1-3

### Goals
Create World 1 "Grassland Plains" with 3 main levels + 1 bonus level. Establish level design pipeline.

### World 1 Theme: Grassland Plains
**Visual Style**:
- Grass-topped platforms (green)
- Wood/dirt layered terrain
- Blue sky background
- Trees, flowers, clouds
- Cheerful, beginner-friendly

**Difficulty Curve**:
- Level 1-1: Tutorial (easiest)
- Level 1-2: Basic challenges
- Level 1-3: Introduces all mechanics
- Level 1-Bonus: Hard optional challenge

### Implementation Tasks

#### 4.1: Level 1-1 "First Steps" (Tutorial)
**File**: `scenes/levels/world1_level1.tscn`

**Design Goals**:
- Teach basic movement
- Introduce first Crown Crystal
- Show coin collection
- Present first enemy (single goblin)
- Checkpoint before enemy section
- **No death** possible in first 30 seconds

**Layout** (Top-down view):
```
[Start] → [Coins Trail] → [Crystal 1] → [Checkpoint] →
[Gap Jump] → [Goblin Patrol] → [Crystal 2] →
[Moving Platform] → [Crystal 3] → [Goal]
```

**Tutorial Signs** (Interactive UI):
- Sign 1: "Move with WASD! Jump with Space!"
- Sign 2: "Collect Crown Crystals to progress!"
- Sign 3: "Jump on enemies to defeat them!"

**Specifications**:
- Time Targets: Gold 60s, Silver 90s, Bronze 120s
- Coins: 100 total
- Treasures: 1 chest (contains 10 coins)
- NPCs: 3 villagers (easy to find)
- Enemies: 3 goblins total
- Hazards: None (only bottomless pit)
- Platform Count: ~20 platforms
- Length: Short (1-2 minutes for new players)

**Collectible Placement**:
```gdscript
# Coins in breadcrumb trails
[C][C][C] across gap to guide jump
[C] [C] [C] leading to hidden chest
Loop of 10 coins around Crystal 2

# Crown Crystals
Crystal 1: On obvious platform (10 seconds in)
Crystal 2: Requires defeating goblin to reach
Crystal 3: On moving platform (requires timing)

# NPCs
Villager 1: Next to start (tutorial)
Villager 2: Behind tree (slight exploration)
Villager 3: On side platform near Crystal 3
```

#### 4.2: Level 1-2 "Leaping Meadows"
**File**: `scenes/levels/world1_level2.tscn`

**Design Goals**:
- Increase platforming challenge
- Multiple enemy encounters
- Introduce moving platforms
- First treasure chest requires exploration

**New Mechanics**:
- Faster moving platforms
- 2 goblins in same area (combo opportunity)
- Hidden path to bonus coins
- Crumbling platforms (grass gets darker, falls after 1 second)

**Specifications**:
- Time Targets: Gold 90s, Silver 120s, Bronze 180s
- Coins: 100 (20 in hidden area)
- Treasures: 1 chest (contains costume piece)
- NPCs: 3 villagers
- Enemies: 6 goblins, 1 cannon turret
- Hazards: Spike traps, crumbling platforms
- Platform Count: ~30
- Length: 2-3 minutes

**Layout**:
```
[Start] → [Linear moving platforms] → [Checkpoint] →
[Enemy gauntlet - 3 goblins] → [Crystal 1] →
[Hidden path with chest] ← OR → [Main path with Crystal 2] →
[Crumbling platform section] → [Cannon turret] →
[Final moving platforms] → [Crystal 3] → [Goal]
```

#### 4.3: Level 1-3 "Crown Peak"
**File**: `scenes/levels/world1_level3.tscn`

**Design Goals**:
- World 1 finale
- All mechanics from previous levels
- Unlock double jump after completion
- Challenging but fair

**New Mechanics**:
- Armored knights (2-hit enemies)
- Multiple path choices (easy/hard)
- Vertical climbing section
- Boss-lite encounter (3 enemies at once)

**Specifications**:
- Time Targets: Gold 120s, Silver 180s, Bronze 240s
- Coins: 100 (30 on hard path, 70 on easy path)
- Treasures: 2 chests
- NPCs: 3 villagers (one very hidden)
- Enemies: 8 goblins, 2 knights, 2 cannons
- Hazards: Spikes, crumbling platforms, bottomless pits
- Platform Count: ~40
- Length: 3-5 minutes

**Layout**:
```
[Start] → [Choice Point] →
    Easy Path: [More platforms, fewer enemies] → [Crystal 1] → [Merge]
    Hard Path: [Precision jumps, more coins] → [Chest] → [Merge]
[Merge] → [Checkpoint] → [Vertical Section] → [Crystal 2] →
[Mini-Boss Arena: 2 knights + 3 goblins] → [Crystal 3] → [Goal]
```

**Unlock on Completion**:
```gdscript
# In level complete handler
if level_id == "world1_level3":
    GameManager.unlock_double_jump()
    show_ability_unlocked_popup("Double Jump")
```

#### 4.4: Level 1-Bonus "Grassland Gauntlet"
**File**: `scenes/levels/world1_bonus.tscn`

**Design Goals**:
- Extra-hard challenge for completionists
- Required: Double jump from Level 1-3
- Focus on precision platforming
- High coin rewards

**Specifications**:
- Time Targets: Gold 180s, Silver 240s, Bronze 300s
- Coins: 100 (all valuable, many hidden)
- Treasures: 2 chests (costume pieces)
- NPCs: 3 villagers (very hidden)
- Enemies: 12 enemies (mixed types)
- Hazards: All types
- Platform Count: ~50
- Length: 4-6 minutes
- **Unlocked by**: Collecting all 9 stars in World 1

**Layout**:
```
[Start] → [Precision jumps requiring double jump] →
[Enemy gauntlet] → [Crystal 1] → [Checkpoint] →
[Vertical platforming (hardest section)] → [Crystal 2] →
[Final challenge: moving platforms + enemies] → [Crystal 3] → [Goal]
```

#### 4.5: Level Design Pipeline/Tools
**Files**: `tools/level_editor_additions.gd` (Editor plugin)

Create reusable tools:
- [ ] Platform snapping grid
- [ ] Coin placement tool (breadcrumb mode)
- [ ] Enemy patrol waypoint editor
- [ ] Collectible placement guide (shows distances)
- [ ] Playtesting timer (shows where players die most)

**Level Template**:
```gdscript
# level_template.tscn
# Contains:
- WorldEnvironment (sky, lighting)
- Ground plane
- Player spawn point
- Camera controller
- GameUI
- GameHUD
- PauseMenu
- CollisionDebugger
- Collectibles (organized in folders)
  - CrownCrystals/
  - Coins/
  - Chests/
  - Hearts/
- Enemies/
  - Goblins/
  - Knights/
  - Cannons/
- Platforms/
  - Static/
  - Moving/
  - Crumbling/
- NPCs/
- Hazards/
  - Spikes/
  - Pits/
```

#### 4.6: Level Data Resources
**Files**: `resources/levels/world1_data.tres` (new)

Store level metadata in resources:
```gdscript
# level_data.gd (resource script)
extends Resource
class_name LevelDataResource

@export var level_id: String = ""
@export var world: int = 1
@export var level_number: int = 1
@export var display_name: String = ""
@export var description: String = ""

# Targets
@export var gold_time: float = 60.0
@export var silver_time: float = 90.0
@export var bronze_time: float = 120.0

# Content counts (for validation)
@export var coin_count: int = 100
@export var crystal_count: int = 3
@export var npc_count: int = 3
@export var chest_count: int = 1

# Unlocks
@export var unlocks_ability: String = ""  # "double_jump", "ground_pound", etc.
@export var required_ability: String = ""  # Ability needed to access level
```

### Phase 4 Deliverables
✅ 4 fully playable World 1 levels
✅ Level design pipeline established
✅ Tutorial system functional
✅ All collectibles placeable in editor
✅ Enemy AI working in actual levels
✅ Level data resources system

### Phase 4 Testing Checklist
- [ ] Level 1-1 teaches all basics clearly
- [ ] All levels completable with target times achievable
- [ ] Coin counts exactly 100 per level
- [ ] No unreachable collectibles
- [ ] Enemy patrols don't overlap incorrectly
- [ ] Checkpoints placed fairly
- [ ] NPCs all rescuable
- [ ] Treasure chests contain correct items
- [ ] Performance: Solid 60fps throughout all levels
- [ ] Double jump unlocks after 1-3

---

## PHASE 5: UI & Progression Systems
**Duration**: 1 week
**Status**: Not Started
**Dependencies**: Phase 4

### Goals
Create world map, level select, game over screen, victory screen, and overall progression tracking.

### Implementation Tasks

#### 5.1: World Map UI
**Files**: `scenes/ui/world_map.tscn` (new), `scripts/world_map.gd` (new)

**Design**:
- Island-style map with 5 world islands
- Floating in clouds background
- Each level is a node on island
- Lines connect levels showing progression
- Visual indicators: locked/unlocked, stars earned

**Implementation**:
```gdscript
# world_map.gd
extends Control

@onready var world_container: Node2D = $WorldIslands

class LevelNode extends TextureButton:
    var level_id: String
    var stars_earned: int = 0
    var is_locked: bool = true

func _ready():
    populate_map()
    position_camera_on_current_world()

func populate_map():
    for world_num in range(1, 6):
        var world_island = create_world_island(world_num)

        for level_num in range(1, 5):  # 3 main + 1 bonus
            var level_node = create_level_node(world_num, level_num)
            world_island.add_child(level_node)

func create_level_node(world: int, level: int) -> LevelNode:
    var node = LevelNode.new()
    node.level_id = "world%d_level%d" % [world, level]

    # Load progress data
    var level_stats = GameManager.get_level_stats(node.level_id)
    node.stars_earned = level_stats.get("stars", 0)
    node.is_locked = not GameManager.is_level_unlocked(node.level_id)

    # Set visual state
    if node.is_locked:
        node.texture_normal = locked_texture
        node.disabled = true
    else:
        node.texture_normal = unlocked_texture
        update_star_display(node)

    node.pressed.connect(_on_level_selected.bind(node.level_id))

    return node

func _on_level_selected(level_id: String):
    GameManager.load_level_by_id(level_id)
```

**Visual Design**:
```
World 1 Island (Grassland)
   [1-1]---[1-2]---[1-3]
      \     |     /
       \    |    /
        [1-Bonus]

World 2 Island (Desert)
   [2-1]---[2-2]---[2-3]
                    |
                [2-Bonus]

... etc for Worlds 3-5
```

#### 5.2: Enhanced Level Select
**Files**: `scripts/level_select.gd` (extend existing)

**Current State**: Basic button grid exists

**Enhancements**:
- [ ] Show level thumbnail/preview image
- [ ] Display best time
- [ ] Show collected items: X/100 coins, Y/3 NPCs
- [ ] Hover shows level description
- [ ] Click plays preview animation

**Implementation**:
```gdscript
# level_select.gd (enhanced)
func _create_level_button(level_data: LevelDataResource) -> PanelContainer:
    var container = PanelContainer.new()

    # Level thumbnail
    var thumbnail = TextureRect.new()
    thumbnail.texture = load("res://thumbnails/%s.png" % level_data.level_id)

    # Stats display
    var stats = VBoxContainer.new()

    # Stars
    var stars_label = HBoxContainer.new()
    for i in range(3):
        var star = TextureRect.new()
        star.texture = star_filled if i < level_stats.stars else star_empty
        stars_label.add_child(star)

    # Time
    var time_label = Label.new()
    if level_stats.has("best_time"):
        time_label.text = "Best: %s" % format_time(level_stats.best_time)

    # Completion
    var completion = Label.new()
    completion.text = "Coins: %d/100 | NPCs: %d/3" % [
        level_stats.coins_collected,
        level_stats.npcs_rescued
    ]

    # Assemble
    stats.add_child(stars_label)
    stats.add_child(time_label)
    stats.add_child(completion)

    container.add_child(thumbnail)
    container.add_child(stats)

    return container
```

#### 5.3: Level Complete Screen
**Files**: `scenes/ui/level_complete.tscn` (extend existing), `scripts/level_complete.gd`

**Current State**: Basic completion screen exists

**Enhancements**:
- [ ] Animated star reveals (with sound)
- [ ] Coin counter counts up from 0 to final
- [ ] Show medal earned for each star
- [ ] Display new unlocks (if any)
- [ ] Show next level preview
- [ ] Confetti particles on 100% completion

**Implementation**:
```gdscript
# level_complete.gd
func display_results(level_stats: Dictionary):
    # Show victory banner
    play_victory_fanfare()

    # Animate each stat
    await animate_stat_reveal("LEVEL COMPLETE!", 0.5)

    # Animate stars (one at a time)
    for i in range(3):
        if level_stats.stars >= i + 1:
            await reveal_star(i, get_star_reason(i))

    # Count up coins
    await count_up_animation(
        coin_label,
        0,
        level_stats.coins_collected,
        1.0
    )

    # Show time
    time_label.text = "Time: %s" % format_time(level_stats.completion_time)
    if level_stats.time_medal_earned:
        show_time_medal_icon()

    # NPCs rescued
    npc_label.text = "Villagers Rescued: %d/3" % level_stats.npcs_rescued

    # Total completion
    var completion_pct = calculate_level_completion(level_stats)
    completion_label.text = "Completion: %.0f%%" % completion_pct

    if completion_pct >= 100.0:
        spawn_confetti()

    # Show new unlocks
    if level_stats.has("unlocked_ability"):
        show_unlock_popup(level_stats.unlocked_ability)

    # Show buttons
    show_action_buttons()

func get_star_reason(star_index: int) -> String:
    match star_index:
        0: return "Level Complete!"
        1: return "All Coins Collected!"
        2: return "Fast Time!"
        _: return ""
```

#### 5.4: Game Over Screen
**Files**: `scenes/ui/game_over.tscn` (new), `scripts/game_over.gd` (new)

**Design**:
- Friendly, encouraging tone ("Try again!")
- Shows how many coins lost (-10)
- Options: Retry from checkpoint, Level select, Main menu
- Background: Darkened current level view

**Implementation**:
```gdscript
# game_over.gd
extends Control

@onready var coins_lost_label: Label = $Panel/CoinsLost
@onready var retry_button: Button = $Panel/Buttons/RetryButton
@onready var level_select_button: Button = $Panel/Buttons/LevelSelectButton

func _ready():
    # Show coins penalty
    coins_lost_label.text = "Coins Lost: -10"

    # Connect buttons
    retry_button.pressed.connect(_on_retry)
    level_select_button.pressed.connect(_on_level_select)

    # Focus retry by default
    retry_button.grab_focus()

func _on_retry():
    GameManager.respawn_at_checkpoint()

func _on_level_select():
    GameManager.return_to_level_select()
```

**Trigger Game Over**:
```gdscript
# player.gd
func _on_died():
    if GameManager.total_coins >= 10:
        GameManager.lose_coins(10)
    else:
        GameManager.lose_coins(GameManager.total_coins)

    show_game_over_screen()
```

#### 5.5: Checkpoint System
**Files**: `scripts/checkpoint.gd` (new), `scenes/objects/checkpoint.tscn` (new)

- [ ] Flag pole with color change on activation
- [ ] Auto-activate when player passes
- [ ] Sparkle effect on activation
- [ ] "Checkpoint!" text popup
- [ ] Save player respawn position

**Implementation**:
```gdscript
# checkpoint.gd
extends Area3D

@export var checkpoint_id: String
var is_activated: bool = false

@onready var flag: MeshInstance3D = $FlagPole/Flag
@onready var particles: GPUParticles3D = $ActivationParticles

func _ready():
    body_entered.connect(_on_body_entered)

    # Check if already activated
    if GameManager.is_checkpoint_activated(
        GameManager.current_level_data.level_id,
        checkpoint_id
    ):
        set_activated_visuals()

func _on_body_entered(body):
    if body.is_in_group("player") and not is_activated:
        activate()

func activate():
    is_activated = true

    # Visual feedback
    set_activated_visuals()
    particles.restart()

    # Audio
    play_checkpoint_sound()

    # UI popup
    show_checkpoint_text()

    # Save progress
    GameManager.set_checkpoint(
        GameManager.current_level_data.level_id,
        checkpoint_id,
        global_position
    )

func set_activated_visuals():
    # Change flag color from green to red
    var material = flag.get_surface_override_material(0)
    material.albedo_color = Color.RED
```

#### 5.6: NPC Rescue System
**Files**: `scripts/npc_villager.gd` (new), `scenes/characters/villager.tscn` (new)

- [ ] 3 trapped NPCs per level
- [ ] Caged character models
- [ ] Interaction prompt ("Press E to rescue")
- [ ] Happy dance animation on rescue
- [ ] Reward: 20 coins + contribution to 100%
- [ ] Track rescued NPCs in save

**Implementation**:
```gdscript
# npc_villager.gd
extends Node3D

@export var npc_id: String
@export var dialogue: String = "Thank you for rescuing me!"
@export var coin_reward: int = 20

var is_rescued: bool = false
var player_nearby: bool = false

@onready var cage: Node3D = $Cage
@onready var character: Node3D = $Character
@onready var interaction_prompt: Label3D = $InteractionPrompt

func _ready():
    interaction_prompt.visible = false

    # Check if already rescued
    if GameManager.is_npc_rescued(
        GameManager.current_level_data.level_id,
        npc_id
    ):
        set_rescued_state()

func _process(_delta):
    if player_nearby and Input.is_action_just_pressed("interact"):
        if not is_rescued:
            rescue()

func _on_interaction_area_body_entered(body):
    if body.is_in_group("player"):
        player_nearby = true
        if not is_rescued:
            interaction_prompt.visible = true

func _on_interaction_area_body_exited(body):
    if body.is_in_group("player"):
        player_nearby = false
        interaction_prompt.visible = false

func rescue():
    is_rescued = true

    # Remove cage
    cage.queue_free()

    # Play happy dance
    character.play("victory_dance")

    # Show dialogue
    show_dialogue_bubble(dialogue)

    # Reward
    GameManager.add_coins(coin_reward)
    spawn_coin_particles(coin_reward)

    # Save progress
    GameManager.mark_npc_rescued(
        GameManager.current_level_data.level_id,
        npc_id
    )

    # Check if all NPCs rescued in world
    if GameManager.are_all_world_npcs_rescued(GameManager.current_world):
        show_world_complete_bonus()

func set_rescued_state():
    is_rescued = true
    cage.queue_free()
    interaction_prompt.queue_free()
```

#### 5.7: Overall Progression Tracking
**Files**: `scripts/game_manager.gd` (extend existing)

**Add to GameManager**:
```gdscript
# Progression data
var total_stars_earned: int = 0
var total_coins_collected: int = 0
var total_npcs_rescued: int = 0
var worlds_completed: Array[int] = []
var abilities_unlocked: Array[String] = []
var costumes_unlocked: Array[String] = []

# Completion tracking
func get_overall_completion() -> float:
    var total_possible_stars = 135  # 3 per level × 20 levels
    var total_possible_coins = 2000  # 100 per level × 20 levels
    var total_possible_npcs = 60     # 3 per level × 20 levels

    var star_completion = (total_stars_earned as float / total_possible_stars) * 100.0
    var coin_completion = (total_coins_collected as float / total_possible_coins) * 100.0
    var npc_completion = (total_npcs_rescued as float / total_possible_npcs) * 100.0

    return (star_completion + coin_completion + npc_completion) / 3.0

func unlock_next_world():
    var current_world_stars = count_world_stars(current_world)
    var required_stars = get_required_stars_for_world(current_world + 1)

    if current_world_stars >= required_stars:
        worlds_unlocked.append(current_world + 1)
        save_game()
        return true
    return false
```

### Phase 5 Deliverables
✅ World map with visual progression
✅ Enhanced level select with stats
✅ Animated level complete screen
✅ Game over screen with retry options
✅ Checkpoint system working
✅ NPC rescue missions functional
✅ Overall progression tracking

### Phase 5 Testing Checklist
- [ ] World map shows correct lock states
- [ ] Stars display accurately on all UI screens
- [ ] Level complete animations play smoothly
- [ ] Checkpoints save and load correctly
- [ ] NPCs stay rescued after level restart
- [ ] Game over respawns at correct checkpoint
- [ ] All progression data persists across sessions
- [ ] 100% completion triggers special celebration

---

## PHASE 6: Worlds 2-4 Production (12 Levels)
**Duration**: 3 weeks
**Status**: Not Started
**Dependencies**: Phase 5

### Goals
Create Worlds 2, 3, and 4 with unique themes and progressive difficulty. 3 main levels + 1 bonus per world.

### World 2: Desert Dunes

**Theme**: Sandy platforms, beige/tan colors, pyramids, palm trees, hot atmosphere

**New Mechanics**:
- **Quicksand**: Slows player movement
- **Sand Geysers**: Launch player upward on timer
- **Sandstorms**: Reduce visibility, push player sideways
- **Scarab Enemies**: Roll toward player, must be jumped precisely

**Levels**:
- 2-1: "Oasis Arrival" - Introduction to desert theme
- 2-2: "Pyramid Pathways" - Vertical pyramid climbing
- 2-3: "Sandstorm Summit" - Harsh weather challenges
- 2-Bonus: "Ancient Ruins" - Hard puzzle-platforming

**Asset Usage**:
- Cube_Sand_Single.gltf for platforms
- Palm trees, cacti for decoration
- Pyramid structures

**Implementation Time**: 1 week

### World 3: Forest Canopy

**Theme**: Wooden platforms, tree trunks, green/brown colors, vertical climbing focus

**New Mechanics**:
- **Vines**: Swinging (hold to swing, release to jump)
- **Bounce Mushrooms**: Like springs but bouncy
- **Tree Climbing**: Vertical sections with branch platforms
- **Spider Enemies**: Drop from above on webs

**Levels**:
- 3-1: "Treetop Trail" - Introduction to forest
- 3-2: "Canopy Climb" - Vertical platforming challenges
- 3-3: "Ancient Grove" - Complex tree navigation
- 3-Bonus: "Sky Forest" - Extreme heights, thin platforms

**Asset Usage**:
- Cube_Wood_Single.gltf for platforms
- Tree models for decoration/climbing
- Vine objects

**New Enemies**:
- **Spiders**: Hang from webs, drop when player near
- **Tree Goblins**: Green goblins that climb trees

**Implementation Time**: 1 week

### World 4: Mountain Peaks

**Theme**: Rocky gray platforms, snow caps, windy atmosphere, hazardous gaps

**New Mechanics**:
- **Wind**: Pushes player horizontally (must compensate)
- **Falling Rocks**: Triggered by weight, crush player
- **Ice Patches**: Slippery surfaces (reduced traction)
- **Avalanche Sections**: Run forward as rocks fall behind

**Levels**:
- 4-1: "Rocky Ascent" - Introduction to mountains
- 4-2: "Windy Peaks" - Wind-based challenges
- 4-3: "Summit Push" - Hardest platforming yet
- 4-Bonus: "Avalanche Escape" - Timed run level

**Asset Usage**:
- Cube_Rock_Single.gltf for platforms
- Stone/mountain structures
- Snow particles

**New Enemies**:
- **Mountain Goats**: Charge at player (knockback)
- **Rock Golems**: Slow, tanky, 3 HP

**Implementation Time**: 1 week

### Level Design Checklist (Per Level)

Each level must have:
- [ ] 100 coins placed (verified with counter)
- [ ] 3 Crown Crystals (logical progression)
- [ ] 1-2 treasure chests (hidden but findable)
- [ ] 3 NPCs to rescue (varying difficulty to find)
- [ ] 2-3 checkpoints (fair spacing)
- [ ] Clear start/end goals
- [ ] 5-10 enemy encounters
- [ ] Time targets set (Gold/Silver/Bronze)
- [ ] Multiple paths (easy/hard route)
- [ ] Secret areas with bonus coins
- [ ] Proper lighting (no too-dark areas)
- [ ] Performance test (60fps maintained)

### Quality Standards

**Difficulty Curve** (per world):
- Level X-1: Introduction (Easy)
- Level X-2: Application (Medium)
- Level X-3: Mastery (Hard)
- Level X-Bonus: Expert (Very Hard)

**Pacing**:
- Action section (enemies/hazards)
- Rest section (coins/platforming)
- Checkpoint
- Challenge section (combines mechanics)
- Crystal reward
- Repeat pattern

**Visual Variety**:
- Change platform heights/sizes
- Vary background elements
- Use different enemy combinations
- Mix hazard types

### Phase 6 Deliverables
✅ 12 additional levels (Worlds 2-4)
✅ 3 new enemy types
✅ 8 new environmental mechanics
✅ All collectibles and secrets placed
✅ Performance optimized

### Phase 6 Testing Checklist
- [ ] All 12 levels completable
- [ ] Time targets achievable but challenging
- [ ] No unreachable collectibles
- [ ] Enemy variety keeps gameplay fresh
- [ ] New mechanics taught clearly
- [ ] Difficulty progression feels natural
- [ ] Each world has distinct visual identity
- [ ] All bonus levels require appropriate skills
- [ ] Checkpoints prevent frustration
- [ ] 60fps maintained across all levels

---

## PHASE 7: World 5 & Boss Battle
**Duration**: 2 weeks
**Status**: Not Started
**Dependencies**: Phase 6

### Goals
Create final world with castle theme, culminating in Goblin King boss battle. Hardest challenges in game.

### World 5: Castle Kingdom

**Theme**: Stone castle platforms, medieval structures, dark atmosphere, final challenges

**Design Philosophy**:
- Combine all mechanics from previous worlds
- Hardest platforming challenges
- Most enemies per level
- Complex layouts with multiple routes
- Builds tension toward final boss

**Levels**:
- 5-1: "Castle Gates" - Fortress approach
- 5-2: "Tower Siege" - Vertical castle climbing
- 5-3: "Throne Room Approach" - Pre-boss gauntlet
- 5-Boss: "Goblin King Battle" - Final boss
- 5-Bonus: "Secret Vault" - Ultimate challenge

**New Elements**:
- **Drawbridges**: Timed platforms that raise/lower
- **Portcullises**: Gates that open/close on trigger
- **Ballista**: Fires large projectiles
- **Lava Pits**: In castle interior, damage over time
- **Chandelier Platforms**: Swinging platforms

### Implementation Tasks

#### 7.1: Level 5-1 "Castle Gates"
**File**: `scenes/levels/world5_level1.tscn`

**Design**:
- Introduction to castle theme
- Combine mechanics: moving platforms + enemies + hazards
- Show castle in background (destination)
- Knight enemies introduced in force (6-8 total)

**Specifications**:
- Time Targets: Gold 150s, Silver 210s, Bronze 300s
- Coins: 100
- Treasures: 2 chests
- NPCs: 3 (well hidden)
- Enemies: 6 goblins, 4 knights, 2 cannons
- Hazards: Spikes, lava, falling rocks
- Platform Count: ~45
- Length: 4-6 minutes

#### 7.2: Level 5-2 "Tower Siege"
**File**: `scenes/levels/world5_level2.tscn`

**Design**:
- Primarily vertical (climb tower)
- Spiral staircase pattern
- Enemy encounters at each floor
- Windows show progress (view from height)

**Specifications**:
- Time Targets: Gold 180s, Silver 240s, Bronze 360s
- Coins: 100 (spread vertically)
- Treasures: 2 chests (one at very top)
- NPCs: 3
- Enemies: 10 goblins, 5 knights, 3 cannons
- Hazards: All types
- Platform Count: ~50
- Length: 5-7 minutes

#### 7.3: Level 5-3 "Throne Room Approach"
**File**: `scenes/levels/world5_level3.tscn`

**Design**:
- Final level before boss
- Gauntlet of hardest challenges
- All mechanics combined
- Builds tension
- Ends at throne room door (boss entry)

**Specifications**:
- Time Targets: Gold 210s, Silver 300s, Bronze 420s
- Coins: 100
- Treasures: 2 chests
- NPCs: 3 (very hidden)
- Enemies: 12 goblins, 6 knights, 4 cannons
- Hazards: All types, high density
- Platform Count: ~60
- Length: 6-8 minutes

#### 7.4: Level 5-Boss "Goblin King Battle"
**File**: `scenes/levels/world5_boss.tscn`

**Boss Arena Design**:
- Circular arena (40 unit diameter)
- 6 platforms arranged in ring
- Center platform (boss starting position)
- Platforms disappear in Phase 3
- Trapped room (cannot leave)
- Dramatic lighting

**Boss Implementation**:

##### Phase 1: Bomb Throwing (10-8 HP)
```gdscript
# goblin_king.gd - Phase 1
func phase_1_behavior(delta):
    # Walk around arena
    patrol_arena(2.0)  # Speed: 2.0

    # Throw bombs every 3 seconds
    bomb_timer -= delta
    if bomb_timer <= 0:
        throw_bomb(player.global_position)
        bomb_timer = 3.0

    # Summon minions every 10 seconds
    summon_timer -= delta
    if summon_timer <= 0:
        summon_goblin_minions(2)
        summon_timer = 10.0
```

**Bomb Projectile**:
```gdscript
# bomb.gd
extends Area3D

var velocity: Vector3
const GRAVITY = -15.0
const FUSE_TIME = 2.0

func _physics_process(delta):
    velocity.y += GRAVITY * delta
    global_position += velocity * delta

    if is_on_floor():
        explode()

func explode():
    create_explosion_area(3.0)  # 3 unit radius
    spawn_explosion_particles()
    play_explosion_sound()
    queue_free()
```

##### Phase 2: Jump Shockwaves (7-5 HP)
```gdscript
# goblin_king.gd - Phase 2
func phase_2_behavior(delta):
    # Jump to random platform
    jump_timer -= delta
    if jump_timer <= 0:
        var target_platform = arena_platforms.pick_random()
        jump_to_platform(target_platform)
        jump_timer = 4.0

    # Throw bombs faster
    bomb_timer -= delta
    if bomb_timer <= 0:
        throw_bomb(player.global_position)
        bomb_timer = 2.0

    # Summon more minions
    summon_timer -= delta
    if summon_timer <= 0:
        summon_goblin_minions(3)
        summon_timer = 8.0

func jump_to_platform(platform: Node3D):
    # Leap arc
    var jump_duration = 1.0
    var tween = create_tween()
    tween.tween_property(self, "global_position", platform.global_position, jump_duration)

    await tween.finished
    create_shockwave(5.0)  # 5 unit radius

func create_shockwave(radius: float):
    # Player must jump to avoid
    var shockwave_area = Area3D.new()
    # Check if player is on ground
    if player.is_on_floor():
        player.take_damage(1)

    # Visual ring expands
    show_shockwave_ring_animation(radius)
```

##### Phase 3: Desperate Fury (4-1 HP)
```gdscript
# goblin_king.gd - Phase 3
func phase_3_behavior(delta):
    # Platforms start disappearing
    if not platforms_disappearing:
        start_platform_despawn_sequence()
        platforms_disappearing = true

    # Fast movement
    move_speed = 6.0
    chase_player(delta)

    # Rapid attacks
    attack_timer -= delta
    if attack_timer <= 0:
        if randf() > 0.5:
            throw_double_bombs()
        else:
            dash_attack_player()
        attack_timer = 1.5

    # Continuous minion spawns
    summon_timer -= delta
    if summon_timer <= 0:
        summon_goblin_minions(1)
        summon_timer = 5.0

func start_platform_despawn_sequence():
    # Platforms disappear in order, one every 5 seconds
    for platform in arena_platforms:
        await get_tree().create_timer(5.0).timeout
        despawn_platform(platform)
```

**Boss Defeat**:
```gdscript
func _on_boss_defeated():
    # Slow motion
    Engine.time_scale = 0.3

    # Dramatic death animation
    play_defeat_animation()

    # Camera zoom
    camera_zoom_to_boss(2.0)

    await get_tree().create_timer(3.0).timeout

    # Restore time
    Engine.time_scale = 1.0

    # Victory screen
    show_final_victory_screen()

    # Unlock special reward
    GameManager.unlock_golden_costume()

    # Credits
    play_credits_sequence()
```

#### 7.5: Level 5-Bonus "Secret Vault"
**File**: `scenes/levels/world5_bonus.tscn`

**Design**:
- Unlocked by: Collecting all stars in Worlds 1-5
- Absolute hardest level
- Requires all abilities
- Precision platforming + combat mastery
- Huge coin reward (200 coins)
- Exclusive costume unlock

**Specifications**:
- Time Targets: Gold 300s, Silver 420s, Bronze 600s
- Coins: 200 (double normal)
- Treasures: 3 chests (all contain rare costumes)
- NPCs: 3 (extremely hidden)
- Enemies: 15+ enemies (all types)
- Hazards: All types, maximum density
- Platform Count: ~70
- Length: 8-12 minutes

### Final Boss UI

**Boss Health Bar**:
```gdscript
# boss_health_bar.gd
extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var boss_name: Label = $BossName
@onready var phase_label: Label = $PhaseLabel

func _ready():
    boss_name.text = "GOBLIN KING"
    update_health(10, 10)

func update_health(current: int, max: int):
    health_bar.max_value = max
    health_bar.value = current

    # Change color by phase
    if current > 7:
        health_bar.modulate = Color.GREEN
    elif current > 4:
        health_bar.modulate = Color.YELLOW
    else:
        health_bar.modulate = Color.RED

func show_phase_transition(phase: int):
    phase_label.text = "PHASE %d" % phase
    phase_label.visible = true

    # Animate
    var tween = create_tween()
    tween.tween_property(phase_label, "modulate:a", 0.0, 2.0)
```

### Phase 7 Deliverables
✅ 4 World 5 levels complete
✅ Full Goblin King boss battle
✅ All mechanics integrated
✅ Final challenges polished
✅ Secret vault level (ultimate challenge)
✅ Boss health UI
✅ Victory sequence

### Phase 7 Testing Checklist
- [ ] Boss phases transition smoothly
- [ ] All boss attacks are telegraphed fairly
- [ ] Boss is challenging but beatable
- [ ] Platform despawn in Phase 3 is manageable
- [ ] Final levels feel climactic
- [ ] Secret vault truly requires all abilities
- [ ] Victory sequence is satisfying
- [ ] Game can be completed start-to-finish

---

## PHASE 8: Audio & Polish
**Duration**: 1 week
**Status**: Not Started
**Dependencies**: Phase 7

### Goals
Add all audio, particle effects, screen effects, and visual polish to make game feel professional.

### Implementation Tasks

#### 8.1: Music System
**Files**: `scripts/audio/music_manager.gd` (new)

**Music Tracks Needed**:
1. Main Menu Theme (cheerful, adventurous)
2. World 1 Music (grassland, upbeat)
3. World 2 Music (desert, exotic)
4. World 3 Music (forest, mysterious)
5. World 4 Music (mountain, tense)
6. World 5 Music (castle, epic)
7. Boss Battle Theme (intense, dramatic)
8. Victory Jingle (short, triumphant)
9. Game Over Music (sad but encouraging)

**Implementation**:
```gdscript
# music_manager.gd
extends Node

var current_track: AudioStreamPlayer
var music_tracks = {
    "main_menu": preload("res://audio/music/main_menu.ogg"),
    "world1": preload("res://audio/music/world1_grassland.ogg"),
    "world2": preload("res://audio/music/world2_desert.ogg"),
    # ... etc
}

func play_music(track_name: String, fade_in: bool = true):
    if current_track:
        fade_out_current(0.5)

    current_track = AudioStreamPlayer.new()
    current_track.stream = music_tracks[track_name]
    current_track.bus = "Music"
    add_child(current_track)

    if fade_in:
        fade_in_track(current_track, 0.5)

    current_track.play()

func fade_in_track(track: AudioStreamPlayer, duration: float):
    track.volume_db = -80
    var tween = create_tween()
    tween.tween_property(track, "volume_db", 0.0, duration)
```

**Music Triggers**:
- Main menu: On menu load
- Level start: On level ready
- Boss battle: When entering boss arena
- Victory: On level complete
- Game over: On player death

#### 8.2: Sound Effects System
**Files**: `scripts/audio/sfx_manager.gd` (new)

**Sound Effects Needed**:
1. **Player**:
   - Jump (light "boing")
   - Double jump (higher pitch boing)
   - Land (soft thud)
   - Dash (whoosh)
   - Ground pound (heavy slam)
   - Take damage (short "ow!")
   - Death (comedic "wah!")

2. **Collectibles**:
   - Coin (bright "pling")
   - Crown Crystal (magical chime + sparkle)
   - Treasure chest open (treasure jingle)
   - Heart pickup (healing chime)
   - Power-up collect (power-up sound)

3. **Enemies**:
   - Enemy defeat (comedic "poof")
   - Goblin attack (grunt)
   - Knight attack (armor clank)
   - Cannonball fire (boom)
   - Boss roar (intimidating)

4. **Environment**:
   - Checkpoint activation (fanfare)
   - Door/gate open (mechanical)
   - Crumbling platform (cracking)
   - Switch activate (click)
   - Spring bounce (boing)

5. **UI**:
   - Menu navigate (soft click)
   - Menu select (confirm beep)
   - Menu back (cancel beep)
   - Star appear (twinkle)
   - Level unlock (success chime)

**Implementation**:
```gdscript
# sfx_manager.gd
extends Node

var sfx_pool: Array[AudioStreamPlayer3D] = []
const POOL_SIZE = 20

func _ready():
    # Create pool of 3D sound players
    for i in range(POOL_SIZE):
        var player = AudioStreamPlayer3D.new()
        player.bus = "SFX"
        add_child(player)
        sfx_pool.append(player)

func play_sfx(sound: AudioStream, position: Vector3 = Vector3.ZERO, volume: float = 0.0):
    var player = get_available_player()
    if player:
        player.stream = sound
        player.global_position = position
        player.volume_db = volume
        player.play()

func play_sfx_2d(sound: AudioStream, volume: float = 0.0):
    # For UI sounds
    var player = AudioStreamPlayer.new()
    player.stream = sound
    player.bus = "SFX"
    player.volume_db = volume
    add_child(player)
    player.play()

    # Auto-cleanup
    player.finished.connect(player.queue_free)

func get_available_player() -> AudioStreamPlayer3D:
    for player in sfx_pool:
        if not player.playing:
            return player
    return sfx_pool[0]  # Fallback: interrupt oldest
```

**Audio Bus Configuration**:
```gdscript
# default_bus_layout.tres (already exists, extend)
- Master (0 dB)
  - Music (-6 dB)
  - SFX (0 dB)
  - Voice (-3 dB)  # For NPC dialogue if added
```

#### 8.3: Particle Effects
**Files**: Various particle scene files

**Particle Effects Needed**:

1. **Collectibles**:
   - Coin sparkle (golden particles)
   - Crystal glow (pink shimmer)
   - Chest burst (gold coins flying out)
   - Heart heal (green sparkles)

2. **Movement**:
   - Jump dust (small puff on takeoff)
   - Landing dust (larger puff)
   - Dash trail (speed lines)
   - Double jump sparkles (colorful)
   - Ground pound impact (shockwave ring)

3. **Combat**:
   - Enemy poof (smoke cloud)
   - Bomb explosion (fire + smoke)
   - Damage hit (red flash)
   - Player death (stars circling)

4. **Environment**:
   - Checkpoint activation (golden sparkles)
   - Waterfall mist (if water present)
   - Lava bubbles
   - Torch flames

**Example Particle System**:
```gdscript
# coin_sparkle.tscn (GPUParticles3D)
[node name="CoinSparkle" type="GPUParticles3D"]
amount = 20
lifetime = 0.5
explosiveness = 0.8
visibility_aabb = AABB(-2, -2, -2, 4, 4, 4)

[sub_resource type="ParticleProcessMaterial"]
emission_shape = 1  # Sphere
emission_sphere_radius = 0.3
gravity = Vector3(0, 2, 0)  # Upward
initial_velocity_min = 1.0
initial_velocity_max = 2.0
angular_velocity_min = -180
angular_velocity_max = 180
scale_curve = # Fade out
color = Color(1, 0.9, 0.3, 1)  # Golden
```

#### 8.4: Screen Effects
**Files**: `scripts/camera_effects.gd` (new)

**Screen Shake**:
```gdscript
# camera_effects.gd
extends Node

var camera: Camera3D
var shake_amount: float = 0.0
var shake_duration: float = 0.0
var original_position: Vector3

func shake_camera(duration: float, intensity: float):
    shake_duration = duration
    shake_amount = intensity
    original_position = camera.position

func _process(delta):
    if shake_duration > 0:
        shake_duration -= delta

        # Random offset
        var offset = Vector3(
            randf_range(-shake_amount, shake_amount),
            randf_range(-shake_amount, shake_amount),
            0
        )

        camera.position = original_position + offset

        if shake_duration <= 0:
            camera.position = original_position
```

**Damage Flash**:
```gdscript
# player.gd
func flash_damage():
    # Red overlay flash
    var flash_overlay = ColorRect.new()
    flash_overlay.color = Color(1, 0, 0, 0.3)
    flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    get_tree().root.add_child(flash_overlay)

    var tween = create_tween()
    tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.2)
    tween.finished.connect(flash_overlay.queue_free)
```

**Slow Motion** (boss defeat):
```gdscript
func apply_slow_motion(duration: float, scale: float = 0.3):
    Engine.time_scale = scale
    await get_tree().create_timer(duration * scale).timeout
    Engine.time_scale = 1.0
```

**Freeze Frame** (crystal collection):
```gdscript
func freeze_game(duration: float):
    get_tree().paused = true
    await get_tree().create_timer(duration).timeout
    get_tree().paused = false
```

#### 8.5: Animation Polish
**Files**: Various scene files

**Idle Animations**:
- Coins: Rotate + gentle bob
- Crystals: Rotate + pulse glow
- Flags: Cloth wave
- Trees: Gentle sway
- Clouds: Slow drift

**Environmental Motion**:
```gdscript
# coin_idle_animation.gd
extends Node3D

@export var bob_speed: float = 2.0
@export var bob_height: float = 0.2
@export var rotation_speed: float = 2.0

var time: float = 0.0
var start_y: float

func _ready():
    start_y = global_position.y

func _process(delta):
    time += delta

    # Bob up and down
    global_position.y = start_y + sin(time * bob_speed) * bob_height

    # Rotate
    rotate_y(delta * rotation_speed)
```

#### 8.6: Visual Feedback Enhancement
**Files**: Various UI and object scripts

**Number Popups** (coins collected):
```gdscript
# floating_text.gd
extends Label3D

func animate_collection(value: int):
    text = "+%d" % value
    modulate = Color(1, 0.9, 0.3)

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position:y", position.y + 2.0, 1.0)
    tween.tween_property(self, "modulate:a", 0.0, 1.0)

    tween.finished.connect(queue_free)
```

**Combo Display**:
```gdscript
# combo_display.gd
extends Label

func show_combo(count: int):
    text = "x%d COMBO!" % count

    # Scale punch
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
```

**Confetti** (100% completion):
```gdscript
# confetti.gd
extends GPUParticles3D

func spawn_confetti():
    amount = 100
    emitting = true

    # Colorful, falling particles
    # Use multiple colors, long lifetime
```

### Phase 8 Deliverables
✅ All music tracks implemented
✅ All sound effects added
✅ Particle effects for all major actions
✅ Screen effects (shake, flash, slow-mo)
✅ Animation polish on environment
✅ Visual feedback enhanced
✅ Audio settings functional

### Phase 8 Testing Checklist
- [ ] Music loops seamlessly
- [ ] Music transitions smoothly between areas
- [ ] All sound effects play correctly
- [ ] Sound effects don't overlap unpleasantly
- [ ] Volume settings affect all audio
- [ ] Particle effects don't cause lag
- [ ] Screen shake feels impactful not nauseating
- [ ] Visual feedback makes gameplay readable
- [ ] Audio-visual feedback is satisfying

---

## PHASE 9: Testing & Balancing
**Duration**: 1 week
**Status**: Not Started
**Dependencies**: Phase 8

### Goals
Full game testing, difficulty balancing, bug fixing, performance optimization, final polish.

### Implementation Tasks

#### 9.1: Full Playthrough Testing

**Complete Game Testing**:
- [ ] Play through all 20 levels start to finish
- [ ] Attempt to collect all collectibles
- [ ] Try to find all secrets
- [ ] Test all ability unlocks
- [ ] Verify all checkpoints work
- [ ] Confirm all NPCs rescuable
- [ ] Test all shop purchases
- [ ] Verify save/load across sessions

**Testing Scenarios**:
1. **New Player Experience**:
   - Start fresh save
   - Play World 1 without prior knowledge
   - Track: time to understand controls, deaths
   - Note: confusing moments

2. **Completionist Playthrough**:
   - Collect every coin
   - Rescue every NPC
   - Open every chest
   - Get all 3 stars per level
   - Track: how long 100% takes

3. **Speedrun Test**:
   - Rush through levels as fast as possible
   - Verify time targets are achievable
   - Check for sequence breaks

#### 9.2: Difficulty Balancing

**Star Target Adjustment**:
```gdscript
# Level timing analyzer
func analyze_level_times():
    var level_times = []

    for level in all_levels:
        # 5 playtests per level
        var times = []
        for i in range(5):
            times.append(get_playtester_time(level))

        # Average
        var avg_time = times.reduce(func(a, b): return a + b) / times.size()

        # Set targets
        var gold = avg_time * 0.8  # 20% faster than average
        var silver = avg_time * 1.0
        var bronze = avg_time * 1.3

        level.gold_time = gold
        level.silver_time = silver
        level.bronze_time = bronze
```

**Enemy Balance**:
- [ ] Goblins: 1 HP, easy to defeat
- [ ] Knights: 2 HP, feel tankier
- [ ] Cannons: Predictable, avoidable
- [ ] Bats: Annoying but not unfair
- [ ] Boss: 10 HP feels like appropriate length

**Health Balance**:
- [ ] 3 hearts feels right
- [ ] Extra heart unlock valuable
- [ ] Heart pickups placed fairly
- [ ] Damage invincibility window sufficient

**Coin Economy**:
- [ ] 100 coins per level achievable
- [ ] Hidden coins rewarding
- [ ] Shop prices feel fair
- [ ] Coin loss on death not too punishing

#### 9.3: Performance Optimization

**Target Performance**: 60fps on mid-range hardware

**Optimization Checklist**:
- [ ] Reduce draw calls (batch static meshes)
- [ ] Use LOD (Level of Detail) for distant objects
- [ ] Occlusion culling for large levels
- [ ] Particle effect limits (max 200 particles)
- [ ] Audio source limits (max 32 simultaneous)
- [ ] Enemy pooling (reuse defeated enemies)
- [ ] Collectible pooling (reuse collected items)

**Performance Testing**:
```gdscript
# performance_monitor.gd
extends Node

var fps_history: Array[float] = []

func _process(_delta):
    fps_history.append(Engine.get_frames_per_second())
    if fps_history.size() > 300:  # 5 seconds at 60fps
        fps_history.pop_front()

    var avg_fps = fps_history.reduce(func(a, b): return a + b) / fps_history.size()

    if avg_fps < 55:
        push_warning("Performance issue detected! Average FPS: %.1f" % avg_fps)
```

**Memory Management**:
- [ ] No memory leaks (nodes properly freed)
- [ ] Scenes preloaded efficiently
- [ ] Textures compressed appropriately
- [ ] Audio files compressed (OGG format)

#### 9.4: Bug Fixing

**Common Bug Categories**:

1. **Physics Bugs**:
   - Player clipping through platforms
   - Getting stuck in geometry
   - Incorrect collision responses
   - Floating/falling through floor

2. **State Bugs**:
   - Abilities not unlocking
   - Progress not saving
   - Checkpoints not working
   - NPCs respawning after rescue

3. **UI Bugs**:
   - Incorrect coin counts
   - Stars not displaying
   - Menu navigation issues
   - HUD elements overlapping

4. **Gameplay Bugs**:
   - Enemies not attacking
   - Collectibles not collecting
   - Doors not opening
   - Soft locks (can't progress)

**Bug Tracking**:
```gdscript
# Create bug_tracker.md
# Level: X-X
# Steps to Reproduce:
# Expected Behavior:
# Actual Behavior:
# Severity: Critical/High/Medium/Low
# Status: Open/In Progress/Fixed/Won't Fix
```

#### 9.5: Accessibility Features

**Settings to Add**:
- [ ] Colorblind mode (change collectible colors)
- [ ] Larger text option
- [ ] Reduced motion (fewer particles)
- [ ] Extended invincibility frames
- [ ] Assisted aiming (auto-aim jump attacks)
- [ ] God mode (for testing/accessibility)

**Implementation**:
```gdscript
# accessibility_settings.gd
extends Node

var colorblind_mode: bool = false
var large_text: bool = false
var reduced_motion: bool = false
var extended_invincibility: bool = false
var assisted_mode: bool = false
var god_mode: bool = false

func apply_settings():
    if colorblind_mode:
        # Change coin color from gold to blue
        # Change crystal color to high-contrast
        pass

    if large_text:
        # Increase UI font sizes by 25%
        pass

    if extended_invincibility:
        # Double invincibility duration
        pass
```

#### 9.6: Final Polish Pass

**Polish Checklist (Per Level)**:
- [ ] All platforms aligned properly
- [ ] No z-fighting (overlapping geometry)
- [ ] Consistent visual style
- [ ] Proper lighting (no too-dark areas)
- [ ] All collectibles visible
- [ ] Enemy patrols make sense
- [ ] Checkpoint placement logical
- [ ] Starting position clear
- [ ] Goal clearly marked
- [ ] Background elements interesting

**Menu Polish**:
- [ ] Smooth transitions between screens
- [ ] Consistent button styles
- [ ] Proper text alignment
- [ ] Loading screens (if needed)
- [ ] Credits screen complete

**Audio Polish**:
- [ ] Volume levels balanced
- [ ] No audio clipping
- [ ] Proper fade in/out
- [ ] Music loops seamlessly
- [ ] Sound effects positioned correctly

#### 9.7: Build & Export

**Export Settings**:
```gdscript
# export_presets.cfg
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter="*.md,*.txt,tools/*"

[preset.1]
name="Linux/X11"
# ... similar settings

[preset.2]
name="macOS"
# ... similar settings

[preset.3]
name="Web (HTML5)"
# ... for browser version
```

**Build Checklist**:
- [ ] Windows .exe builds and runs
- [ ] Linux binary builds and runs
- [ ] macOS app builds and runs
- [ ] Web version works in browser
- [ ] All assets included
- [ ] Correct icon/splash screen
- [ ] Version number set
- [ ] No debug code included

### Phase 9 Deliverables
✅ Complete game tested extensively
✅ All major bugs fixed
✅ Difficulty balanced
✅ Performance optimized (60fps)
✅ Accessibility features added
✅ Final polish complete
✅ Builds created for all platforms

### Phase 9 Testing Checklist
- [ ] Game completable start to finish
- [ ] No game-breaking bugs remain
- [ ] Performance stable across all levels
- [ ] Save/load works reliably
- [ ] All achievements/collectibles accessible
- [ ] UI fully functional
- [ ] Audio mix balanced
- [ ] Game feels polished and complete
- [ ] Playtesters can complete without major issues
- [ ] Ready for release

---

## APPENDIX A: Asset Organization

### Directory Structure
```
plat_godot/
├── assets/
│   ├── models/
│   │   └── quaternius_platformer/
│   │       ├── characters/
│   │       ├── platforms/
│   │       ├── structures/
│   │       └── collectibles/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── textures/
│       ├── ui/
│       └── particles/
├── scenes/
│   ├── characters/
│   │   ├── player/
│   │   ├── enemies/
│   │   └── npcs/
│   ├── levels/
│   │   ├── world1/
│   │   ├── world2/
│   │   ├── world3/
│   │   ├── world4/
│   │   └── world5/
│   ├── collectibles/
│   ├── platforms/
│   ├── hazards/
│   ├── interactive/
│   └── ui/
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── managers/
│   ├── ui/
│   ├── collectibles/
│   └── utilities/
├── resources/
│   ├── levels/
│   ├── abilities/
│   └── costumes/
└── tools/
    └── editor/
```

---

## APPENDIX B: Code Architecture

### Singleton Pattern (Autoloads)
```gdscript
GameManager        # Game state, progression, save/load
SettingsManager    # User preferences
AudioManager       # Music and SFX playback
LevelSession       # Current level state
GameConstants      # Global constants
```

### Component Pattern
```gdscript
HealthComponent    # Reusable health system
PatrolComponent    # Enemy patrol behavior
CollectibleComponent  # Base collectible functionality
InteractionComponent  # E to interact prompts
```

### State Machine Pattern
```gdscript
PlayerStateMachine     # Player states (idle, walk, jump, etc.)
BossStateMachine       # Boss phase states
UIStateMachine         # UI screen transitions
```

---

## APPENDIX C: Development Tools

### Recommended Godot Plugins
- **Godot Jolt** (better physics)
- **GDScript Formatter** (code formatting)
- **Asset Placer** (level design helper)
- **Performance Monitor** (profiling)

### External Tools
- **Audacity** (audio editing)
- **Aseprite** (sprite/texture editing)
- **Blender** (model adjustments if needed)
- **Git** (version control)

---

## APPENDIX D: Reusable Systems from Demo

### Already Implemented (Keep These)
1. **Player Movement** (scripts/player.gd)
   - Extend with new abilities
2. **Camera Follow** (scripts/camera_follow.gd)
   - Works well, minor tweaks only
3. **Game Manager** (scripts/game_manager.gd)
   - Core architecture solid, extend
4. **Settings System** (scripts/settings_manager.gd)
   - Complete, just add new options
5. **HUD System** (scripts/game_hud.gd)
   - Modify display, keep structure
6. **Pause Menu** (scripts/pause_menu.gd)
   - Perfect as-is
7. **Moving Platforms** (scripts/moving_platform.gd)
   - Reuse for all worlds
8. **Level Session** (scripts/level_session.gd)
   - Extend with new tracking

### Demo Levels to Retire
- Level 1-5 are tech demos
- Keep as templates/examples
- Replace with proper World 1 levels
- Reuse platform layouts where appropriate

---

## APPENDIX E: Timeline Summary

| Week | Phase | Major Deliverables |
|------|-------|-------------------|
| 1 | Phase 1 | Enhanced character controller |
| 2-3 | Phase 2 | Combat & enemy system |
| 4 | Phase 3 | Collectibles & economy |
| 5-6 | Phase 4 | World 1 (4 levels) |
| 7 | Phase 5 | UI & progression systems |
| 8-10 | Phase 6 | Worlds 2-4 (12 levels) |
| 11-12 | Phase 7 | World 5 & boss battle |
| 13 | Phase 8 | Audio & polish |
| 14 | Phase 9 | Testing & balancing |

**Total**: ~14 weeks for complete game

---

## APPENDIX F: Success Metrics

### Technical Targets
- 60 FPS on mid-range hardware
- Load times < 3 seconds per level
- Save/load < 1 second
- No game-breaking bugs
- Memory usage < 2GB

### Content Targets
- 20 playable levels
- 135 possible stars (3 per level × 20 + bonus)
- 2,000 total coins
- 60 NPCs to rescue
- 5 unique worlds
- 10+ hours of gameplay (completionist)

### Player Experience Goals
- Tutorial teaches all mechanics clearly
- Difficulty curve feels fair
- Controls feel responsive and fun
- Visual style is cohesive
- Audio enhances experience
- Secrets reward exploration
- 100% completion feels achievable

---

**END OF ROADMAP**

Ready to begin Phase 1: Enhanced Character Controller?
