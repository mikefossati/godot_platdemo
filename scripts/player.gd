extends CharacterBody3D

## Player Controller - Handles player movement, jumping, and physics
## CharacterBody3D provides built-in physics and collision detection for character movement

# Movement parameters - these can be tweaked to adjust game feel
@export var speed: float = 5.0  ## How fast the player moves (units per second)
@export var jump_velocity: float = 10.0  ## Initial upward velocity when jumping
@export var rotation_speed: float = 10.0  ## How quickly the player rotates to face movement direction

# Gravity is pulled from project settings (configured in project.godot)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Death boundary - if player falls below this Y position, trigger game over
const DEATH_Y: float = GameConstants.DEFAULT_DEATH_Y

# Animation
@onready var animation_tree: AnimationTree = $CharacterModel/AnimationTree
var was_on_floor: bool = true  # Track previous frame's ground state for landing detection
var landing_frames: int = 0  # Count frames since landing to persist the landing signal
var punch_frames: int = 0  # Count frames since punch triggered to persist the punch signal
var wave_frames: int = 0  # Count frames since wave triggered to persist the wave signal


func _ready() -> void:
	# Set up the player when it enters the scene
	pass


func _physics_process(delta: float) -> void:
	## Called every physics frame (typically 60 times per second)
	## delta is the time since the last frame, used for frame-rate independent movement

	# Apply gravity when not on the floor
	# is_on_floor() is a built-in function that checks if the CharacterBody3D is touching ground
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump input
	# Only allow jumping when on the floor to prevent double-jumps
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction from action mappings (WASD keys)
	# Input.get_axis returns -1, 0, or 1 based on which keys are pressed
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Convert 2D input to 3D direction vector
	# We use the global transform basis to ensure movement is relative to world space
	# This creates movement on the X and Z axes (horizontal plane)
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction != Vector3.ZERO:
		# Apply movement speed to horizontal velocity
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# Rotate player to face movement direction
		# lerp_angle provides smooth rotation interpolation
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		# Apply friction when no input - gradually slow down horizontal movement
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# move_and_slide() is a built-in function that moves the character and handles collisions
	# It uses the velocity vector and automatically handles sliding along surfaces
	move_and_slide()

	# Update character animations based on current state
	update_animation()

	# Check if player has fallen off the level
	if global_position.y < DEATH_Y:
		die()


## Called when the player dies (falls off the level)
func die() -> void:
	GameManager.trigger_game_over()


## Called when player collides with a collectible
func collect_item() -> void:
	GameManager.collect_item()


## Update character animations based on movement state
func update_animation() -> void:
	# Determine current movement state
	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	var is_moving := horizontal_velocity.length() > 0.1
	var is_grounded := is_on_floor()
	var is_jumping := not is_grounded and velocity.y > 0

	# Detect landing (just touched ground)
	var just_landed := is_grounded and not was_on_floor

	# Persist landing signal for a few frames to ensure state machine processes it
	if just_landed:
		landing_frames = GameConstants.get_landing_frames()

	var has_landed := landing_frames > 0
	var is_punching := punch_frames > 0
	var is_waving := wave_frames > 0

	# Update animation tree conditions
	animation_tree.set("parameters/conditions/is_moving", is_moving)
	animation_tree.set("parameters/conditions/is_idle", not is_moving)
	animation_tree.set("parameters/conditions/is_jumping", is_jumping)
	animation_tree.set("parameters/conditions/has_landed", has_landed)
	animation_tree.set("parameters/conditions/is_punching", is_punching)
	animation_tree.set("parameters/conditions/is_waving", is_waving)

	# Countdown landing frames
	if landing_frames > 0:
		landing_frames -= 1

	# Countdown punch frames
	if punch_frames > 0:
		punch_frames -= 1

	# Countdown wave frames
	if wave_frames > 0:
		wave_frames -= 1

	# Store current ground state for next frame
	was_on_floor = is_grounded


## Play the collectible pickup animation (Punch)
## Triggers the Punch state in the animation state machine
func play_collect_animation() -> void:
	# Persist punch signal long enough for the full animation to play
	punch_frames = GameConstants.get_punch_frames()


## Play the victory animation (Wave)
## Triggers the Wave state in the animation state machine
func play_victory_animation() -> void:
	# Persist wave signal long enough for the full animation to play
	wave_frames = GameConstants.get_wave_frames()
