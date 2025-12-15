extends Control

## Game Over Screen - Displayed when the player dies
## Shows final score and collectibles, with options to retry or return to menu

# UI element references
@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var collectibles_label: Label = $CenterContainer/VBoxContainer/CollectiblesLabel
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton


func _ready() -> void:
	# Display the final game statistics
	score_label.text = "Final Score: %d" % GameManager.score
	collectibles_label.text = "Collectibles: %d/%d" % [
		GameManager.collectibles_gathered,
		GameManager.total_collectibles
	]

	# Connect button signals
	retry_button.pressed.connect(_on_retry_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	# Focus the retry button for keyboard navigation
	retry_button.grab_focus()


## Called when the Retry button is pressed
func _on_retry_button_pressed() -> void:
	# Restart the current level from the beginning
	GameManager.load_level(GameManager.current_level_index)


## Called when the Menu button is pressed
func _on_menu_button_pressed() -> void:
	# Return to the main menu
	GameManager.return_to_menu()
