extends BaseEnemy

## Goblin - Basic melee enemy
## Inherits most behavior from BaseEnemy.

func _ready() -> void:
	# Call the parent's ready function first
	super._ready()

	# Goblin-specific properties
	health_component.max_health = 1
	move_speed = 2.0
	coins_dropped = 3
	detection_range = 5.0
