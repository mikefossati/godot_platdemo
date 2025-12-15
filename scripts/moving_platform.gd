extends AnimatableBody3D

## Moving Platform - Smooth, configurable platform movement
## Uses AnimatableBody3D for proper physics interaction with player
## Supports multiple movement patterns for level design variety

## Movement pattern type
enum MovementType {
	LINEAR,          ## Back and forth between two points
	CIRCULAR,        ## Circular/elliptical path
	PATH_FOLLOW,     ## Follow a custom Path3D
	PENDULUM         ## Swing like a pendulum
}

# Movement configuration
@export_group("Movement Settings")
@export var movement_type: MovementType = MovementType.LINEAR
@export var speed: float = 2.0  ## Units per second or radians per second for circular
@export var start_delay: float = 0.0  ## Delay before starting movement (seconds)
@export var pause_at_ends: float = 0.0  ## How long to pause at each endpoint (seconds)

# Linear movement
@export_group("Linear Movement")
@export var end_position: Vector3 = Vector3(5, 0, 0)  ## Relative to start position
@export var loop_movement: bool = true  ## If false, stops at end position

# Circular movement
@export_group("Circular Movement")
@export var orbit_radius: Vector2 = Vector2(3, 3)  ## X and Z radius (Y stays constant)
@export var clockwise: bool = true  ## Direction of rotation
@export var start_angle: float = 0.0  ## Starting angle in radians

# Path following
@export_group("Path Following")
@export var path_node: Path3D  ## Reference to Path3D node to follow
@export var loop_path: bool = true  ## If true, repeats path continuously

# Visual feedback
@export_group("Visual Settings")
@export var show_movement_preview: bool = true  ## Show movement path in editor
@export var preview_color: Color = Color(1, 1, 0, 0.5)  ## Path preview color

# Internal state
var _start_position: Vector3
var _current_time: float = 0.0
var _moving_forward: bool = true
var _is_paused: bool = false
var _pause_timer: float = 0.0
var _has_started: bool = false

# Path following state
var _path_follower: PathFollow3D
var _path_progress: float = 0.0


func _ready() -> void:
	_start_position = global_position

	# Set up path following if needed
	if movement_type == MovementType.PATH_FOLLOW and path_node != null:
		_setup_path_follower()

	# Validate configuration
	_validate_configuration()

	# Add to platform group for easy identification
	add_to_group("moving_platforms")


func _physics_process(delta: float) -> void:
	# Handle start delay
	if not _has_started:
		if start_delay > 0:
			start_delay -= delta
			return
		_has_started = true

	# Handle pause at endpoints
	if _is_paused:
		_pause_timer -= delta
		if _pause_timer <= 0:
			_is_paused = false
		else:
			return

	# Update movement based on type
	match movement_type:
		MovementType.LINEAR:
			_update_linear_movement(delta)
		MovementType.CIRCULAR:
			_update_circular_movement(delta)
		MovementType.PATH_FOLLOW:
			_update_path_movement(delta)
		MovementType.PENDULUM:
			_update_pendulum_movement(delta)

	# Sync transform for physics (AnimatableBody3D requirement)
	# This ensures player moves with platform
	sync_to_physics = true


## Update linear back-and-forth movement
func _update_linear_movement(delta: float) -> void:
	_current_time += delta * speed

	var total_distance = _start_position.distance_to(_start_position + end_position)
	var travel_time = total_distance / speed

	var progress: float

	if loop_movement:
		# Ping-pong movement
		var cycle_time = _current_time
		if pause_at_ends > 0:
			cycle_time = _current_time / (1.0 + pause_at_ends / travel_time)

		progress = abs(fmod(cycle_time, travel_time * 2) - travel_time) / travel_time
		progress = clamp(progress, 0.0, 1.0)

		# Trigger pause at endpoints
		if pause_at_ends > 0:
			var is_at_end = progress >= 0.99 or progress <= 0.01
			var was_moving = not _is_paused
			if is_at_end and was_moving and _moving_forward != (progress >= 0.99):
				_is_paused = true
				_pause_timer = pause_at_ends
				_moving_forward = not _moving_forward
	else:
		# One-way movement
		progress = clamp(_current_time / travel_time, 0.0, 1.0)

		if progress >= 1.0 and pause_at_ends > 0 and not _is_paused:
			_is_paused = true
			_pause_timer = pause_at_ends

	global_position = _start_position.lerp(_start_position + end_position, progress)


