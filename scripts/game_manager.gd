extends Node

## GameManager - Autoload singleton for managing global game state
## This script persists across scenes and handles score, collectibles, and scene transitions

# Game state variables
var score: int = 0
var collectibles_gathered: int = 0
var total_collectibles: int = 0

# Signals to notify other nodes of state changes
signal score_changed(new_score: int)
signal collectible_gathered(current: int, total: int)
signal game_over
signal level_complete


func _ready() -> void:
	# Initialize game state when the game starts
	reset_game()


## Resets the game state to default values
func reset_game() -> void:
	score = 0
	collectibles_gathered = 0
	total_collectibles = 0


## Called when a collectible is picked up
## Increments the collectible counter and emits a signal
func collect_item(points: int = 10) -> void:
	collectibles_gathered += 1
	score += points
	score_changed.emit(score)
	collectible_gathered.emit(collectibles_gathered, total_collectibles)

	# Check if all collectibles have been gathered
	if collectibles_gathered >= total_collectibles and total_collectibles > 0:
		trigger_level_complete()


## Sets the total number of collectibles in the current level
func set_total_collectibles(total: int) -> void:
	total_collectibles = total


## Loads a scene by path
func load_scene(scene_path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", scene_path)


## Triggers game over state
func trigger_game_over() -> void:
	game_over.emit()
	load_scene("res://scenes/ui/game_over.tscn")


## Triggers level complete state
func trigger_level_complete() -> void:
	level_complete.emit()
	load_scene("res://scenes/ui/level_complete.tscn")


## Starts the game from the main menu
func start_game() -> void:
	reset_game()
	load_scene("res://scenes/level/main_level.tscn")


## Returns to main menu
func return_to_menu() -> void:
	reset_game()
	load_scene("res://scenes/ui/main_menu.tscn")
