extends Area3D
class_name Checkpoint

## Checkpoint - Save player progress within a level
## Part of Phase 4: World 1 Production
## When activated, saves respawn position for the player

# Checkpoint properties
@export var checkpoint_id: int = 0  ## Unique ID within the level

# Visual parameters
@export var inactive_color: Color = Color(0.5, 0.5, 0.5)
@export var active_color: Color = Color(0.2, 1.0, 0.2)
@export var pulse_speed: float = 2.0

# State
var is_activated: bool = false
var time_passed: float = 0.0

# Node references
@onready var mesh: MeshInstance3D = $Mesh if has_node("Mesh") else null
@onready var particles: GPUParticles3D = $ActivationParticles if has_node("ActivationParticles") else null
@onready var light: OmniLight3D = $OmniLight3D if has_node("OmniLight3D") else null


func _ready() -> void:
	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Set initial visual state
	_set_visual_state(false)


func _process(delta: float) -> void:
	if is_activated:
		# Pulse the light when active
		time_passed += delta * pulse_speed
		if light:
			light.light_energy = 2.0 + sin(time_passed) * 0.5


func _on_body_entered(body: Node3D) -> void:
	if OS.is_debug_build():
		print("Checkpoint: Body entered - %s" % body.name)

	if body.is_in_group("player") and not is_activated:
		activate(body)


func activate(player: Node3D) -> void:
	if is_activated:
		return

	is_activated = true

	# Save checkpoint position in LevelSession
	if LevelSession and LevelSession.has_method("set_checkpoint"):
		LevelSession.set_checkpoint(global_position)
	else:
		push_warning("Checkpoint: LevelSession.set_checkpoint() not available!")

	# Visual feedback
	_set_visual_state(true)

	# Play activation particles
	if particles:
		particles.emitting = true

	# Play sound
	_play_sound("checkpoint_activate")

	print("Checkpoint %d activated at: %s" % [checkpoint_id, global_position])


func _set_visual_state(active: bool) -> void:
	var target_color = active_color if active else inactive_color

	# Update mesh color
	if mesh:
		var material = mesh.get_surface_override_material(0)
		if material:
			material.albedo_color = target_color
		else:
			# Create new material if none exists
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = target_color
			new_material.emission_enabled = active
			new_material.emission = target_color * 2.0 if active else Color.BLACK
			mesh.set_surface_override_material(0, new_material)

	# Update light
	if light:
		light.light_color = target_color
		light.light_energy = 2.0 if active else 0.5


func _play_sound(sound_name: String) -> void:
	# TODO: Implement in Phase 8 (Audio & Polish)
	if OS.is_debug_build():
		print("Playing sound: %s" % sound_name)
