extends Area3D
class_name CrownCrystal

## Crown Crystal - Primary level objective collectible
## Part of Phase 3: Collectibles & Economy System
## 3 per level required to unlock next level

# Crystal properties
@export var crystal_id: int = 0  ## Unique ID within the level (0, 1, or 2)

# Visual animation parameters
@export var rotation_speed: float = 1.5  ## Slower rotation for dramatic effect
@export var bob_height: float = 0.3  ## Larger bobbing for visibility
@export var bob_speed: float = 1.5  ## Slower bob for dramatic effect
@export var glow_intensity: float = 1.5  ## Emission strength

# Collection sequence parameters
@export var freeze_duration: float = 0.8  ## How long to freeze game
@export var camera_zoom_duration: float = 0.5  ## Camera zoom time
@export var total_sequence_duration: float = 1.5  ## Total collection sequence

# Internal state
var start_y: float = 0.0
var time_passed: float = 0.0
var has_been_collected: bool = false

# Node references
@onready var gem_model: Node3D = $GemModel if has_node("GemModel") else null
@onready var light_pillar: MeshInstance3D = $LightPillar if has_node("LightPillar") else null
@onready var glow_particles: GPUParticles3D = $GlowParticles if has_node("GlowParticles") else null
@onready var burst_particles: GPUParticles3D = $BurstParticles if has_node("BurstParticles") else null
@onready var omni_light: OmniLight3D = $OmniLight3D if has_node("OmniLight3D") else null


func _ready() -> void:
	# Store initial Y position
	start_y = position.y

	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Set up visual effects
	_setup_visual()

	# Check if already collected (persistence)
	if GameManager.current_level_data:
		var level_id = GameManager.current_level_data.level_id
		var already_collected = _is_crystal_already_collected(level_id, crystal_id)
		if OS.is_debug_build():
			print("CrownCrystal: Level=%s, Crystal=%d, AlreadyCollected=%s, Position=%s" % [level_id, crystal_id, already_collected, global_position])
			print("  - GemModel exists: %s" % (gem_model != null))
			print("  - OmniLight exists: %s" % (omni_light != null))
			print("  - Visible: %s" % visible)
		if already_collected:
			has_been_collected = true
			queue_free()  # Already collected, don't show
	else:
		if OS.is_debug_build():
			print("CrownCrystal: No level data yet, crystal %d will spawn at %s" % [crystal_id, global_position])


func _process(delta: float) -> void:
	if has_been_collected:
		return

	# Rotate slowly for dramatic effect
	rotate_y(rotation_speed * delta)

	# Bobbing animation
	time_passed += delta * bob_speed
	position.y = start_y + sin(time_passed) * bob_height

	# Pulse the light
	if omni_light:
		omni_light.light_energy = 2.0 + sin(time_passed * 2.0) * 0.5


func _on_body_entered(body: Node3D) -> void:
	if has_been_collected:
		return

	if body.is_in_group("player"):
		collect(body)


func collect(player_node: Node3D) -> void:
	if has_been_collected:
		return

	has_been_collected = true

	# Disable collision to prevent double collection
	set_deferred("monitoring", false)

	# Start dramatic collection sequence
	_play_collection_sequence(player_node)

	# Mark as collected in GameManager
	if GameManager.current_level_data:
		var level_id = GameManager.current_level_data.level_id
		_mark_crystal_collected(level_id, crystal_id)

	# Track crystal collection in LevelSession
	if LevelSession:
		LevelSession.record_crystal_collected()

	# Check if all crystals are collected
	_check_level_completion()


## Play the dramatic collection sequence
func _play_collection_sequence(player_node: Node3D) -> void:
	# Play burst particles
	if burst_particles:
		burst_particles.emitting = true

	# Play collection sound (fanfare)
	_play_crystal_fanfare()

	# Freeze the game
	_freeze_game()

	# Camera zoom effect
	_camera_zoom_to_crystal()

	# Wait for sequence to complete
	await get_tree().create_timer(total_sequence_duration).timeout

	# Unfreeze the game
	_unfreeze_game()

	# Remove the crystal
	queue_free()


## Setup visual effects
func _setup_visual() -> void:
	# Set up gem model material if needed
	if gem_model:
		# The gem model is already set up in the scene
		pass

	# Set up the light pillar if it exists
	if light_pillar:
		var pillar_material = StandardMaterial3D.new()
		pillar_material.albedo_color = Color(1.0, 0.4, 0.8, 0.3)  # Pink with transparency
		pillar_material.emission_enabled = true
		pillar_material.emission = Color(1.0, 0.4, 0.8) * glow_intensity
		pillar_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pillar_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		light_pillar.material_override = pillar_material

	# Set up the omni light
	if omni_light:
		omni_light.light_color = Color(1.0, 0.4, 0.8)  # Pink
		omni_light.light_energy = 2.0
		omni_light.omni_range = 5.0

	# Start glow particles if available
	if glow_particles:
		glow_particles.emitting = true


## Freeze the game for dramatic effect
func _freeze_game() -> void:
	# Slow down time instead of full freeze (feels better)
	Engine.time_scale = 0.3
	await get_tree().create_timer(freeze_duration * 0.3).timeout  # Account for time scale
	Engine.time_scale = 1.0


## Unfreeze the game
func _unfreeze_game() -> void:
	Engine.time_scale = 1.0


## Zoom camera to crystal
func _camera_zoom_to_crystal() -> void:
	# TODO: Implement camera zoom in Phase 4 when camera system is enhanced
	# For now, this is a placeholder
	pass


## Play crystal collection fanfare
func _play_crystal_fanfare() -> void:
	# TODO: Implement in Phase 8 (Audio & Polish)
	if OS.is_debug_build():
		print("Crystal %d collected! Fanfare plays!" % crystal_id)


## Check if crystal is already collected
func _is_crystal_already_collected(level_id: String, crystal_idx: int) -> bool:
	return GameManager.is_crystal_collected(level_id, crystal_idx)


## Mark crystal as collected
func _mark_crystal_collected(level_id: String, crystal_idx: int) -> void:
	# Update GameManager
	GameManager.collect_item(50)  # Worth 50 points

	# Track individual crystal collection in GameManager
	GameManager.collect_crown_crystal(level_id, crystal_idx)


## Check if all crystals collected to unlock next level
func _check_level_completion() -> void:
	# This will be handled by the level itself
	# The level checks if all 3 crystals (collectibles) are gathered
	pass
