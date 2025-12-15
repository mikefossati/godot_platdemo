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

## Star Rating Thresholds
@export_group("Star Rating")
@export var gold_time: float = 30.0  ## Time requirement for 3 stars (seconds)
@export var silver_time: float = 45.0  ## Time requirement for 2 stars (seconds)
@export var bronze_time: float = 60.0  ## Time requirement for 1 star (seconds)
@export var require_all_collectibles: bool = true  ## Must collect all stars for 3-star rating
@export var require_perfect_run: bool = false  ## Must have no deaths for 3-star rating


func _init(
	p_level_id: String = "",
	p_level_name: String = "",
	p_scene_path: String = "",
	p_difficulty: int = 1,
	p_description: String = "",
	p_unlock_requirement: String = "",
	p_gold_time: float = 30.0,
	p_silver_time: float = 45.0,
	p_bronze_time: float = 60.0,
	p_require_all_collectibles: bool = true,
	p_require_perfect_run: bool = false
) -> void:
	level_id = p_level_id
	level_name = p_level_name
	scene_path = p_scene_path
	difficulty = p_difficulty
	description = p_description
	unlock_requirement = p_unlock_requirement
	gold_time = p_gold_time
	silver_time = p_silver_time
	bronze_time = p_bronze_time
	require_all_collectibles = p_require_all_collectibles
	require_perfect_run = p_require_perfect_run
