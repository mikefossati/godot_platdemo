extends Node

## GameManager - Autoload singleton for managing global game state
## This script persists across scenes and handles score, collectibles, and scene transitions

# Current session state
var score: int = 0
var collectibles_gathered: int = 0
var total_collectibles: int = 0

# Combat combo state
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _coin_multiplier: float = 1.0
const COMBO_TIMEOUT: float = 2.5

# Ability unlocks
var unlocked_abilities: Dictionary = {
	"double_jump": false,
	"ground_pound": false,
	"air_dash": false
}

# Level progression state
var current_level_index: int = 0
var current_level_data: LevelData = null
var unlocked_levels: Array[String] = ["level_1", "level_6"]  # Array of unlocked level IDs

# Cached player reference (reset on each level load)
var cached_player: Node = null

# Level registry - all available levels
var level_registry: Array[LevelData] = []

# Statistics per level
var level_stats: Dictionary = {}

# Save file path
const SAVE_PATH: String = GameConstants.SAVE_PATH

# Signals to notify other nodes of state changes
signal score_changed(new_score: int)
signal collectible_gathered(current: int, total: int)
signal game_over
signal level_complete
signal level_unlocked(level_id: String)
signal combo_updated(combo_count: int, multiplier: float)


func _process(delta: float) -> void:
	if _combo_timer > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_reset_combo()


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
		20.0,  # gold_time
		30.0,  # silver_time
		45.0,  # bronze_time
		true,  # require_all_collectibles
		false  # require_perfect_run
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
		30.0,  # gold_time
		45.0,  # silver_time
		60.0,  # bronze_time
		true,  # require_all_collectibles
		false  # require_perfect_run
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
		45.0,  # gold_time
		60.0,  # silver_time
		75.0,  # bronze_time
		true,  # require_all_collectibles
		false  # require_perfect_run
	)
	level_registry.append(level_3)

	# Level 4 - Moving Platforms (Linear)
	var level_4 = LevelData.new(
		"level_4",
		"Linear Motion",
		"res://scenes/levels/level_4.tscn",
		3,
		"Navigate moving platforms with precise timing.",
		"level_3",
		50.0,  # gold_time
		70.0,  # silver_time
		90.0,  # bronze_time
		true,  # require_all_collectibles
		false  # require_perfect_run
	)
	level_registry.append(level_4)

	# Level 5 - Moving Platforms (Circular)
	var level_5 = LevelData.new(
		"level_5",
		"Orbital Dance",
		"res://scenes/levels/level_5.tscn",
		4,
		"Master circular platforms in a rotating ballet.",
		"level_4",
		60.0,  # gold_time
		80.0,  # silver_time
		100.0,  # bronze_time
		true,  # require_all_collectibles
		false  # require_perfect_run
	)
	level_registry.append(level_5)

	# Level 6 - Combat Showcase
	var level_6 = LevelData.new(
		"level_6",
		"Combat Showcase",
		"res://scenes/levels/level_combat_showcase.tscn",
		5,
		"Test your might against new foes.",
		"level_5",
		45.0,  # gold_time
		60.0,  # silver_time
		75.0,  # bronze_time
		false, # require_all_collectibles
		false  # require_perfect_run
	)
	level_registry.append(level_6)


## Resets the current session state (not progression)
func reset_game() -> void:
	score = 0
	collectibles_gathered = 0
	total_collectibles = 0
	cached_player = null  # Invalidate player cache when resetting game
	_reset_combo()


## Called when a collectible is picked up
## Increments the collectible counter and emits a signal
func add_coins(amount: int) -> void:
	var coins_to_add = int(amount * _coin_multiplier)
	score += coins_to_add
	score_changed.emit(score)


func record_jump_kill() -> void:
	_combo_count += 1
	_combo_timer = COMBO_TIMEOUT
	_coin_multiplier = 1.0 + (_combo_count * 0.5)
	combo_updated.emit(_combo_count, _coin_multiplier)


func _reset_combo() -> void:
	_combo_count = 0
	_combo_timer = 0.0
	_coin_multiplier = 1.0
	combo_updated.emit(_combo_count, _coin_multiplier)


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
			await get_tree().create_timer(GameConstants.VICTORY_WAIT_DURATION).timeout

		trigger_level_complete()


## Sets the total number of collectibles in the current level
func set_total_collectibles(total: int) -> void:
	total_collectibles = total


