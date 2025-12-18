extends CanvasLayer

## GameHUD - In-game heads-up display
## Shows timer, collectibles, score, and FPS based on settings

# UI References
@onready var timer_label: Label = $TopLeft/TimerLabel
@onready var collectibles_label: Label = $TopLeft/CollectiblesLabel
@onready var score_label: Label = $TopLeft/ScoreLabel
@onready var fps_label: Label = $TopRight/FPSLabel
@onready var combo_label: Label = $TopRight/ComboLabel
@onready var hearts_container: HBoxContainer = $TopLeft/HeartsContainer

# Heart textures
const HEART_FULL = preload("res://assets/ui/heart_full.svg")
const HEART_EMPTY = preload("res://assets/ui/heart_empty.svg")

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
		GameManager.combo_updated.connect(_on_combo_updated)

	# Connect to LevelSession signals
	if LevelSession:
		LevelSession.timer_updated.connect(_on_timer_updated)

	# Find player and connect to health signals
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		var health_component = player.get_node("HealthComponent")
		health_component.health_changed.connect(_on_health_changed)
		# HealthComponent will emit health_changed in its _ready(), no manual call needed

	# Initial update
	_update_ui()
	# Hide combo label initially
	if combo_label:
		combo_label.visible = false


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


## Called when player's health changes
func _on_health_changed(current: int, max_val: int) -> void:
	if not hearts_container:
		return

	# Clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()

	# Add new heart icons
	for i in range(max_val):
		var heart_icon = TextureRect.new()
		heart_icon.texture = HEART_FULL if i < current else HEART_EMPTY
		heart_icon.custom_minimum_size = Vector2(32, 32)
		heart_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(heart_icon)


## Called when the jump combo is updated
func _on_combo_updated(combo_count: int, multiplier: float) -> void:
	if not combo_label:
		return

	if combo_count > 1:
		combo_label.text = "Combo: %dx\n(%.1fx Coins)" % [combo_count, multiplier]
		combo_label.visible = true
	else:
		combo_label.visible = false


## Called when gameplay settings change
func _on_gameplay_settings_changed() -> void:
	if SettingsManager:
		_show_timer = SettingsManager.get_setting("gameplay", "show_timer", true)
		_show_fps = SettingsManager.get_setting("gameplay", "show_fps", false)
	_update_ui()
