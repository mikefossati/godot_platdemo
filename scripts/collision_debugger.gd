extends Node

## Collision Debugger - Attach to any node to debug collision shapes and positions
## Prints actual world positions, sizes, and collision events

@export var debug_player: bool = true
@export var debug_platforms: bool = true
@export var debug_ground: bool = true

var player: CharacterBody3D
var platforms: Array = []
var ground: StaticBody3D


func _ready() -> void:
	# Wait a frame for scene to be fully loaded
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")

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
			var scaled_size = aabb.size * model.scale
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
