extends Area3D
class_name PowerUp

## PowerUp Base Class - Temporary power-ups with duration
## Part of Phase 3: Collectibles & Economy System
## Provides various temporary buffs to the player

# Power-up types
enum PowerUpType {
	SPEED_BOOST,       # 1.5x movement speed (yellow)
	INVINCIBILITY,     # No damage (rainbow)
	COIN_MAGNET,       # Auto-collect coins (purple)
	DOUBLE_COINS       # 2x coin value (gold)
}

# Power-up properties
@export var powerup_type: PowerUpType = PowerUpType.SPEED_BOOST
@export var duration: float = 10.0  ## How long the power-up lasts

# Visual animation parameters
@export var rotation_speed: float = 4.0  ## Fast rotation for power-ups
@export var bob_height: float = 0.25
@export var bob_speed: float = 3.0

# Internal state
var start_y: float = 0.0
var time_passed: float = 0.0

# Node references
@onready var model: Node3D = $PowerUpModel if has_node("PowerUpModel") else null
@onready var particles: GPUParticles3D = $GlowParticles if has_node("GlowParticles") else null
@onready var collect_particles: GPUParticles3D = $CollectParticles if has_node("CollectParticles") else null
@onready var omni_light: OmniLight3D = $OmniLight3D if has_node("OmniLight3D") else null


func _ready() -> void:
	# Store initial Y position
	start_y = position.y

	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Set up visual effects based on type
	_setup_visual()


func _process(delta: float) -> void:
	# Fast rotation for power-ups
	rotate_y(rotation_speed * delta)

	# Bobbing animation
	time_passed += delta * bob_speed
	position.y = start_y + sin(time_passed) * bob_height

	# Pulse the light
	if omni_light:
		omni_light.light_energy = 2.0 + sin(time_passed * 2.0) * 0.5


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		activate_powerup(body)


func activate_powerup(player: Node3D) -> void:
	# Disable collision to prevent double collection
	set_deferred("monitoring", false)

	# Apply the power-up effect
	match powerup_type:
		PowerUpType.SPEED_BOOST:
			_apply_speed_boost(player)
		PowerUpType.INVINCIBILITY:
			_apply_invincibility(player)
		PowerUpType.COIN_MAGNET:
			_apply_coin_magnet(player)
		PowerUpType.DOUBLE_COINS:
			_apply_double_coins(player)

	# Play collection effects
	if collect_particles:
		collect_particles.emitting = true

	# Play sound
	_play_sound("powerup_collect")

	print("PowerUp: Activated %s for %.1fs" % [PowerUpType.keys()[powerup_type], duration])

	# Remove the power-up
	queue_free()


func _apply_speed_boost(player: Node3D) -> void:
	if player.has_method("apply_speed_boost"):
		player.apply_speed_boost(duration, 1.5)
	else:
		# Fallback: directly modify max_speed
		var original_speed = player.max_speed if "max_speed" in player else 5.0
		player.max_speed = original_speed * 1.5

		# Reset after duration
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(player):
			player.max_speed = original_speed


func _apply_invincibility(player: Node3D) -> void:
	# Check if player has HealthComponent
	if player.has_node("HealthComponent"):
		var health_component = player.get_node("HealthComponent")
		health_component.invulnerable = true

		# Visual feedback: make player flash/glow
		_create_invincibility_visual(player)

		# Reset after duration
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(health_component):
			health_component.invulnerable = false
	else:
		push_warning("PowerUp: Player has no HealthComponent for invincibility!")


func _apply_coin_magnet(player: Node3D) -> void:
	if player.has_method("enable_coin_magnet"):
		player.enable_coin_magnet(duration)
	else:
		# Fallback: increase attraction radius on all coins
		_boost_all_coin_magnets()

		# Reset after duration
		await get_tree().create_timer(duration).timeout
		_reset_all_coin_magnets()


func _apply_double_coins(player: Node3D) -> void:
	# Set coin multiplier in GameManager
	if GameManager.has_method("set_coin_multiplier"):
		GameManager.set_coin_multiplier(2.0)
	else:
		# Fallback: use internal coin multiplier
		if "_coin_multiplier" in GameManager:
			var original_multiplier = GameManager._coin_multiplier
			GameManager._coin_multiplier = 2.0

			# Reset after duration
			await get_tree().create_timer(duration).timeout
			if GameManager:
				GameManager._coin_multiplier = original_multiplier
		else:
			push_warning("PowerUp: GameManager has no coin_multiplier!")


func _boost_all_coin_magnets() -> void:
	var coins = get_tree().get_nodes_in_group("coin")
	for coin in coins:
		if "attract_radius" in coin:
			coin.attract_radius = 5.0  # Increase from default 1.5


func _reset_all_coin_magnets() -> void:
	var coins = get_tree().get_nodes_in_group("coin")
	for coin in coins:
		if "attract_radius" in coin:
			coin.attract_radius = 1.5  # Reset to default


func _create_invincibility_visual(player: Node3D) -> void:
	# Create a rainbow shimmer effect
	# TODO: Implement proper visual in Phase 8
	pass


func _setup_visual() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()

	match powerup_type:
		PowerUpType.SPEED_BOOST:
			# Yellow glow
			material.albedo_color = Color(1.0, 1.0, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 0.2) * 0.8
			if omni_light:
				omni_light.light_color = Color(1.0, 1.0, 0.2)

		PowerUpType.INVINCIBILITY:
			# Rainbow/white glow
			material.albedo_color = Color(1.0, 1.0, 1.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 1.0) * 1.0
			if omni_light:
				omni_light.light_color = Color(1.0, 1.0, 1.0)

		PowerUpType.COIN_MAGNET:
			# Purple glow
			material.albedo_color = Color(0.8, 0.2, 1.0)
			material.emission_enabled = true
			material.emission = Color(0.8, 0.2, 1.0) * 0.8
			if omni_light:
				omni_light.light_color = Color(0.8, 0.2, 1.0)

		PowerUpType.DOUBLE_COINS:
			# Gold glow
			material.albedo_color = Color(1.0, 0.8, 0.0)
			material.metallic = 0.8
			material.emission_enabled = true
			material.emission = Color(1.0, 0.8, 0.0) * 0.8
			if omni_light:
				omni_light.light_color = Color(1.0, 0.8, 0.0)

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Apply material to model if available
	if model:
		var mesh_instance = _find_mesh_instance(model)
		if mesh_instance and mesh_instance is MeshInstance3D:
			mesh_instance.material_override = material

	# Set up particles
	if particles:
		particles.emitting = true

	# Set up light
	if omni_light:
		omni_light.light_energy = 2.0
		omni_light.omni_range = 4.0


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null


func _play_sound(sound_name: String) -> void:
	# TODO: Implement in Phase 8 (Audio & Polish)
	if OS.is_debug_build():
		print("Playing sound: %s" % sound_name)
