extends Node

## LevelSession - Tracks player performance during a level playthrough
## Autoload singleton that monitors time, deaths, and collectibles for star rating
## Critical for commercial game progression and player engagement

# Session statistics
var level_start_time: float = 0.0
var current_level_time: float = 0.0
var death_count: int = 0
var coins_collected: int = 0  # Track coins collected during session
var crystals_collected: int = 0  # Track crown crystals collected
var is_session_active: bool = false
var is_paused: bool = false

# Phase 4: Checkpoint system
var checkpoint_position: Vector3 = Vector3.ZERO
var has_checkpoint: bool = false
var checkpoint_active_id: int = -1  # Track which checkpoint is active

# Phase 3 medal requirements
const COINS_PER_LEVEL: int = 100
const CRYSTALS_PER_LEVEL: int = 3

# Signals for UI updates
signal timer_updated(time: float)
signal death_recorded(death_count: int)
signal session_started
signal session_ended(stats: Dictionary)


func _ready() -> void:
	# Connect to GameManager signals
	if GameManager:
		GameManager.game_over.connect(_on_player_death)


func _process(delta: float) -> void:
	if is_session_active and not is_paused:
		current_level_time += delta
		timer_updated.emit(current_level_time)


## Start a new level session
func start_session() -> void:
	level_start_time = Time.get_ticks_msec() / 1000.0
	current_level_time = 0.0
	death_count = 0
	coins_collected = 0
	crystals_collected = 0
	is_session_active = true
	is_paused = false
	# Clear checkpoint data
	checkpoint_position = Vector3.ZERO
	has_checkpoint = false
	checkpoint_active_id = -1
	session_started.emit()
	print("LevelSession: Session started")


## End the current level session and return statistics
func end_session() -> Dictionary:
	is_session_active = false

	var stats = {
		"completion_time": current_level_time,
		"death_count": death_count,
		"collectibles_gathered": GameManager.collectibles_gathered,
		"total_collectibles": GameManager.total_collectibles,
		"coins_collected": coins_collected,
		"crystals_collected": crystals_collected,
		"perfect_run": death_count == 0,
		"all_collectibles": GameManager.collectibles_gathered >= GameManager.total_collectibles,
		"all_coins": coins_collected >= COINS_PER_LEVEL,
		"all_crystals": crystals_collected >= CRYSTALS_PER_LEVEL
	}

	session_ended.emit(stats)
	print("LevelSession: Session ended - Time: %.2fs, Deaths: %d, Coins: %d, Crystals: %d" % [
		stats.completion_time,
		stats.death_count,
		stats.coins_collected,
		stats.crystals_collected
	])

	return stats


## Pause the session timer
func pause_session() -> void:
	is_paused = true


## Resume the session timer
func resume_session() -> void:
	is_paused = false


## Record a player death
func record_death() -> void:
	if is_session_active:
		death_count += 1
		death_recorded.emit(death_count)
		print("LevelSession: Death recorded (total: %d)" % death_count)


## Called when player dies (connected to GameManager.game_over)
func _on_player_death() -> void:
	record_death()


## Track coin collection (called by coin collectibles)
func record_coin_collected(value: int = 1) -> void:
	if is_session_active:
		coins_collected += value


## Track crystal collection (called by crown crystal collectibles)
func record_crystal_collected() -> void:
	if is_session_active:
		crystals_collected += 1
		print("LevelSession: Crystal collected (%d/%d)" % [crystals_collected, CRYSTALS_PER_LEVEL])


## Get current session time
func get_session_time() -> float:
	return current_level_time


## Get current death count
func get_death_count() -> int:
	return death_count


## Check if session is active
func is_active() -> bool:
	return is_session_active


## Calculate star rating based on level data and session stats
## Phase 3 Medal System:
## - Medal 1: Complete level (collect all 3 crown crystals)
## - Medal 2: Collect all 100 coins
## - Medal 3: Complete under target time
func calculate_star_rating(level_data: LevelData, stats: Dictionary) -> int:
	if level_data == null:
		push_error("LevelSession: Cannot calculate stars without level_data")
		return 0

	var stars = 0

	# Medal 1: Complete level (all crystals)
	if stats.get("all_crystals", false) or stats.get("all_collectibles", false):
		stars = 1

	# Medal 2: Collect all coins
	if stats.get("all_coins", false):
		stars = max(stars, 2)

	# Medal 3: Complete under target time
	var time = stats.completion_time
	if time <= level_data.gold_time:
		stars = 3
	elif stars >= 2 and time <= level_data.silver_time:
		# Only award time medal if you have at least 2 other medals
		stars = 3

	print("LevelSession: Calculated %d stars (Time: %.2fs, Crystals: %s, Coins: %s)" % [
		stars,
		time,
		stats.get("all_crystals", false),
		stats.get("all_coins", false)
	])

	return stars


## Phase 4: Set checkpoint position
func set_checkpoint(position: Vector3, checkpoint_id: int = -1) -> void:
	checkpoint_position = position
	has_checkpoint = true
	checkpoint_active_id = checkpoint_id
	if OS.is_debug_build():
		print("LevelSession: Checkpoint saved at %s (ID: %d)" % [position, checkpoint_id])


## Phase 4: Respawn player at checkpoint
func respawn_at_checkpoint(player: Player) -> bool:
	if has_checkpoint and player:
		# Spawn slightly above checkpoint to avoid ground collision
		player.global_position = checkpoint_position + Vector3(0, 1.0, 0)
		# Reset player velocity
		player.velocity = Vector3.ZERO
		if OS.is_debug_build():
			print("LevelSession: Player respawned at checkpoint %d" % checkpoint_active_id)
		return true
	return false


## Phase 4: Clear checkpoint data
func clear_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_position = Vector3.ZERO
	checkpoint_active_id = -1
	if OS.is_debug_build():
		print("LevelSession: Checkpoint cleared")


## Phase 4: Check if checkpoint is active
func has_active_checkpoint() -> bool:
	return has_checkpoint


## Get a detailed performance summary
func get_performance_summary(level_data: LevelData = null) -> Dictionary:
	var stats = {
		"time": current_level_time,
		"deaths": death_count,
		"collectibles": GameManager.collectibles_gathered,
		"total_collectibles": GameManager.total_collectibles,
		"perfect_run": death_count == 0,
		"all_collectibles": GameManager.collectibles_gathered >= GameManager.total_collectibles
	}

	if level_data != null:
		stats["stars"] = calculate_star_rating(level_data, stats)
		stats["gold_time"] = level_data.gold_time
		stats["silver_time"] = level_data.silver_time
		stats["bronze_time"] = level_data.bronze_time

		# Calculate time rank
		if stats.time <= level_data.gold_time:
			stats["time_rank"] = "GOLD"
		elif stats.time <= level_data.silver_time:
			stats["time_rank"] = "SILVER"
		elif stats.time <= level_data.bronze_time:
			stats["time_rank"] = "BRONZE"
		else:
			stats["time_rank"] = "NONE"

	return stats
