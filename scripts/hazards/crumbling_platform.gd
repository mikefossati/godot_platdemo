extends StaticBody3D
class_name CrumblingPlatform

## Crumbling Platform - Platform that falls after player steps on it
## Part of Phase 4: World 1 Production
## Used in Level 1-2 "Leaping Meadows" and beyond

# Platform behavior
@export var shake_delay: float = 0.5  ## Time before platform starts shaking
@export var fall_delay: float = 1.0  ## Total time before platform falls
@export var respawn_delay: float = 3.0  ## Time until platform respawns

# Visual feedback
@export var warning_color: Color = Color(0.6, 0.4, 0.2)  ## Darker color when unstable
@export var shake_intensity: float = 0.05  ## How much to shake

# Internal state
var player_on_platform: bool = false
var time_stepped_on: float = 0.0
var is_falling: bool = false
var is_respawning: bool = false
var original_position: Vector3
var original_color: Color

# Node references
@onready var mesh: MeshInstance3D = $Mesh if has_node("Mesh") else null
@onready var collision: CollisionShape3D = $CollisionShape3D if has_node("CollisionShape3D") else null
@onready var detection_area: Area3D = $DetectionArea if has_node("DetectionArea") else null
@onready var warning_particles: GPUParticles3D = $WarningParticles if has_node("WarningParticles") else null


func _ready() -> void:
	# Store original position and color
	original_position = global_position

	# Get original material color
	if mesh:
		var material = mesh.get_surface_override_material(0)
		if material:
			original_color = material.albedo_color
		else:
			# Get from mesh's material
			var mesh_material = mesh.mesh.surface_get_material(0)
			if mesh_material:
				original_color = mesh_material.albedo_color
			else:
				original_color = Color.WHITE

	# Connect detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)
	else:
		push_error("CrumblingPlatform: DetectionArea not found! Platform won't detect player.")


func _process(delta: float) -> void:
	if is_falling or is_respawning:
		return

	if player_on_platform:
		time_stepped_on += delta

		# Start shaking after shake_delay
		if time_stepped_on > shake_delay:
			_apply_shake()
			_set_warning_visual(true)

		# Fall after fall_delay
		if time_stepped_on >= fall_delay:
			_start_falling()


func _on_body_entered(body: Node3D) -> void:
	if OS.is_debug_build():
		print("CrumblingPlatform: Body entered - %s" % body.name)

	if body.is_in_group("player") and not is_falling:
		player_on_platform = true
		if OS.is_debug_build():
			print("CrumblingPlatform: Player stepped on platform")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_on_platform = false
		# Reset timer if player leaves before falling
		if time_stepped_on < fall_delay:
			time_stepped_on = 0.0
			_set_warning_visual(false)
			if mesh:
				mesh.position = Vector3.ZERO  # Stop shaking


func _apply_shake() -> void:
	if mesh:
		# Shake the mesh slightly
		mesh.position = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			0,
			randf_range(-shake_intensity, shake_intensity)
		)


func _set_warning_visual(active: bool) -> void:
	if mesh:
		var material = mesh.get_surface_override_material(0)
		if not material:
			# Create material if doesn't exist
			var mesh_material = mesh.mesh.surface_get_material(0)
			if mesh_material:
				material = mesh_material.duplicate()
				mesh.set_surface_override_material(0, material)
			else:
				material = StandardMaterial3D.new()
				mesh.set_surface_override_material(0, material)

		if active:
			# Darken color to show instability
			material.albedo_color = warning_color
		else:
			# Return to original color
			material.albedo_color = original_color

	# Emit warning particles
	if warning_particles and active:
		warning_particles.emitting = true


func _start_falling() -> void:
	if is_falling:
		return

	is_falling = true
	player_on_platform = false

	if OS.is_debug_build():
		print("CrumblingPlatform: Platform falling!")

	# Disable collision so player falls through
	if collision:
		collision.set_deferred("disabled", true)

	# Disable detection area
	if detection_area:
		detection_area.monitoring = false

	# Play fall sound
	_play_sound("platform_crumble")

	# Animate fall
	_animate_fall()


func _animate_fall() -> void:
	if not mesh:
		# If no mesh, just wait and respawn
		await get_tree().create_timer(1.0).timeout
		_respawn_platform()
		return

	# Tween animation: fall down and rotate
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	# Fall downward
	tween.tween_property(self, "global_position", global_position + Vector3(0, -20, 0), 1.5)

	# Rotate while falling
	tween.tween_property(mesh, "rotation", Vector3(
		randf_range(-PI, PI),
		randf_range(-PI, PI),
		randf_range(-PI, PI)
	), 1.5)

	# Fade out
	tween.tween_property(mesh, "transparency", 1.0, 1.5)

	# Wait for animation to complete, then respawn
	await tween.finished
	_respawn_platform()


func _respawn_platform() -> void:
	is_respawning = true

	# Wait respawn delay
	await get_tree().create_timer(respawn_delay).timeout

	# Reset position and state
	global_position = original_position
	time_stepped_on = 0.0
	is_falling = false
	is_respawning = false

	# Reset mesh
	if mesh:
		mesh.position = Vector3.ZERO
		mesh.rotation = Vector3.ZERO
		mesh.transparency = 0.0
		# Reset color
		_set_warning_visual(false)

	# Re-enable collision
	if collision:
		collision.disabled = false

	# Re-enable detection
	if detection_area:
		detection_area.monitoring = true

	if OS.is_debug_build():
		print("CrumblingPlatform: Platform respawned")


func _play_sound(sound_name: String) -> void:
	# TODO: Implement in Phase 8 (Audio & Polish)
	if OS.is_debug_build():
		print("Playing sound: %s" % sound_name)


## Force platform to fall (for debugging/scripted events)
func force_fall() -> void:
	if not is_falling:
		_start_falling()


## Reset platform to initial state (for level restart)
func reset_platform() -> void:
	# Cancel any ongoing animations
	is_falling = false
	is_respawning = false
	player_on_platform = false
	time_stepped_on = 0.0

	# Reset to original position
	global_position = original_position

	# Reset mesh
	if mesh:
		mesh.position = Vector3.ZERO
		mesh.rotation = Vector3.ZERO
		mesh.transparency = 0.0
		_set_warning_visual(false)

	# Enable collision
	if collision:
		collision.disabled = false

	# Enable detection
	if detection_area:
		detection_area.monitoring = true
