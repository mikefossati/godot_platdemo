extends Boss

## GoblinKing - The final boss of World 1.
## Implements a 3-phase attack pattern.

# Preload scenes for minions and projectiles
const BOMB_SCENE = preload("res://scenes/projectiles/bomb.tscn")
const GOBLIN_MINION_SCENE = preload("res://scenes/enemies/goblin.tscn")

@export_group("Goblin King Settings")
@export var arena_platforms: Array[Node3D] = []

@onready var animation_player = get_node_or_null("AnimationPlayer")  # Type: AnimationPlayer

var attack_timer: float = 0.0
var player_reference = null  # Type: Player
var move_speed: float = 2.0  # Boss movement speed (for phase transitions)

func _ready() -> void:
	super._ready()
	health_component.max_health = 10
	health_component.current_health = 10
	attack_timer = 3.0 # Initial delay before first attack

	# Find the player in the scene
	player_reference = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	attack_timer -= delta
	if attack_timer <= 0:
		execute_attack_pattern()
	
	move_and_slide()


func execute_attack_pattern() -> void:
	match current_phase:
		1:
			# Phase 1: Throw a bomb, reset timer
			throw_bomb()
			attack_timer = 3.0
		2:
			# Phase 2: Jump attack, reset timer
			jump_attack()
			attack_timer = 4.0
		3:
			# Phase 3: Throw two bombs, reset timer
			throw_double_bombs()
			attack_timer = 1.5


func transition_to_phase(phase: int) -> void:
	print("Goblin King entering phase %d" % phase)
	match phase:
		2:
			# Start of Phase 2: Summon 3 goblins
			move_speed = 4.0
			for i in range(3):
				spawn_minion()
		3:
			# Start of Phase 3: Start despawning platforms
			start_platform_despawn()
			# Continuously spawn minions in phase 3
			var timer = get_tree().create_timer(5.0)
			timer.timeout.connect(spawn_minion)


# ========== ATTACK IMPLEMENTATIONS ==========

func throw_bomb() -> void:
	if not player_reference:
		player_reference = get_tree().get_first_node_in_group("player") as Player
		if not player_reference:
			return

	# animation_player.play("throw")
	var bomb = BOMB_SCENE.instantiate()
	get_tree().root.add_child(bomb)
	bomb.global_position = global_position + Vector3(0, 1.5, 0)

	# Aim the bomb at the player's position
	bomb.launch_at_target(player_reference.global_position)

func throw_double_bombs() -> void:
	throw_bomb()
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(throw_bomb)

func jump_attack() -> void:
	# animation_player.play("jump_charge")
	velocity.y = 15.0 # Large jump
	# On landing, a shockwave should be created. This can be handled
	# by checking is_on_floor() after a jump.

func spawn_minion() -> void:
	var minion = GOBLIN_MINION_SCENE.instantiate()
	get_tree().root.add_child(minion)
	# Position the minion at a random spawn point in the arena
	minion.global_position = global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))

func start_platform_despawn() -> void:
	# Logic to randomly make platforms disappear
	if arena_platforms.size() > 0:
		var platform = arena_platforms.pick_random()
		if is_instance_valid(platform):
			platform.queue_free()
		
		# Repeat this action every few seconds
		var timer = get_tree().create_timer(4.0)
		timer.timeout.connect(start_platform_despawn)
