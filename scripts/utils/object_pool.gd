## ObjectPool - Performance optimization for frequently spawned objects
## Reduces instantiation overhead by reusing objects

class_name ObjectPool
extends Node

## Pool configuration
@export var pool_size: int = 20
@export var scene_to_pool: PackedScene

## Internal pool state
var available_objects: Array[Node] = []
var active_objects: Array[Node] = []

## Initialize the pool
func _ready() -> void:
	if not scene_to_pool:
		push_error("ObjectPool: scene_to_pool is not set!")
		return

	# Pre-populate pool with objects
	for i in range(pool_size):
		var obj = scene_to_pool.instantiate()
		obj.add_to_group("pooled_objects")
		add_child(obj)

		# Configure pooled state AFTER adding to tree (so _ready has run)
		obj.visible = false
		obj.process_mode = Node.PROCESS_MODE_DISABLED

		# Disable Area3D monitoring if this is an Area3D
		if obj is Area3D:
			obj.monitoring = false
			obj.monitorable = false

		# Reset pooled state for pre-created objects
		if obj.has_method("reset_pool_state"):
			obj.reset_pool_state()

		available_objects.append(obj)

## Get an object from the pool
func get_object() -> Node:
	var obj: Node = null

	# Try to get a valid object from available pool
	while available_objects.size() > 0:
		obj = available_objects.pop_back()

		# Validate object is still valid
		if is_instance_valid(obj):
			obj.visible = true
			obj.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
			active_objects.append(obj)

			# Activate object for spawning
			if obj.has_method("_on_spawn"):
				obj._on_spawn()

			return obj
		else:
			# Object was freed somehow, skip it
			obj = null

	# Pool exhausted or all objects invalid - create new object
	obj = scene_to_pool.instantiate()
	obj.add_to_group("pooled_objects")
	active_objects.append(obj)
	add_child(obj)

	# Activate newly created object
	if obj.has_method("_on_spawn"):
		obj._on_spawn()

	return obj

## Return an object to the pool
func return_object(obj: Node) -> void:
	if not obj or not is_instance_valid(obj):
		return

	# Remove from active objects
	active_objects.erase(obj)

	# Non-pooled objects should be freed
	if not obj.is_in_group("pooled_objects"):
		if obj.is_inside_tree():
			obj.get_parent().remove_child(obj)
		obj.queue_free()
		return

	# Make sure object is a child of the pool
	if obj.get_parent() != self:
		if obj.is_inside_tree():
			obj.get_parent().remove_child(obj)
		add_child(obj)

	# Reset object state
	obj.visible = false
	obj.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	if obj.has_method("reset_pool_state"):
		obj.reset_pool_state()

	# Return to available pool (or free if pool is full)
	if available_objects.size() < pool_size:
		available_objects.append(obj)
	else:
		# Pool full - remove and free the object
		remove_child(obj)
		obj.queue_free()

## Clear all objects from pool
func clear_pool() -> void:
	# Return all active objects
	for obj in active_objects.duplicate():
		return_object(obj)
	
	# Clear available objects
	for obj in available_objects:
		if obj.is_inside_tree():
			obj.get_parent().remove_child(obj)
			obj.queue_free()
	
	available_objects.clear()
	active_objects.clear()

## Get pool statistics
func get_pool_stats() -> Dictionary:
	return {
		"available": available_objects.size(),
		"active": active_objects.size(),
		"total_created": available_objects.size() + active_objects.size(),
		"pool_size": pool_size
	}

## Check if object is from this pool
func is_pooled_object(obj: Node) -> bool:
	return obj.is_in_group("pooled_objects")
