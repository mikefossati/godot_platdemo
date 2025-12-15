extends Node3D

## Camera Follow System with Collision Avoidance
## Uses SpringArm3D to prevent camera from clipping through platforms
## This creates a third-person camera view that stays behind and above the player

# Reference to the player node
@export var target: Node3D  ## The object the camera should follow (set in the editor)

# Camera positioning parameters
@export var offset: Vector3 = Vector3(0, 5, 8)  ## Camera position relative to target
@export var follow_speed: float = 5.0  ## How quickly camera catches up to target (lower = smoother but slower)
@export var collision_margin: float = 0.3  ## Safety distance from walls for SpringArm

# Debug options
@export_group("Debug")
@export var enable_debug: bool = false  ## Enable debug visualization and console output
@export var debug_draw_raycast: bool = true  ## Draw SpringArm raycast line
@export var debug_draw_positions: bool = true  ## Draw position indicators
@export var debug_console_output: bool = false  ## Print debug info to console

# Child nodes
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

# Debug tracking
var _last_spring_length: float = 0.0
var _collision_detected: bool = false


func _ready() -> void:
	# If no target is assigned, try to find the player automatically
	if target == null:
		target = get_tree().get_first_node_in_group("player")

	# If we still don't have a target, print a warning
	if target == null:
		push_warning("CameraFollow: No target assigned and no player found in 'player' group")
		return

	# Configure SpringArm3D
	if spring_arm:
		# Set spring length to the magnitude of the offset vector
		spring_arm.spring_length = offset.length()
		spring_arm.margin = collision_margin
		# Set collision mask to only collide with World layer (layer 1)
		spring_arm.collision_mask = 1

		# SpringArm extends along local -Z axis by default
		# No need to rotate it - the parent CameraController handles rotation
		# The spring arm will automatically extend backward from the controller


func _process(delta: float) -> void:
	# Only follow if we have a valid target
	if target == null:
		return

	# Position controller at the player
	var target_position: Vector3 = target.global_position
	global_position = global_position.lerp(target_position, follow_speed * delta)

	# Make the camera controller face AWAY from the player (in the offset direction)
	# This way when SpringArm extends backward, it points toward the offset
	# SpringArm extends along local -Z, so we want -Z to point in offset direction
	# This means +Z (forward) should point opposite to offset
	var look_away_position: Vector3 = target.global_position - offset
	look_away_position.y += 1.0

	# Check if look direction and UP vector are not colinear
	var look_direction = (look_away_position - global_position).normalized()
	var dot_product = abs(look_direction.dot(Vector3.UP))

	if dot_product < 0.99:
		look_at(look_away_position, Vector3.UP)

	# Debug visualization and output
	if enable_debug:
		_draw_debug_info()


func _draw_debug_info() -> void:
	## Draw debug visualization for camera system
	if not is_inside_tree():
		return

	var immediate_mesh: ImmediateMesh = ImmediateMesh.new()
	var mesh_instance: MeshInstance3D

	# Find or create debug mesh instance
	if not has_node("DebugMesh"):
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "DebugMesh"
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh_instance)
	else:
		mesh_instance = get_node("DebugMesh")

	mesh_instance.mesh = immediate_mesh

	# Start drawing
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	if debug_draw_raycast and spring_arm:
		# Draw SpringArm raycast line
		# From controller to intended camera position
		var spring_start = global_position
		var spring_end = camera.global_position

		# Green if no collision, Red if compressed
		var current_length = spring_start.distance_to(spring_end)
		var is_compressed = current_length < (spring_arm.spring_length - 0.1)

		if is_compressed != _collision_detected:
			_collision_detected = is_compressed
			if debug_console_output and is_compressed:
				print("[Camera] SpringArm COMPRESSED - collision detected")
			elif debug_console_output and not is_compressed:
				print("[Camera] SpringArm EXTENDED - collision cleared")

		var raycast_color = Color.GREEN if not is_compressed else Color.RED

		# Draw line from controller to camera
		immediate_mesh.surface_set_color(raycast_color)
		immediate_mesh.surface_add_vertex(spring_start)
		immediate_mesh.surface_add_vertex(spring_end)

		# Draw intended position (if different from actual)
		if is_compressed:
			var intended_pos = spring_start - global_transform.basis.z * spring_arm.spring_length
			immediate_mesh.surface_set_color(Color.YELLOW)
			immediate_mesh.surface_add_vertex(spring_end)
			immediate_mesh.surface_add_vertex(intended_pos)

	if debug_draw_positions:
		# Draw position markers as small cross hairs
		_draw_crosshair(immediate_mesh, global_position, Color.BLUE, 0.3)  # Controller position
		_draw_crosshair(immediate_mesh, target.global_position, Color.CYAN, 0.5)  # Target position
		_draw_crosshair(immediate_mesh, camera.global_position, Color.WHITE, 0.2)  # Camera position

	immediate_mesh.surface_end()

	# Console output
	if debug_console_output and Engine.get_process_frames() % 60 == 0:
		var current_length = global_position.distance_to(camera.global_position)
		print("[Camera Debug]")
		print("  Controller: ", global_position)
		print("  Target: ", target.global_position)
		print("  Camera: ", camera.global_position)
		print("  SpringArm length: %.2f / %.2f" % [current_length, spring_arm.spring_length])
		print("  Compressed: ", _collision_detected)
		print("  Offset: ", offset)


func _draw_crosshair(mesh: ImmediateMesh, pos: Vector3, color: Color, size: float) -> void:
	## Draw a 3D crosshair at the given position
	mesh.surface_set_color(color)

	# X axis
	mesh.surface_add_vertex(pos + Vector3(-size, 0, 0))
	mesh.surface_add_vertex(pos + Vector3(size, 0, 0))

	# Y axis
	mesh.surface_add_vertex(pos + Vector3(0, -size, 0))
	mesh.surface_add_vertex(pos + Vector3(0, size, 0))

	# Z axis
	mesh.surface_add_vertex(pos + Vector3(0, 0, -size))
	mesh.surface_add_vertex(pos + Vector3(0, 0, size))
