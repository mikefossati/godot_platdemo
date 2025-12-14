extends Camera3D

## Camera Follow System - Smoothly follows the player character
## This creates a third-person camera view that stays behind and above the player

# Reference to the player node
@export var target: Node3D  ## The object the camera should follow (set in the editor)

# Camera positioning parameters
@export var offset: Vector3 = Vector3(0, 5, 8)  ## Camera position relative to target
@export var follow_speed: float = 5.0  ## How quickly camera catches up to target (lower = smoother but slower)
@export var look_ahead: float = 2.0  ## How far ahead of the target to look


func _ready() -> void:
	# If no target is assigned, try to find the player automatically
	if target == null:
		target = get_tree().get_first_node_in_group("player")

	# If we still don't have a target, print a warning
	if target == null:
		push_warning("CameraFollow: No target assigned and no player found in 'player' group")


func _process(delta: float) -> void:
	# Only follow if we have a valid target
	if target == null:
		return

	# Calculate the desired camera position
	# We want to be at the target's position plus the offset
	var target_position: Vector3 = target.global_position + offset

	# Smoothly interpolate (lerp) from current position to target position
	# This creates smooth camera movement instead of instant snapping
	# The follow_speed parameter controls how quickly the camera catches up
	global_position = global_position.lerp(target_position, follow_speed * delta)

	# Make the camera look at the target
	# We look slightly ahead by adding a forward offset based on the target's position
	var look_at_position: Vector3 = target.global_position
	look_at_position.y += 1.0  # Look at a point slightly above the player's feet

	# look_at() makes the camera point toward the specified position
	# Vector3.UP defines which direction is "up" for the camera
	look_at(look_at_position, Vector3.UP)
