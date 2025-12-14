extends Control

## Main Menu - The first screen players see when starting the game
## Provides options to start the game or quit

# Button references
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	# Connect button signals to handler functions
	# "pressed" signal is emitted when a button is clicked
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	# Make sure the first button is focused for keyboard navigation
	start_button.grab_focus()


## Called when the Start button is pressed
func _on_start_button_pressed() -> void:
	# Use GameManager to start the game, which handles scene transition and state reset
	GameManager.start_game()


## Called when the Quit button is pressed
func _on_quit_button_pressed() -> void:
	# Quit the application
	# Note: This won't work in the web editor, only in exported builds
	get_tree().quit()
