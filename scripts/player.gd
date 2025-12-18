class_name Player
extends CharacterBody3D

## Enhanced Player Controller - Phase 2: Health System Integrated
## Features: Acceleration, Coyote Time, Jump Buffering, Double Jump, Dash, Ground Pound

# ========== COMPONENTS ==========
@onready var health_component: HealthComponent = SceneValidator.validate_node_path(self, "HealthComponent")

# ========== MOVEMENT PARAMETERS ==========
@export_group("Basic Movement")
@export var max_speed: float = 5.0  ## Maximum movement speed
@export var run_multiplier: float = 1.5  ## Speed multiplier when running (hold Shift)
@export var acceleration: float = 20.0  ## How quickly player reaches max speed
@export var deceleration: float = 25.0  ## How quickly player stops when no input
@export var rotation_speed: float = 10.0  ## How quickly player rotates to face direction

@export_group("Jump Parameters")
@export var jump_velocity: float = 10.0  ## Initial jump strength
@export var jump_release_multiplier: float = 0.5  ## Reduced gravity when releasing jump (variable height)
@export var coyote_time: float = 0.1  ## Grace period after leaving platform (seconds)
@export var jump_buffer_time: float = 0.1  ## Can press jump slightly before landing (seconds)

@export_group("Advanced Abilities")
@export var dash_speed: float = 12.0  ## Speed during dash
@export var dash_duration: float = 0.3  ## How long dash lasts (seconds)
@export var dash_cooldown: float = 0.5  ## Time between dashes (seconds)
@export var ground_pound_speed: float = -15.0  ## Downward velocity for ground pound
@export var ground_pound_bounce: float = 5.0  ## Upward bounce after ground pound

# ========== ABILITY UNLOCKS ==========
var double_jump_unlocked: bool = false  ## Unlocked after World 1-3
var ground_pound_unlocked: bool = false  ## Purchased from shop for 150 coins
var air_dash_unlocked: bool = false  ## Purchased from shop for 150 coins

# ========== STATE VARIABLES ==========
var current_speed: float = 0.0  ## Current horizontal speed (for acceleration)
var is_running: bool = false  ## Is player holding run button

# Jump state
var jumps_available: int = 1  ## How many jumps player can do
var max_jumps: int = 1  ## Maximum jumps (increases with double jump)
var coyote_timer: float = 0.0  ## Time since leaving ground
var jump_buffer_timer: float = 0.0  ## Time since pressing jump
var is_jump_held: bool = false  ## Is jump button currently held

# Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

# Ground pound state
var is_ground_pounding: bool = false
var ground_pound_charge_time: float = 0.0
const GROUND_POUND_CHARGE_REQUIRED: float = 0.2  ## Must hold jump this long

# Physics
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
const DEATH_Y: float = GameConstants.DEFAULT_DEATH_Y

# Animation (existing system)
@onready var animation_tree: AnimationTree = $CharacterModel/AnimationTree
var was_on_floor: bool = true
var landing_frames: int = 0
var punch_frames: int = 0
var wave_frames: int = 0
var previous_animation_state: String = "idle"  # Track animation state changes

# Camera reference (for shake effect)
var camera_controller: Node3D = null

# Particle effect scenes
const DOUBLE_JUMP_PARTICLES = preload("res://scenes/effects/double_jump_particles.tscn")
const DASH_TRAIL_PARTICLES = preload("res://scenes/effects/dash_trail_particles.tscn")
const GROUND_POUND_IMPACT = preload("res://scenes/effects/ground_pound_impact.tscn")

# Active dash trail reference
var active_dash_trail: GPUParticles3D = null

# ========== INITIALIZATION ==========
func _ready() -> void:
	# Connect to health component signals
	if health_component:
		health_component.died.connect(die)
	else:
		push_error("Player scene is missing a HealthComponent node!")

	# Load ability unlocks from GameManager
	if GameManager.has_method("is_ability_unlocked"):
		double_jump_unlocked = GameManager.is_ability_unlocked("double_jump")
		ground_pound_unlocked = GameManager.is_ability_unlocked("ground_pound")
		air_dash_unlocked = GameManager.is_ability_unlocked("air_dash")

	# Update max jumps based on double jump unlock
	update_max_jumps()

	# Find camera controller in scene
	camera_controller = get_tree().get_first_node_in_group("camera")