## Loads a scene by path
func load_scene(scene_path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", scene_path)


## Triggers game over state
func trigger_game_over() -> void:
	_reset_combo()
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

	# Start level session for time/death tracking (after scene loads)
	await get_tree().process_frame
	if LevelSession:
		LevelSession.start_session()


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

	# End level session and get stats
	var session_stats = {}
	if LevelSession and LevelSession.is_active():
		session_stats = LevelSession.end_session()
	else:
		# Fallback stats if session wasn't active
		session_stats = {
			"completion_time": 0.0,
			"death_count": 0,
			"collectibles_gathered": collectibles_gathered,
			"total_collectibles": total_collectibles,
			"perfect_run": true,
			"all_collectibles": collectibles_gathered >= total_collectibles
		}

	# Calculate star rating
	var stars = 0
	if LevelSession:
		stars = LevelSession.calculate_star_rating(current_level_data, session_stats)

	# Initialize stats if first completion
	if not level_stats.has(level_id):
		level_stats[level_id] = {
			"completed": false,
			"best_score": 0,
			"best_time": 999999.0,
			"best_stars": 0,
			"times_played": 0,
			"total_deaths": 0
		}

	# Update stats
	level_stats[level_id]["completed"] = true
	level_stats[level_id]["times_played"] += 1

	# Handle new fields with backward compatibility
	if not level_stats[level_id].has("total_deaths"):
		level_stats[level_id]["total_deaths"] = 0
	level_stats[level_id]["total_deaths"] += session_stats.get("death_count", 0)

	# Update best score if better
	if score > level_stats[level_id]["best_score"]:
		level_stats[level_id]["best_score"] = score

	# Update best time if better (with backward compatibility)
	if not level_stats[level_id].has("best_time"):
		level_stats[level_id]["best_time"] = 999999.0
	var completion_time = session_stats.get("completion_time", 0.0)
	if completion_time > 0 and completion_time < level_stats[level_id]["best_time"]:
		level_stats[level_id]["best_time"] = completion_time

	# Update best stars if better (with backward compatibility)
	if not level_stats[level_id].has("best_stars"):
		level_stats[level_id]["best_stars"] = 0
	if stars > level_stats[level_id]["best_stars"]:
		level_stats[level_id]["best_stars"] = stars
		print("New best! Achieved %d stars on %s" % [stars, current_level_data.level_name])

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

	# Save ability unlocks
	save_file.set_value("progression", "unlocked_abilities", unlocked_abilities)

	# Save level stats
	save_file.set_value("stats", "level_stats", level_stats)

	# Save metadata
	save_file.set_value("meta", "version", GameConstants.SAVE_VERSION)
	save_file.set_value("meta", "last_played", Time.get_datetime_string_from_system())

	var err = save_file.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game: %d" % err)
	else:
		print("Game saved successfully to: %s" % SAVE_PATH)


## Load game progress
func load_game() -> void:
	var save_file = ConfigFile.new()
	var err = save_file.load(SAVE_PATH)

	if err != OK:
		# No save file exists, use defaults
		print("No save file found, using defaults")
		_use_default_save_data()
		return

	# Validate save file
	if not _validate_save_file(save_file):
		push_warning("Save file validation failed, using defaults")
		_use_default_save_data()
		return

	# Load and validate version
	var save_version = save_file.get_value("meta", "version", "0.0")
	if not _is_save_version_compatible(save_version):
		push_warning("Save file version %s incompatible with current version %s" % [save_version, GameConstants.SAVE_VERSION])
		# Attempt migration
		if not _migrate_save_file(save_file, save_version):
			push_error("Save file migration failed, using defaults")
			_use_default_save_data()
			return

	# Load unlocked levels with validation
	var default_unlocked = ["level_1", "level_6"]
	var loaded_levels = save_file.get_value("progression", "unlocked_levels", default_unlocked)
	if _validate_unlocked_levels(loaded_levels):
		# Merge loaded levels with default test levels to ensure they are always available
		var combined_levels = loaded_levels + default_unlocked
		var unique_levels: Array[String] = []
		for level in combined_levels:
			if not level in unique_levels:
				unique_levels.append(level)
		unlocked_levels = unique_levels
	else:
		push_warning("Invalid unlocked_levels data, using defaults")
		unlocked_levels = default_unlocked

	# Load level stats with validation
	var loaded_stats = save_file.get_value("stats", "level_stats", {})
	if _validate_level_stats(loaded_stats):
		level_stats = loaded_stats
	else:
		push_warning("Invalid level_stats data, using defaults")
		level_stats = {}

	# Load ability unlocks
	var loaded_abilities = save_file.get_value("progression", "unlocked_abilities", {})
	if loaded_abilities is Dictionary:
		# Merge loaded abilities with defaults (in case new abilities were added)
		for ability in unlocked_abilities.keys():
			if loaded_abilities.has(ability):
				unlocked_abilities[ability] = loaded_abilities[ability]
	else:
		push_warning("Invalid unlocked_abilities data, using defaults")

	print("Game loaded successfully from: %s" % SAVE_PATH)


## Use default save data
func _use_default_save_data() -> void:
	unlocked_levels = ["level_1", "level_6"]
	level_stats = {}


## Validate save file structure
func _validate_save_file(save_file: ConfigFile) -> bool:
	# Check required sections exist
	if not save_file.has_section("meta"):
		push_error("Save file missing 'meta' section")
		return false

	if not save_file.has_section("progression"):
		push_error("Save file missing 'progression' section")
		return false

	if not save_file.has_section("stats"):
		push_error("Save file missing 'stats' section")
		return false

	# Check required keys exist
	if not save_file.has_section_key("meta", "version"):
		push_error("Save file missing version info")
		return false

	return true


## Check if save version is compatible
func _is_save_version_compatible(save_version: String) -> bool:
	# For now, only version 1.0 is supported
	# Future versions should implement migration logic
	return save_version == GameConstants.SAVE_VERSION


## Migrate save file from old version to current version
func _migrate_save_file(_save_file: ConfigFile, _from_version: String) -> bool:
	# No migrations needed yet (only version 1.0 exists)
	# Future versions should implement migration logic here
	push_warning("Save file migration not yet implemented")
	return false


## Validate unlocked_levels data
func _validate_unlocked_levels(data: Variant) -> bool:
	# Must be an Array
	if not data is Array:
		push_error("unlocked_levels is not an Array")
		return false

	# Must contain at least level_1
	if not "level_1" in data:
		push_error("unlocked_levels doesn't contain level_1")
		return false

	# All entries should be strings
	for level_id in data:
		if not level_id is String:
			push_error("unlocked_levels contains non-String entry: %s" % level_id)
			return false

	return true


## Validate level_stats data
func _validate_level_stats(data: Variant) -> bool:
	# Must be a Dictionary
	if not data is Dictionary:
		push_error("level_stats is not a Dictionary")
		return false

	# Validate each level's stats
	for level_id in data.keys():
		if not level_id is String:
			push_error("level_stats contains non-String key")
			return false

		var stats = data[level_id]
		if not stats is Dictionary:
			push_error("level_stats[%s] is not a Dictionary" % level_id)
			return false

		# Validate required fields (with backward compatibility)
		if not stats.has("completed") or not stats["completed"] is bool:
			push_error("level_stats[%s] missing or invalid 'completed'" % level_id)
			return false

		if not stats.has("best_score") or not stats["best_score"] is int:
			push_error("level_stats[%s] missing or invalid 'best_score'" % level_id)
			return false

		if not stats.has("times_played") or not stats["times_played"] is int:
			push_error("level_stats[%s] missing or invalid 'times_played'" % level_id)
			return false

		# Optional new fields (will be added on next save if missing)
		# No validation failure if missing - backward compatibility

	return true


## Check if an ability is unlocked
func is_ability_unlocked(ability_name: String) -> bool:
	if unlocked_abilities.has(ability_name):
		return unlocked_abilities[ability_name]
	push_warning("Unknown ability: %s" % ability_name)
	return false


## Unlock an ability
func unlock_ability(ability_name: String) -> void:
	if unlocked_abilities.has(ability_name):
		unlocked_abilities[ability_name] = true
		print("Ability unlocked: %s" % ability_name)
		save_game()

		# Notify the player to update their abilities
		var player = _find_player()
		if player:
			match ability_name:
				"double_jump":
					if player.has_method("unlock_double_jump"):
						player.unlock_double_jump()
				"ground_pound":
					if player.has_method("unlock_ground_pound"):
						player.unlock_ground_pound()
				"air_dash":
					if player.has_method("unlock_air_dash"):
						player.unlock_air_dash()
	else:
		push_warning("Unknown ability: %s" % ability_name)


## Purchase an ability from the shop (placeholder for Phase 3)
func purchase_ability(ability_name: String, cost: int) -> bool:
	if score >= cost:
		score -= cost
		unlock_ability(ability_name)
		score_changed.emit(score)
		return true
	return false


## Find the player node in the current scene (with caching for performance)
func _find_player() -> Node:
	# Return cached player if still valid
	if cached_player != null and is_instance_valid(cached_player):
		return cached_player

	# Cache miss - search for player in scene tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		cached_player = players[0]
		return cached_player

	# No player found
	cached_player = null
	return null
