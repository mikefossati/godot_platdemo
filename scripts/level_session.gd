extends Node

## LevelSession - Tracks player performance during a level playthrough
## Autoload singleton that monitors time, deaths, and collectibles for star rating
## Critical for commercial game progression and player engagement

# Session statistics
var level_start_time: float = 0.0
var current_level_time: float = 0.0
var death_count: int = 0
var is_session_active: bool = false
var is_paused: bool = false

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
	is_session_active = true
	is_paused = false
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
		"perfect_run": death_count == 0,
		"all_collectibles": GameManager.collectibles_gathered >= GameManager.total_collectibles
	}

	session_ended.emit(stats)
	print("LevelSession: Session ended - Time: %.2fs, Deaths: %d, Collectibles: %d/%d" % [
		stats.completion_time,
		stats.death_count,
		stats.collectibles_gathered,
		stats.total_collectibles
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
func calculate_star_rating(level_data: LevelData, stats: Dictionary) -> int:
	if level_data == null:
		push_error("LevelSession: Cannot calculate stars without level_data")
		return 0

	var stars = 0

	# Check time requirements
	var time = stats.completion_time
	if time <= level_data.gold_time:
		stars = 3
	elif time <= level_data.silver_time:
		stars = 2
	elif time <= level_data.bronze_time:
		stars = 1

	# Additional requirements for 3 stars
	if stars == 3:
		# Check if all collectibles required
		if level_data.require_all_collectibles:
			if not stats.all_collectibles:
				stars = 2  # Downgrade to 2 stars

		# Check if perfect run required
		if level_data.require_perfect_run:
			if not stats.perfect_run:
				stars = min(stars, 2)  # Downgrade to 2 stars

	# Special case: If you got all collectibles and no deaths, minimum 2 stars
	if stats.all_collectibles and stats.perfect_run and stars < 2:
		stars = 2

	print("LevelSession: Calculated %d stars (Time: %.2fs, Perfect: %s, All collectibles: %s)" % [
		stars,
		time,
		stats.perfect_run,
		stats.all_collectibles
	])

	return stars


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
