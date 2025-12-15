extends Control

## Level Complete Screen - Displayed when the player collects all stars
## Shows final score and celebration message, with options to replay or return to menu

# UI element references
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var collectibles_label: Label = $CenterContainer/VBoxContainer/CollectiblesLabel
@onready var message_label: Label = $CenterContainer/VBoxContainer/MessageLabel
@onready var replay_button: Button = $CenterContainer/VBoxContainer/ReplayButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton


func _ready() -> void:
	# Display the final game statistics
	score_label.text = "Final Score: %d" % GameManager.score
	collectibles_label.text = "Stars Collected: %d/%d" % [
		GameManager.collectibles_gathered,
		GameManager.total_collectibles
	]

	# Connect button signals
	replay_button.pressed.connect(_on_replay_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	# Focus the replay button for keyboard navigation
	replay_button.grab_focus()


## Called when the Replay button is pressed
func _on_replay_button_pressed() -> void:
	# Restart the level - this will reset the score and reload the level
	GameManager.start_game()


## Called when the Menu button is pressed
func _on_menu_button_pressed() -> void:
	# Return to the main menu
	GameManager.return_to_menu()
