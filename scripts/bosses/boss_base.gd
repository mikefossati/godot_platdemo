class_name Boss
extends CharacterBody3D

## BossBase - Foundation for all boss enemies.
## Manages health, phases, and provides virtual functions for specific boss logic.

signal phase_changed(phase_number)
signal boss_defeated

@onready var health_component: HealthComponent = $HealthComponent

@export_group("Boss Settings")
@export var phase_thresholds: Array[int] = [7, 4] # HP values that trigger phase changes

var current_phase: int = 1

func _ready() -> void:
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_defeated)
	else:
		push_error("Boss scene is missing a HealthComponent node: %s" % self.name)

func _on_health_changed(new_health: int, _max_health: int) -> void:
	# Check for phase transitions
	for i in range(phase_thresholds.size()):
		# Phases are 1-indexed, arrays are 0-indexed
		var phase_number = i + 2 
		if new_health <= phase_thresholds[i] and current_phase < phase_number:
			current_phase = phase_number
			phase_changed.emit(current_phase)
			transition_to_phase(current_phase)
			break # Transition to one phase at a time

func _on_defeated() -> void:
	boss_defeated.emit()
	# Default death behavior
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


# ========== VIRTUAL FUNCTIONS FOR BOSS IMPLEMENTATIONS ==========

func transition_to_phase(phase: int) -> void:
	# This function should be overridden by specific boss scripts
	# to change attack patterns, behavior, etc.
	pass
