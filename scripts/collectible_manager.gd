extends Node

## CollectibleManager - Manages collectible spawning and pooling
## This node should be added to each level scene and configured with spawn points
## Add this node to the "collectible_pool" group for collectibles to find it

@export var collectible_scene: PackedScene  ## The collectible scene to spawn
@export var spawn_positions: Array[Vector3] = []  ## Positions where collectibles spawn
@export var enable_pooling: bool = true  ## Use object pooling (recommended)

# Object pool for collectibles
var _pool: Node = null


func _ready() -> void:
	# Add to group so collectibles can find us
	add_to_group("collectible_pool")

	# Create object pool if pooling is enabled
	if enable_pooling and collectible_scene != null:
		_pool = load("res://scripts/object_pool.gd").new()
		_pool.pooled_scene = collectible_scene
		_pool.initial_pool_size = spawn_positions.size()
		_pool.max_pool_size = spawn_positions.size() * 2
		add_child(_pool)
		# Give pool time to initialize
		await get_tree().process_frame

	# Spawn initial collectibles
	spawn_all_collectibles()


## Spawn all collectibles at their designated positions
func spawn_all_collectibles() -> void:
	for pos in spawn_positions:
		spawn_collectible_at(pos)


## Spawn a single collectible at a specific position
func spawn_collectible_at(pos: Vector3) -> Node3D:
	var collectible: Node3D = null

	if enable_pooling and _pool != null:
		# Get from pool
		collectible = _pool.acquire()
	elif collectible_scene != null:
		# Create new instance (traditional approach)
		collectible = collectible_scene.instantiate()
		get_parent().add_child(collectible)
	else:
		push_error("CollectibleManager: No collectible_scene assigned!")
		return null

	# Position the collectible
	collectible.global_position = pos

	# If using pool, need to reparent to level
	if enable_pooling and collectible.get_parent() != get_parent():
		var current_parent = collectible.get_parent()
		if current_parent != null:
			current_parent.remove_child(collectible)
		get_parent().add_child(collectible)

	# Update start_y for bobbing animation
	if collectible.has_method("set"):
		collectible.start_y = pos.y

	return collectible


## Release a collectible back to the pool
func release_collectible(collectible: Node3D) -> void:
	if enable_pooling and _pool != null:
		# Decrement total collectibles count (it was incremented in collectible._ready)
		GameManager.total_collectibles -= 1

		# Return to pool
		_pool.release(collectible)
	else:
		# Traditional destruction
		collectible.queue_free()


## Get pool statistics (for debugging)
func get_pool_stats() -> Dictionary:
	if _pool != null:
		return _pool.get_pool_stats()
	return {"available": 0, "active": 0, "total": 0}


## Clear all collectibles (useful for level reset)
func clear_all_collectibles() -> void:
	if _pool != null:
		_pool.clear_pool()
