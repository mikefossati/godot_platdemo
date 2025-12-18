class_name HealthComponent
extends Node

signal health_changed(new_health, max_health)
signal died

@export var max_health: int = 3
var current_health: int = 0

var invulnerable: bool = false

func _ready():
	current_health = max_health
	# Emit initial health state so HUD can create hearts
	health_changed.emit(current_health, max_health)

func take_damage(amount: int):
	if invulnerable or current_health <= 0:
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		died.emit()
	else:
		start_invulnerability(1.0)

func heal(amount: int):
	if current_health >= max_health:
		return
		
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func start_invulnerability(duration: float):
	invulnerable = true

	# Visual feedback for invulnerability - flash visibility
	if owner.has_node("CharacterModel"):
		var model = owner.get_node("CharacterModel")
		_flash_visual(model, duration)

	await get_tree().create_timer(duration).timeout
	invulnerable = false

# Flash the model by toggling visibility
func _flash_visual(model: Node, duration: float):
	var flash_interval = duration / 6.0
	for i in range(3):
		await get_tree().create_timer(flash_interval).timeout
		model.visible = false
		await get_tree().create_timer(flash_interval).timeout
		model.visible = true
