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
