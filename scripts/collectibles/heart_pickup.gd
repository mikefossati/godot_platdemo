extends Area3D
class_name HeartPickup

## Heart Pickup - Restores player health
## Part of Phase 3: Collectibles & Economy System
## Placed before difficult sections, respawns on level restart

# Heart properties
@export var heal_amount: int = 1  ## Amount of health to restore

# Visual animation parameters
@export var rotation_speed: float = 2.0  ## Rotation speed
@export var bob_height: float = 0.2  ## Bobbing height
@export var bob_speed: float = 2.5  ## Bobbing speed
@export var pulse_speed: float = 2.0  ## Scale pulsing speed
@export var pulse_amount: float = 0.1  ## How much to pulse

# Internal state
var start_y: float = 0.0
var time_passed: float = 0.0
var base_scale: Vector3 = Vector3.ONE

# Node references
@onready var heart_model: Node3D = $HeartModel if has_node("HeartModel") else null
@onready var glow_particles: GPUParticles3D = $GlowParticles if has_node("GlowParticles") else null
@onready var collect_particles: GPUParticles3D = $CollectParticles if has_node("CollectParticles") else null
@onready var omni_light: OmniLight3D = $OmniLight3D if has_node("OmniLight3D") else null


func _ready() -> void:
	# Store initial Y position and scale
	start_y = position.y
	if heart_model:
		base_scale = heart_model.scale

	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Set up visual effects
	_setup_visual()


func _process(delta: float) -> void:
	# Rotate for visual appeal
	rotate_y(rotation_speed * delta)

	# Bobbing animation
	time_passed += delta * bob_speed
	position.y = start_y + sin(time_passed) * bob_height

	# Pulsing scale animation
	if heart_model:
		var pulse = 1.0 + sin(time_passed * pulse_speed) * pulse_amount
		heart_model.scale = base_scale * pulse

	# Pulse the light
	if omni_light:
		omni_light.light_energy = 1.5 + sin(time_passed * pulse_speed) * 0.3


func _on_body_entered(body: Node3D) -> void:
	if OS.is_debug_build():
		print("HeartPickup: Body entered - %s" % body.name)

	if body.is_in_group("player"):
		collect(body)
	elif OS.is_debug_build():
		print("HeartPickup: Body is not in player group")


func collect(player_node: Node3D) -> void:
	# Check if player has HealthComponent
	if not player_node.has_node("HealthComponent"):
		push_warning("HeartPickup: Player has no HealthComponent!")
		return

	var health_component = player_node.get_node("HealthComponent")

	# Check if player needs healing
	var current_hp = health_component.current_health
	var max_hp = health_component.max_health

	if OS.is_debug_build():
		print("HeartPickup: Player HP = %d/%d" % [current_hp, max_hp])

	if current_hp >= max_hp:
		# Player already at full health, don't collect
		if OS.is_debug_build():
			print("HeartPickup: Player at full health, cannot collect")
		return

	# Disable collision to prevent double collection
	set_deferred("monitoring", false)

	# Heal the player
	if health_component.has_method("heal"):
		health_component.heal(heal_amount)
	else:
		# Fallback: directly modify health
		health_component.current_health = min(
			health_component.current_health + heal_amount,
			health_component.max_health
		)

	# Play effects
	_play_heal_effects()

	# Play sound
	_play_sound("heal")

	print("HeartPickup: Healed player for %d HP (was %d/%d, now %d/%d)" % [
		heal_amount, current_hp, max_hp, health_component.current_health, max_hp
	])

	# Remove the heart
	queue_free()


func _setup_visual() -> void:
	# Set up the glow particles
	if glow_particles:
		glow_particles.emitting = true

	# Set up the omni light
	if omni_light:
		omni_light.light_color = Color(1.0, 0.3, 0.3)  # Red glow
		omni_light.light_energy = 1.5
		omni_light.omni_range = 3.0

	# Make heart more visible
	if heart_model:
		# Add slight upward offset for visibility
		heart_model.position.y += 0.2


func _play_heal_effects() -> void:
	# Play collection particles
	if collect_particles:
		collect_particles.emitting = true

	# Create a sparkle effect at player position
	# TODO: Add more dramatic healing visual in Phase 8


func _play_sound(sound_name: String) -> void:
	# TODO: Implement in Phase 8 (Audio & Polish)
	if OS.is_debug_build():
		print("Playing sound: %s" % sound_name)


## Reset for object pooling (if used later)
func reset_pooled_object() -> void:
	time_passed = 0.0
	monitoring = true
	monitorable = true
	position.y = start_y
	if heart_model:
		heart_model.scale = base_scale