## Update circular/elliptical movement
func _update_circular_movement(delta: float) -> void:
	_current_time += delta * speed * (1 if clockwise else -1)

	var angle = start_angle + _current_time
	var x_offset = cos(angle) * orbit_radius.x
	var z_offset = sin(angle) * orbit_radius.y

	global_position = _start_position + Vector3(x_offset, 0, z_offset)


## Update path following movement
func _update_path_movement(delta: float) -> void:
	if _path_follower == null:
		return

	_path_progress += delta * speed

	if loop_path:
		# Loop the path
		var path_length = path_node.curve.get_baked_length()
		_path_progress = fmod(_path_progress, path_length)
	else:
		# Clamp to path length
		var path_length = path_node.curve.get_baked_length()
		_path_progress = clamp(_path_progress, 0, path_length)

	_path_follower.progress = _path_progress
	global_position = _path_follower.global_position


## Update pendulum swinging movement
func _update_pendulum_movement(delta: float) -> void:
	_current_time += delta

	# Pendulum physics: angle = amplitude * sin(sqrt(g/L) * t)
	# Simplified for game feel
	var amplitude = PI / 4  # 45 degrees
	var frequency = speed  # Use speed as frequency multiplier
	var angle = amplitude * sin(frequency * _current_time)

	# Swing along X axis (can be modified)
	var swing_distance = end_position.length()
	var x_offset = sin(angle) * swing_distance
	var y_offset = -abs(cos(angle) - 1) * swing_distance * 0.3  # Slight vertical movement

	global_position = _start_position + Vector3(x_offset, y_offset, 0)


## Set up path follower for path-based movement
func _setup_path_follower() -> void:
	if path_node == null:
		push_error("MovingPlatform: PATH_FOLLOW type requires path_node to be set")
		return

	_path_follower = PathFollow3D.new()
	path_node.add_child(_path_follower)
	_path_follower.loop = loop_path


## Validate configuration and warn about issues
func _validate_configuration() -> void:
	match movement_type:
		MovementType.LINEAR:
			if end_position.length() < 0.1:
				push_warning("MovingPlatform '%s': end_position is very small, platform will barely move" % name)

		MovementType.CIRCULAR:
			if orbit_radius.x < 0.1 or orbit_radius.y < 0.1:
				push_warning("MovingPlatform '%s': orbit_radius is very small" % name)

		MovementType.PATH_FOLLOW:
			if path_node == null:
				push_error("MovingPlatform '%s': PATH_FOLLOW requires path_node to be set" % name)

		MovementType.PENDULUM:
			if end_position.length() < 0.1:
				push_warning("MovingPlatform '%s': pendulum needs end_position for swing distance" % name)

	if speed <= 0:
		push_warning("MovingPlatform '%s': speed should be greater than 0" % name)


## Reset platform to starting position (useful for level reset)
func reset_platform() -> void:
	global_position = _start_position
	_current_time = 0.0
	_moving_forward = true
	_is_paused = false
	_pause_timer = 0.0
	_has_started = false
	_path_progress = 0.0


## Get current movement progress (0.0 to 1.0)
func get_movement_progress() -> float:
	match movement_type:
		MovementType.LINEAR:
			var total_distance = _start_position.distance_to(_start_position + end_position)
			var current_distance = _start_position.distance_to(global_position)
			return current_distance / total_distance if total_distance > 0 else 0.0

		MovementType.CIRCULAR:
			var normalized_time = fmod(_current_time, TAU)
			return normalized_time / TAU

		MovementType.PATH_FOLLOW:
			if path_node != null:
				var path_length = path_node.curve.get_baked_length()
				return _path_progress / path_length if path_length > 0 else 0.0
			return 0.0

		MovementType.PENDULUM:
			# Approximate based on position
			var current_offset = global_position - _start_position
			var max_offset = end_position.length()
			return abs(current_offset.x) / max_offset if max_offset > 0 else 0.0

	return 0.0


# Editor visualization (only runs in editor)
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and show_movement_preview:
		queue_redraw()


# Draw movement preview in editor
func _draw() -> void:
	if not Engine.is_editor_hint() or not show_movement_preview:
		return

	# This would need RenderingServer calls for 3D visualization
	# Or we could create a separate EditorPlugin for visual debugging
	# For now, this is a placeholder for future editor integration
