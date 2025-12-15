extends CanvasLayer

## GameHUD - In-game heads-up display
## Shows timer, collectibles, score, and FPS based on settings

# UI References
@onready var timer_label: Label = $TopLeft/TimerLabel
@onready var collectibles_label: Label = $TopLeft/CollectiblesLabel
@onready var score_label: Label = $TopLeft/ScoreLabel
@onready var fps_label: Label = $TopRight/FPSLabel
@onready var death_counter_label: Label = $TopLeft/DeathCounterLabel

# State
var _show_timer: bool = true
var _show_fps: bool = false


func _ready() -> void:
	# Load settings
	if SettingsManager:
		_show_timer = SettingsManager.get_setting("gameplay", "show_timer", true)
		_show_fps = SettingsManager.get_setting("gameplay", "show_fps", false)
		SettingsManager.gameplay_settings_changed.connect(_on_gameplay_settings_changed)

	# Connect to GameManager signals
	if GameManager:
		GameManager.score_changed.connect(_on_score_changed)
		GameManager.collectible_gathered.connect(_on_collectible_gathered)

	# Connect to LevelSession signals
	if LevelSession:
		LevelSession.timer_updated.connect(_on_timer_updated)
		LevelSession.death_recorded.connect(_on_death_recorded)

	# Initial update
	_update_ui()


func _process(_delta: float) -> void:
	# Update FPS if enabled
	if _show_fps and fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
		fps_label.visible = true
	elif fps_label:
		fps_label.visible = false


## Update all UI elements
func _update_ui() -> void:
	# Update score
	if score_label and GameManager:
		score_label.text = "Score: %d" % GameManager.score

	# Update collectibles
	if collectibles_label and GameManager:
		collectibles_label.text = "Stars: %d/%d" % [
			GameManager.collectibles_gathered,
			GameManager.total_collectibles
		]

	# Update death counter
	if death_counter_label and LevelSession:
		var deaths = LevelSession.get_death_count()
		if deaths > 0:
			death_counter_label.text = "Deaths: %d" % deaths
			death_counter_label.visible = true
		else:
			death_counter_label.visible = false

	# Update timer visibility
	if timer_label:
		timer_label.visible = _show_timer


## Format time for display
func _format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	var millis = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, secs, millis]


## Called when timer updates
func _on_timer_updated(time: float) -> void:
	if timer_label and _show_timer:
		timer_label.text = "Time: %s" % _format_time(time)


## Called when score changes
func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % new_score


## Called when collectible gathered
func _on_collectible_gathered(current: int, total: int) -> void:
	if collectibles_label:
		collectibles_label.text = "Stars: %d/%d" % [current, total]


## Called when death recorded
func _on_death_recorded(death_count: int) -> void:
	if death_counter_label:
		death_counter_label.text = "Deaths: %d" % death_count
		death_counter_label.visible = true


## Called when gameplay settings change
func _on_gameplay_settings_changed() -> void:
	if SettingsManager:
		_show_timer = SettingsManager.get_setting("gameplay", "show_timer", true)
		_show_fps = SettingsManager.get_setting("gameplay", "show_fps", false)
	_update_ui()
