extends Node

## Object Pool - Generic pooling system for reusable nodes
## Reduces memory allocation and garbage collection by reusing objects
## instead of constantly creating and destroying them

## The scene to instantiate for pooled objects
@export var pooled_scene: PackedScene

## Initial number of objects to pre-allocate
@export var initial_pool_size: int = 10

## Maximum pool size (0 = unlimited)
@export var max_pool_size: int = 50

# Available objects ready to be used
var _available_objects: Array[Node] = []

# Objects currently in use
var _active_objects: Array[Node] = []


func _ready() -> void:
	# Pre-allocate initial pool
	for i in range(initial_pool_size):
		var obj = _create_new_object()
		_available_objects.append(obj)


## Get an object from the pool (or create new one if pool is empty)
func acquire() -> Node:
	var obj: Node = null

	if _available_objects.size() > 0:
		# Reuse object from pool
		obj = _available_objects.pop_back()
	else:
		# Pool is empty, create new object
		obj = _create_new_object()

	# Mark as active
	_active_objects.append(obj)

	# Enable the object
	obj.set_process(true)
	obj.set_physics_process(true)
	obj.show()

	# Call reset method if available
	if obj.has_method("reset_pooled_object"):
		obj.reset_pooled_object()

	return obj


## Return an object to the pool
func release(obj: Node) -> void:
	if obj == null or not is_instance_valid(obj):
		return

	# Remove from active list
	var index = _active_objects.find(obj)
	if index != -1:
		_active_objects.remove_at(index)

	# Check pool size limit
	if max_pool_size > 0 and _available_objects.size() >= max_pool_size:
		# Pool is full, destroy the object
		obj.queue_free()
		return

	# Disable the object
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.hide()

	# Remove from scene tree (keep as child but hidden)
	if obj.get_parent() != self:
		if obj.get_parent() != null:
			obj.get_parent().remove_child(obj)
		add_child(obj)

	# Return to pool
	_available_objects.append(obj)


## Create a new pooled object
func _create_new_object() -> Node:
	if pooled_scene == null:
		push_error("ObjectPool: No pooled_scene assigned!")
		return null

	var obj = pooled_scene.instantiate()
	add_child(obj)
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.hide()

	return obj


## Get current pool statistics
func get_pool_stats() -> Dictionary:
	return {
		"available": _available_objects.size(),
		"active": _active_objects.size(),
		"total": _available_objects.size() + _active_objects.size()
	}


## Clear all pooled objects
func clear_pool() -> void:
	# Release all active objects
	for obj in _active_objects.duplicate():
		release(obj)

	# Free all available objects
	for obj in _available_objects:
		if is_instance_valid(obj):
			obj.queue_free()

	_available_objects.clear()
	_active_objects.clear()
