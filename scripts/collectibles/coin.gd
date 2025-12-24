extends Area3D
class_name Coin

## Coin Collectible - Collectible currency with magnetic attraction
## Part of Phase 3: Collectibles & Economy System

# Coin types
enum CoinType {
	REGULAR = 1,   # Yellow, worth 1 coin
	BIG = 5,       # Blue, worth 5 coins
	HIDDEN = 10    # Gold, worth 10 coins
}

# Coin properties
@export var coin_type: CoinType = CoinType.REGULAR
@export var attract_radius: float = 1.5  ## Distance at which coin starts attracting to player
@export var attract_speed: float = 10.0  ## Speed of magnetic pull

# Visual animation parameters
@export var rotation_speed: float = 3.0  ## Rotation speed in radians per second
@export var bob_height: float = 0.2  ## Bobbing animation height
@export var bob_speed: float = 2.0  ## Bobbing animation speed

# Internal state
var being_attracted: bool = false
var player: Node3D = null
var start_y: float = 0.0
var time_passed: float = 0.0

# Particle and sound effects
@onready var particles: GPUParticles3D = $CollectParticles if has_node("CollectParticles") else null
@onready var coin_model: Node3D = $CoinModel if has_node("CoinModel") else null


func _ready() -> void:
	# Store initial Y position for bobbing
	start_y = position.y

	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Set up visual appearance based on coin type
	_setup_visual()

	# Start with particles off (will trigger on collection)
	if particles:
		particles.emitting = false

	# Add to coin group for power-ups to find
	add_to_group("coin")

	# Find player for magnetic attraction
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	# Rotate for visual appeal
	rotate_y(rotation_speed * delta)

	# Bobbing animation
	time_passed += delta * bob_speed
	position.y = start_y + sin(time_passed) * bob_height

	# Check for player proximity for magnetic attraction
	if not being_attracted and player:
		var distance = global_position.distance_to(player.global_position)
		if distance < attract_radius:
			being_attracted = true

	# Magnetic pull toward player
	if being_attracted and player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * attract_speed * delta


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		collect(body)


func collect(player_node: Node3D) -> void:
	# Disable collision to prevent double collection
	set_deferred("monitoring", false)

	# Add coins to GameManager
	var coin_value = int(coin_type)
	GameManager.add_coins(coin_value)

	# Track coin collection in LevelSession
	if LevelSession:
		LevelSession.record_coin_collected(coin_value)

	# Play particle effect
	_spawn_particle_effect()

	# Play sound effect
	_play_sound("coin_collect")

	# Remove the coin
	queue_free()


## Setup visual appearance based on coin type
func _setup_visual() -> void:
	if not coin_model:
		return

	# Apply visual differences based on coin type
	match coin_type:
		CoinType.REGULAR:
			# Yellow coin - default appearance
			if coin_model:
				coin_model.scale = Vector3(1.0, 1.0, 1.0)
		CoinType.BIG:
			# Blue coin (bigger value)
			if coin_model:
				coin_model.scale = Vector3(1.5, 1.5, 1.5)
			# TODO: Apply blue material in Phase 8
		CoinType.HIDDEN:
			# Gold coin (highest value)
			if coin_model:
				coin_model.scale = Vector3(1.8, 1.8, 1.8)
			# TODO: Apply gold material in Phase 8


## Spawn particle effect on collection
func _spawn_particle_effect() -> void:
	if particles:
		particles.emitting = true
	else:
		# Create simple particle burst if no particle node exists
		var particle_scene = GPUParticles3D.new()
		get_parent().add_child(particle_scene)
		particle_scene.global_position = global_position
		particle_scene.one_shot = true
		particle_scene.emitting = true

		# Auto-delete after emission
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particle_scene):
			particle_scene.queue_free()


## Play sound effect
func _play_sound(sound_name: String) -> void:
	# TODO: Implement audio system in Phase 8
	# For now, we'll just print a debug message
	if OS.is_debug_build():
		print("Playing sound: %s" % sound_name)


## Set player reference for magnetic attraction
func set_player(player_node: Node3D) -> void:
	player = player_node


## Reset for object pooling (if used later)
func reset_pooled_object() -> void:
	time_passed = 0.0
	being_attracted = false
	player = null
	monitoring = true
	monitorable = true
	start_y = position.y
