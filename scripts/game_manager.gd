extends Node

## GameManager - Autoload singleton for managing global game state
## This script persists across scenes and handles score, collectibles, and scene transitions

# Current session state
var score: int = 0
var collectibles_gathered: int = 0
var total_collectibles: int = 0

# Level progression state
var current_level_index: int = 0
var current_level_data: LevelData = null
var unlocked_levels: Array[String] = ["level_1"]  # Array of unlocked level IDs

# Level registry - all available levels
var level_registry: Array[LevelData] = []

# Statistics per level
var level_stats: Dictionary = {}

# Save file path
const SAVE_PATH: String = "user://game_save.cfg"

# Signals to notify other nodes of state changes
signal score_changed(new_score: int)
signal collectible_gathered(current: int, total: int)
signal game_over
signal level_complete
signal level_unlocked(level_id: String)


func _ready() -> void:
	# Initialize level registry
	_initialize_levels()
	# Load saved progress
	load_game()
	# Reset current session
	reset_game()


## Initialize the level registry with all available levels
func _initialize_levels() -> void:
	level_registry.clear()

	# Level 1 - Tutorial/Easy
	var level_1 = LevelData.new(
		"level_1",
		"First Steps",
		"res://scenes/levels/level_1.tscn",
		1,
		"Learn the basics of movement and jumping.",
		"",
		45.0
	)
	level_registry.append(level_1)

	# Level 2 - Medium
	var level_2 = LevelData.new(
		"level_2",
		"Rising Challenge",
		"res://scenes/levels/level_2.tscn",
		2,
		"Test your platforming skills with trickier jumps.",
		"level_1",
		60.0
	)
	level_registry.append(level_2)

	# Level 3 - Hard
	var level_3 = LevelData.new(
		"level_3",
		"Sky High",
		"res://scenes/levels/level_3.tscn",
		3,
		"Master the art of precision platforming.",
		"level_2",
		75.0
	)
	level_registry.append(level_3)


## Resets the current session state (not progression)
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
		# Find the player in the current scene and trigger victory animation
		var player = _find_player()
		if player and player.has_method("play_victory_animation"):
			player.play_victory_animation()
			# Wait for wave animation to complete before showing level complete screen
			await get_tree().create_timer(5.0).timeout

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
	complete_current_level()
	level_complete.emit()
	load_scene("res://scenes/ui/level_complete.tscn")


## Starts the game from the main menu (goes to level select)
func start_game() -> void:
	load_scene("res://scenes/ui/level_select.tscn")


## Load a specific level by index
func load_level(level_index: int) -> void:
	if level_index < 0 or level_index >= level_registry.size():
		push_error("Invalid level index: %d" % level_index)
		return

	current_level_index = level_index
	current_level_data = level_registry[level_index]
	reset_game()
	load_scene(current_level_data.scene_path)


## Load a specific level by ID
func load_level_by_id(level_id: String) -> void:
	for i in range(level_registry.size()):
		if level_registry[i].level_id == level_id:
			load_level(i)
			return
	push_error("Level not found: %s" % level_id)


## Load the next level in sequence
func load_next_level() -> void:
	var next_index = current_level_index + 1
	if next_index < level_registry.size():
		load_level(next_index)
	else:
		# No more levels, return to level select
		load_scene("res://scenes/ui/level_select.tscn")


## Check if a level is unlocked
func is_level_unlocked(level_id: String) -> bool:
	return level_id in unlocked_levels


## Unlock a level
func unlock_level(level_id: String) -> void:
	if not is_level_unlocked(level_id):
		unlocked_levels.append(level_id)
		level_unlocked.emit(level_id)
		save_game()


## Mark current level as complete and unlock next level
func complete_current_level() -> void:
	if current_level_data == null:
		return

	var level_id = current_level_data.level_id

	# Update stats
	if not level_stats.has(level_id):
		level_stats[level_id] = {
			"completed": false,
			"best_score": 0,
			"times_played": 0
		}

	level_stats[level_id]["completed"] = true
	level_stats[level_id]["times_played"] += 1

	# Update best score if better
	if score > level_stats[level_id]["best_score"]:
		level_stats[level_id]["best_score"] = score

	# Unlock next level
	var next_index = current_level_index + 1
	if next_index < level_registry.size():
		var next_level = level_registry[next_index]
		unlock_level(next_level.level_id)

	save_game()


## Returns to main menu
func return_to_menu() -> void:
	reset_game()
	load_scene("res://scenes/ui/main_menu.tscn")


## Return to level select
func return_to_level_select() -> void:
	reset_game()
	load_scene("res://scenes/ui/level_select.tscn")


## Save game progress
func save_game() -> void:
	var save_file = ConfigFile.new()

	# Save unlocked levels
	save_file.set_value("progression", "unlocked_levels", unlocked_levels)

	# Save level stats
	save_file.set_value("stats", "level_stats", level_stats)

	# Save metadata
	save_file.set_value("meta", "version", "1.0")
	save_file.set_value("meta", "last_played", Time.get_datetime_string_from_system())

	var err = save_file.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game: %d" % err)


## Load game progress
func load_game() -> void:
	var save_file = ConfigFile.new()
	var err = save_file.load(SAVE_PATH)

	if err != OK:
		# No save file exists, use defaults
		unlocked_levels = ["level_1"]
		level_stats = {}
		return

	# Load unlocked levels
	unlocked_levels = save_file.get_value("progression", "unlocked_levels", ["level_1"])

	# Load level stats
	level_stats = save_file.get_value("stats", "level_stats", {})


## Find the player node in the current scene
func _find_player() -> Node:
	# Look for a node in the "player" group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
