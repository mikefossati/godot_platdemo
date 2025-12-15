extends Resource
class_name LevelData

## LevelData Resource - Defines metadata for each game level
## This resource allows levels to be defined in the editor with all their properties

@export var level_id: String = ""
@export var level_name: String = ""
@export var scene_path: String = ""
@export var difficulty: int = 1
@export_multiline var description: String = ""
@export var unlock_requirement: String = ""
@export var par_time: float = 60.0


func _init(
	p_level_id: String = "",
	p_level_name: String = "",
	p_scene_path: String = "",
	p_difficulty: int = 1,
	p_description: String = "",
	p_unlock_requirement: String = "",
	p_par_time: float = 60.0
) -> void:
	level_id = p_level_id
	level_name = p_level_name
	scene_path = p_scene_path
	difficulty = p_difficulty
	description = p_description
	unlock_requirement = p_unlock_requirement
	par_time = p_par_time
