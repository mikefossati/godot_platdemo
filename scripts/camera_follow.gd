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

# Child nodes
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


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

		# Position and rotate the spring arm to match the offset direction
		# The spring arm extends along its local -Z axis
		# We need to rotate it to point in the offset direction
		var offset_direction = offset.normalized()
		# Calculate rotation to align -Z with offset direction
		if offset_direction.length() > 0:
			# Look in the opposite direction of offset (since spring extends backward)
			spring_arm.look_at(global_position - offset_direction, Vector3.UP)


func _process(delta: float) -> void:
	# Only follow if we have a valid target
	if target == null:
		return

	# Smoothly follow the player's position
	# The spring arm will automatically handle collision and pull camera closer if needed
	var target_position: Vector3 = target.global_position
	global_position = global_position.lerp(target_position, follow_speed * delta)

	# Make the camera controller (and spring arm) look at the target
	# This keeps the camera oriented toward the player
	var look_at_position: Vector3 = target.global_position
	look_at_position.y += 1.0  # Look at a point slightly above the player's feet

	# Update rotation to look at target
	# The spring arm will extend from here in its local -Z direction
	look_at(look_at_position, Vector3.UP)
