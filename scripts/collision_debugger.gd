extends Node

## Collision Debugger - Attach to any node to debug collision shapes and positions
## Prints actual world positions, sizes, and collision events
## Now includes validation asserts to catch misalignment issues

@export var debug_player: bool = true
@export var debug_platforms: bool = true
@export var debug_ground: bool = true
@export var enable_validation: bool = true
@export var strict_mode: bool = false  # If true, will assert on validation failures

var validation_errors: int = 0
var validation_warnings: int = 0

var player: CharacterBody3D
var platforms: Array = []
var ground: StaticBody3D


func _ready() -> void:
	# Wait a frame for scene to be fully loaded
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")

	# Validate player exists if debugging is enabled
	if debug_player and player == null:
		push_error("CollisionDebugger: CRITICAL - No player found in 'player' group")
		push_error("  Solution: Add player node to 'player' group in scene")
		assert(false, "CollisionDebugger: Cannot debug player - no player node found")

	# Find all platforms
	for child in get_parent().get_children():
		if child is StaticBody3D and child.name.begins_with("Platform"):
			platforms.append(child)
		elif child is StaticBody3D and child.name == "Ground":
			ground = child

	print("\n========== COLLISION DEBUG INFO ==========")

	if debug_player and player:
		debug_player_info()

	if debug_platforms:
		for platform in platforms:
			debug_platform_info(platform)

	if debug_ground and ground:
		debug_ground_info()

	print("==========================================\n")

	# Run validation if enabled
	if enable_validation:
		print("\n========== VALIDATION REPORT ==========")
		validate_all()
		print_validation_summary()
		print("==========================================\n")


func debug_player_info() -> void:
	print("\n--- PLAYER ---")
	print("Player world position: ", player.global_position)

	# Find collision shape
	var collision_shape = player.get_node_or_null("CollisionShape3D")
	if collision_shape:
		var shape = collision_shape.shape
		print("Collision shape type: ", shape.get_class())

		if shape is CapsuleShape3D:
			print("  Capsule height: ", shape.height)
			print("  Capsule radius: ", shape.radius)
			print("  Collision local pos: ", collision_shape.position)
			print("  Collision world pos: ", collision_shape.global_position)
			print("  Capsule bottom (world): ", collision_shape.global_position.y - shape.height / 2)
			print("  Capsule top (world): ", collision_shape.global_position.y + shape.height / 2)

	# Find character model
	var model = player.get_node_or_null("CharacterModel")
	if model:
		print("Character model local pos: ", model.position)
		print("Character model world pos: ", model.global_position)


func debug_platform_info(platform: StaticBody3D) -> void:
	print("\n--- ", platform.name, " ---")
	print("Platform world position: ", platform.global_position)

	# Find visual model
	var model = platform.get_node_or_null("PlatformModel")
	if model:
		print("Visual model local pos: ", model.position)
		print("Visual model world pos: ", model.global_position)
		print("Visual model scale: ", model.scale)

		# Try to get mesh bounds
		var mesh_instance = find_mesh_instance(model)
		if mesh_instance and mesh_instance.mesh:
			var aabb = mesh_instance.mesh.get_aabb()
			print("  Mesh AABB size: ", aabb.size)
			print("  Mesh AABB center: ", aabb.get_center())

			# Calculate actual bounds in world space
			var _scaled_size = aabb.size * model.scale
			var world_bottom = model.global_position.y + (aabb.get_center().y - aabb.size.y / 2) * model.scale.y
			var world_top = model.global_position.y + (aabb.get_center().y + aabb.size.y / 2) * model.scale.y
			print("  Visual bottom (world): ", world_bottom)
			print("  Visual top (world): ", world_top)

	# Find collision shape
	var collision_shape = platform.get_node_or_null("CollisionShape3D")
	if collision_shape:
		var shape = collision_shape.shape
		print("Collision shape type: ", shape.get_class())

		if shape is BoxShape3D:
			print("  Box size: ", shape.size)
			print("  Collision local pos: ", collision_shape.position)
			print("  Collision world pos: ", collision_shape.global_position)
			print("  Collision bottom (world): ", collision_shape.global_position.y - shape.size.y / 2)
			print("  Collision top (world): ", collision_shape.global_position.y + shape.size.y / 2)


func debug_ground_info() -> void:
	print("\n--- GROUND ---")
	print("Ground world position: ", ground.global_position)

	# Find collision shape
	var collision_shape = ground.get_node_or_null("CollisionShape3D")
	if collision_shape:
		var shape = collision_shape.shape
		print("Collision shape type: ", shape.get_class())

		if shape is BoxShape3D:
			print("  Box size: ", shape.size)
			print("  Collision local pos: ", collision_shape.position)
			print("  Collision world pos: ", collision_shape.global_position)
			print("  Collision bottom (world): ", collision_shape.global_position.y - shape.size.y / 2)
			print("  Collision top (world): ", collision_shape.global_position.y + shape.size.y / 2)


func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	return null


func _physics_process(_delta: float) -> void:
	# Print when player is on floor
	if player and player.is_on_floor():
		# Only print once when landing
		if not player.get_meta("was_on_floor", false):
			print("\nPlayer landed at Y: ", player.global_position.y)
			print("Capsule bottom at Y: ", player.global_position.y)
			player.set_meta("was_on_floor", true)
	elif player:
		player.set_meta("was_on_floor", false)


# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================

## Validate all game objects
func validate_all() -> void:
	validation_errors = 0
	validation_warnings = 0

	if player:
		validate_player()

	for platform in platforms:
		validate_platform(platform)

	if ground:
		validate_ground()