# ========== MAIN PHYSICS LOOP ==========
func _physics_process(delta: float) -> void:
	# Handle different states
	if is_dashing:
		handle_dash_movement(delta)
	elif is_ground_pounding:
		handle_ground_pound_movement(delta)
	else:
		handle_normal_movement(delta)

	# Apply movement
	move_and_slide()

	# Update animations
	update_animation()

	# Check death boundary
	if global_position.y < DEATH_Y:
		# Inflict max damage to trigger death via the health component
		health_component.take_damage(health_component.max_health)


# ========== NORMAL MOVEMENT ==========
func handle_normal_movement(delta: float) -> void:
	# Update timers
	update_timers(delta)

	# Apply gravity
	if not is_on_floor():
		# Variable jump height - less gravity when holding jump
		var gravity_multiplier = jump_release_multiplier if (velocity.y > 0 and not is_jump_held) else 1.0
		velocity.y -= gravity * gravity_multiplier * delta
	else:
		# Reset jumps when landing
		jumps_available = max_jumps
		is_ground_pounding = false

	# Handle jump input
	handle_jump()

	# Handle ground pound input (must be unlocked and in air)
	if ground_pound_unlocked and not is_on_floor():
		handle_ground_pound_charge(delta)

	# Handle dash input
	handle_dash()

	# Get movement input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	# Check if running
	is_running = Input.is_action_pressed("run")
	var target_speed = max_speed * (run_multiplier if is_running else 1.0)

	if direction != Vector3.ZERO:
		# Accelerate toward target speed
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)

		# Apply velocity
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		# Rotate to face movement direction
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		# Decelerate when no input
		current_speed = move_toward(current_speed, 0.0, deceleration * delta)
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)


# ========== JUMP SYSTEM ==========
func handle_jump() -> void:
	# Track jump button state
	var jump_pressed = Input.is_action_just_pressed("jump")
	is_jump_held = Input.is_action_pressed("jump")

	# Buffer jump input
	if jump_pressed:
		jump_buffer_timer = jump_buffer_time

	# Check if we can jump
	var can_jump = false

	if is_on_floor():
		# On ground - can always jump
		can_jump = jump_pressed
	elif coyote_timer > 0:
		# Coyote time - grace period after leaving platform
		can_jump = jump_pressed
	elif jumps_available > 0:
		# Mid-air with jumps remaining (double jump)
		can_jump = jump_pressed
	elif jump_buffer_timer > 0:
		# Jump buffered and just landed
		can_jump = is_on_floor() or coyote_timer > 0

	if can_jump:
		perform_jump()


func perform_jump() -> void:
	velocity.y = jump_velocity
	jump_buffer_timer = 0.0  # Clear buffer

	# Use up a jump if in air
	if not is_on_floor() and coyote_timer <= 0:
		jumps_available -= 1

		# Play different effect for double jump
		if max_jumps > 1 and jumps_available < max_jumps:
			spawn_double_jump_particles()


# ========== DASH SYSTEM ==========
func handle_dash() -> void:
	dash_cooldown_timer -= get_physics_process_delta_time()

	# Can't dash if on cooldown or already dashing
	if dash_cooldown_timer > 0 or is_dashing:
		return

	# Check dash input
	if Input.is_action_just_pressed("dash"):
		# Can only dash in air if ability unlocked
		if not is_on_floor() and not air_dash_unlocked:
			return

		start_dash()


func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	# Get dash direction (current facing direction or input direction)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0.1:
		dash_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	else:
		# Dash in facing direction
		dash_direction = -global_transform.basis.z
		dash_direction.y = 0
		dash_direction = dash_direction.normalized()

	# Spawn dash particles
	spawn_dash_particles()


