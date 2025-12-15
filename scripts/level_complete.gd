extends Control

## Level Complete Screen - Displayed when the player collects all stars
## Shows final score and celebration message, with options to progress or replay

# UI element references
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var level_name_label: Label = $CenterContainer/VBoxContainer/LevelNameLabel
@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var collectibles_label: Label = $CenterContainer/VBoxContainer/CollectiblesLabel
@onready var next_level_button: Button = $CenterContainer/VBoxContainer/NextLevelButton
@onready var replay_button: Button = $CenterContainer/VBoxContainer/ReplayButton
@onready var level_select_button: Button = $CenterContainer/VBoxContainer/LevelSelectButton


func _ready() -> void:
	# Display level name
	if GameManager.current_level_data != null:
		level_name_label.text = GameManager.current_level_data.level_name + " Complete!"
	else:
		level_name_label.text = "Level Complete!"

	# Display the final game statistics
	score_label.text = "Final Score: %d" % GameManager.score
	collectibles_label.text = "Stars Collected: %d/%d" % [
		GameManager.collectibles_gathered,
		GameManager.total_collectibles
	]

	# Check if there's a next level
	var has_next_level = (GameManager.current_level_index + 1) < GameManager.level_registry.size()

	if has_next_level:
		next_level_button.visible = true
		next_level_button.pressed.connect(_on_next_level_button_pressed)
		next_level_button.grab_focus()
	else:
		next_level_button.visible = false
		level_select_button.grab_focus()

	# Connect button signals
	replay_button.pressed.connect(_on_replay_button_pressed)
	level_select_button.pressed.connect(_on_level_select_button_pressed)


## Called when the Next Level button is pressed
func _on_next_level_button_pressed() -> void:
	GameManager.load_next_level()


## Called when the Replay button is pressed
func _on_replay_button_pressed() -> void:
	# Restart the current level
	GameManager.load_level(GameManager.current_level_index)


## Called when the Level Select button is pressed
func _on_level_select_button_pressed() -> void:
	# Return to level select screen
	GameManager.return_to_level_select()