## Validate player collision setup
func validate_player() -> void:
	var collision_shape = player.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		log_error("Player missing CollisionShape3D")
		return

	var shape = collision_shape.shape
	if not shape is CapsuleShape3D:
		log_error("Player collision shape should be CapsuleShape3D, got %s" % shape.get_class())
		return

	# Validate dimensions match constants
	if not is_equal_approx(shape.radius, GameConstants.CHARACTER_COLLISION_RADIUS):
		log_warning("Player capsule radius is %.2f, expected %.2f" % [shape.radius, GameConstants.CHARACTER_COLLISION_RADIUS])

	if not is_equal_approx(shape.height, GameConstants.CHARACTER_COLLISION_HEIGHT):
		log_warning("Player capsule height is %.2f, expected %.2f" % [shape.height, GameConstants.CHARACTER_COLLISION_HEIGHT])

	# Validate character model is at feet (Y=0)
	var model = player.get_node_or_null("CharacterModel")
	if model and abs(model.position.y) > GameConstants.POSITION_TOLERANCE:
		log_warning("Character model Y position is %.2f, should be 0 (feet at capsule bottom)" % model.position.y)


## Validate platform collision alignment
func validate_platform(platform: StaticBody3D) -> void:
	var collision_shape = platform.get_node_or_null("CollisionShape3D")
	var model = platform.get_node_or_null("PlatformModel")

	if not collision_shape:
		log_error("%s missing CollisionShape3D" % platform.name)
		return

	if not model:
		log_error("%s missing PlatformModel" % platform.name)
		return

	var shape = collision_shape.shape
	if not shape is BoxShape3D:
		log_error("%s collision should be BoxShape3D, got %s" % [platform.name, shape.get_class()])
		return

	# Get mesh bounds
	var mesh_instance = find_mesh_instance(model)
	if not mesh_instance or not mesh_instance.mesh:
		log_warning("%s: Could not find mesh for validation" % platform.name)
		return

	var aabb = mesh_instance.mesh.get_aabb()

	# Calculate expected collision size based on scale
	var expected_size = GameConstants.calculate_platform_collision_size(model.scale)
	var actual_size = shape.size

	# Validate collision size
	if not GameConstants.sizes_match(expected_size, actual_size):
		log_error("%s collision size mismatch: expected %v, got %v" % [platform.name, expected_size, actual_size])

	# Validate collision and model have same Y offset
	var model_y = model.position.y
	var collision_y = collision_shape.position.y

	if not is_equal_approx(model_y, collision_y):
		log_error("%s: Model Y (%.2f) != Collision Y (%.2f)" % [platform.name, model_y, collision_y])

	# Validate they're at the expected offset
	if not is_equal_approx(model_y, GameConstants.PLATFORM_MODEL_Y_OFFSET):
		log_warning("%s: Model Y offset is %.2f, expected %.2f" % [platform.name, model_y, GameConstants.PLATFORM_MODEL_Y_OFFSET])

	# Validate visual and collision bounds align in world space
	var world_bottom_visual = model.global_position.y + (aabb.get_center().y - aabb.size.y / 2) * model.scale.y
	var world_top_visual = model.global_position.y + (aabb.get_center().y + aabb.size.y / 2) * model.scale.y
	var world_bottom_collision = collision_shape.global_position.y - shape.size.y / 2
	var world_top_collision = collision_shape.global_position.y + shape.size.y / 2

	if abs(world_bottom_visual - world_bottom_collision) > GameConstants.POSITION_TOLERANCE:
		log_error("%s: Visual bottom (%.2f) != Collision bottom (%.2f)" % [platform.name, world_bottom_visual, world_bottom_collision])

	if abs(world_top_visual - world_top_collision) > GameConstants.POSITION_TOLERANCE:
		log_error("%s: Visual top (%.2f) != Collision top (%.2f)" % [platform.name, world_top_visual, world_top_collision])


## Validate ground collision
func validate_ground() -> void:
	var collision_shape = ground.get_node_or_null("CollisionShape3D")

	if not collision_shape:
		log_error("Ground missing CollisionShape3D")
		return

	var shape = collision_shape.shape
	if not shape is BoxShape3D:
		log_error("Ground collision should be BoxShape3D, got %s" % shape.get_class())
		return

	# Validate size matches constants
	var expected_size = GameConstants.GROUND_COLLISION_SIZE
	var actual_size = shape.size

	if not GameConstants.sizes_match(expected_size, actual_size):
		log_error("Ground collision size mismatch: expected %v, got %v" % [expected_size, actual_size])

	# Validate position offset
	var expected_y = GameConstants.GROUND_COLLISION_Y_OFFSET
	var actual_y = collision_shape.position.y

	if not is_equal_approx(actual_y, expected_y):
		log_warning("Ground collision Y offset is %.2f, expected %.2f" % [actual_y, expected_y])


## Log validation error
func log_error(message: String) -> void:
	validation_errors += 1
	push_error("[VALIDATION ERROR] " + message)
	if strict_mode:
		assert(false, message)


## Log validation warning
func log_warning(message: String) -> void:
	validation_warnings += 1
	push_warning("[VALIDATION WARNING] " + message)


## Print validation summary
func print_validation_summary() -> void:
	if validation_errors == 0 and validation_warnings == 0:
		print("✓ All validation checks passed!")
	else:
		if validation_errors > 0:
			print("✗ Found %d validation ERROR(S)" % validation_errors)
		if validation_warnings > 0:
			print("⚠ Found %d validation WARNING(S)" % validation_warnings)

	if strict_mode and validation_errors > 0:
		print("⚠ STRICT MODE ENABLED - Game will assert on errors")

	print("\nValidation complete. Check console for details.")
