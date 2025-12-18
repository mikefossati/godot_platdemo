extends BaseEnemy

## ArmoredKnight - A slower, tougher enemy with 2 HP.

# A new material to show the damaged state.
@export var damaged_material: Material

func _ready() -> void:
	super._ready()

	# Knight-specific properties
	health_component.max_health = 2
	health_component.current_health = 2 # Ensure it starts with full health
	move_speed = 1.5
	coins_dropped = 5
	detection_range = 4.0

	# Connect to the health_changed signal to show damage
	health_component.health_changed.connect(_on_health_changed)


func _on_health_changed(new_health: int, _max_health: int) -> void:
	# If health is 1, show the damaged state
	if new_health == 1 and damaged_material:
		# Try to find the mesh in the Enemy model structure
		var model = get_node_or_null("CharacterModel/Enemy/Armature/Skeleton3D/Cube")
		if model:
			model.material_override = damaged_material