func handle_dash_movement(delta: float) -> void:
	dash_timer -= delta

	if dash_timer <= 0:
		is_dashing = false
		stop_dash_particles()
		return

	# Override velocity during dash
	velocity = dash_direction * dash_speed
	velocity.y = 0  # No gravity during dash


# ========== GROUND POUND SYSTEM ==========
func handle_ground_pound_charge(delta: float) -> void:
	# Hold jump to charge ground pound
	if Input.is_action_pressed("jump") and velocity.y < 0:  # Only when falling
		ground_pound_charge_time += delta

		# Visual feedback: player glows or particles appear
		if ground_pound_charge_time >= GROUND_POUND_CHARGE_REQUIRED:
			# Show charged visual (could add particles here)
			pass

	# Release jump to activate
	if Input.is_action_just_released("jump"):
		if ground_pound_charge_time >= GROUND_POUND_CHARGE_REQUIRED:
			start_ground_pound()
		ground_pound_charge_time = 0.0


func start_ground_pound() -> void:
	is_ground_pounding = true
	velocity.y = ground_pound_speed
	ground_pound_charge_time = 0.0


func handle_ground_pound_movement(delta: float) -> void:
	# Fast downward movement
	velocity.x = 0
	velocity.z = 0
	velocity.y = ground_pound_speed

	# Check if landed
	if is_on_floor():
		on_ground_pound_land()


func on_ground_pound_land() -> void:
	is_ground_pounding = false

	# Bounce effect
	velocity.y = ground_pound_bounce

	# Create shockwave (damage nearby enemies)
	create_shockwave()

	# Camera shake
	camera_shake(0.3, 5.0)

	# Particles
	spawn_ground_pound_particles()


# ========== COMBAT FUNCTIONS ==========
func bounce_on_enemy() -> void:
	# This function will be called by an enemy when jumped on.
	# It provides an upward bounce to the player.
	# The combo logic will be handled by a separate combat manager.
	velocity.y = jump_velocity * 0.8 # A slightly smaller bounce than a full jump


# ========== UTILITY FUNCTIONS ==========
func update_timers(delta: float) -> void:
	# Coyote time: give grace period after leaving platform
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Jump buffer: remember jump input briefly
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta


func update_max_jumps() -> void:
	max_jumps = 2 if double_jump_unlocked else 1
	jumps_available = max_jumps


func unlock_double_jump() -> void:
	double_jump_unlocked = true
	update_max_jumps()


func unlock_ground_pound() -> void:
	ground_pound_unlocked = true


func unlock_air_dash() -> void:
	air_dash_unlocked = true


# ========== PARTICLE EFFECTS ==========
func spawn_double_jump_particles() -> void:
	var particles = DOUBLE_JUMP_PARTICLES.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	# Auto-delete after lifetime
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()


func spawn_dash_particles() -> void:
	# Create persistent trail during dash
	active_dash_trail = DASH_TRAIL_PARTICLES.instantiate()
	add_child(active_dash_trail)
	active_dash_trail.position = Vector3.ZERO
	active_dash_trail.emitting = true


func stop_dash_particles() -> void:
	if active_dash_trail != null and is_instance_valid(active_dash_trail):
		active_dash_trail.emitting = false
		# Let particles fade out before removing
		var trail_ref = active_dash_trail
		await get_tree().create_timer(active_dash_trail.lifetime).timeout
		if is_instance_valid(trail_ref):
			trail_ref.queue_free()
		active_dash_trail = null


func spawn_ground_pound_particles() -> void:
	var particles = GROUND_POUND_IMPACT.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	# Auto-delete after lifetime
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()


func create_shockwave() -> void:
	# Create temporary Area3D for shockwave damage
	var shockwave = Area3D.new()
	get_parent().add_child(shockwave)
	shockwave.global_position = global_position
	shockwave.collision_layer = 0
	shockwave.collision_mask = 8  # Layer 4 for enemies (will be set up in Phase 2)

	# Add collision shape
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 3.0  # 3-unit radius as specified
	shape.shape = sphere
	shockwave.add_child(shape)

	# Check for enemies in range (will be implemented in Phase 2)
	# For now, just print debug info
	var bodies = shockwave.get_overlapping_bodies()
	if bodies.size() > 0:
		print("[Ground Pound] Shockwave hit %d objects" % bodies.size())
		for body in bodies:
			if body.has_method("take_damage"):
				body.take_damage(2)  # Ground pound does 2 damage

	# Clean up shockwave after 0.1 seconds
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(shockwave):
		shockwave.queue_free()


func camera_shake(_duration: float, intensity: float) -> void:
	if camera_controller and camera_controller.has_method("shake"):
		camera_controller.shake(intensity, _duration)


# ========== EXISTING FUNCTIONS (Keep Compatibility) ==========
func die() -> void:
	# This function is now called by the HealthComponent's 'died' signal
	GameManager.trigger_game_over()


func collect_item() -> void:
	GameManager.collect_item()


func play_collect_animation() -> void:
	punch_frames = GameConstants.get_punch_frames()


func play_victory_animation() -> void:
	wave_frames = GameConstants.get_wave_frames()


# ========== ANIMATION SYSTEM (Enhanced) ==========
func update_animation() -> void:
	# Determine current movement state based on actual movement speed
	var is_moving := current_speed > 0.2  # Simple speed check
	var is_grounded := is_on_floor()
	var is_jumping := not is_grounded and velocity.y > 0
	var is_falling := not is_grounded and velocity.y < 0

	# Detect landing
	var just_landed := is_grounded and not was_on_floor
	if just_landed:
		landing_frames = GameConstants.get_landing_frames()

	var has_landed := landing_frames > 0
	var is_punching := punch_frames > 0
	var is_waving := wave_frames > 0

	# Determine what animation state we should be in
	# Priority order: special animations > jumping/falling > movement
	var current_state: String = "idle"

	if is_waving:
		current_state = "waving"
	elif is_punching:
		current_state = "punching"
	elif is_dashing:
		current_state = "dashing"
	elif is_ground_pounding:
		current_state = "ground_pounding"
	elif has_landed:
		current_state = "landed"
	elif is_jumping:
		current_state = "jumping"
	elif is_falling:
		current_state = "falling"
	elif is_moving:
		current_state = "moving"
	else:
		current_state = "idle"

	# Only update animation tree when state changes
	if current_state != previous_animation_state:

		# Clear all conditions
		animation_tree.set("parameters/conditions/is_moving", false)
		animation_tree.set("parameters/conditions/is_idle", false)
		animation_tree.set("parameters/conditions/is_jumping", false)
		animation_tree.set("parameters/conditions/is_falling", false)
		animation_tree.set("parameters/conditions/has_landed", false)
		animation_tree.set("parameters/conditions/is_punching", false)
		animation_tree.set("parameters/conditions/is_waving", false)
		animation_tree.set("parameters/conditions/is_dashing", false)
		animation_tree.set("parameters/conditions/is_ground_pounding", false)
		animation_tree.set("parameters/conditions/is_running", false)

		# Set the new state's condition
		match current_state:
			"waving":
				animation_tree.set("parameters/conditions/is_waving", true)
			"punching":
				animation_tree.set("parameters/conditions/is_punching", true)
			"dashing":
				animation_tree.set("parameters/conditions/is_dashing", true)
			"ground_pounding":
				animation_tree.set("parameters/conditions/is_ground_pounding", true)
			"landed":
				animation_tree.set("parameters/conditions/has_landed", true)
			"jumping":
				animation_tree.set("parameters/conditions/is_jumping", true)
			"falling":
				animation_tree.set("parameters/conditions/is_falling", true)
			"moving":
				animation_tree.set("parameters/conditions/is_moving", true)
				if is_running:
					animation_tree.set("parameters/conditions/is_running", true)
			"idle":
				animation_tree.set("parameters/conditions/is_idle", true)

		previous_animation_state = current_state

	# Countdown frame timers
	if landing_frames > 0:
		landing_frames -= 1
	if punch_frames > 0:
		punch_frames -= 1
	if wave_frames > 0:
		wave_frames -= 1

	# Store current ground state
	was_on_floor = is_grounded
