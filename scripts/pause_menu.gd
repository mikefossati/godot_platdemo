extends Control

## PauseMenu - In-game pause overlay with options
## Critical for commercial game - respects player time and provides control
## Handles pause state, input, and navigation

# UI References
@onready var panel_container: PanelContainer = $PanelContainer
@onready var resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PanelContainer/VBoxContainer/RestartButton
@onready var settings_button: Button = $PanelContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $PanelContainer/VBoxContainer/QuitButton

# State
var _is_paused: bool = false


func _ready() -> void:
	# Initially hidden
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused

	# Connect button signals
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	# Toggle pause with ESC or Start button
	if event.is_action_pressed("pause"):  # You'll need to add this action
		toggle_pause()
		get_viewport().set_input_as_handled()


## Toggle pause state
func toggle_pause() -> void:
	if _is_paused:
		resume_game()
	else:
		pause_game()


## Pause the game
func pause_game() -> void:
	_is_paused = true
	get_tree().paused = true
	show()

	# Pause level session timer
	if LevelSession:
		LevelSession.pause_session()

	# Focus resume button for keyboard/controller navigation
	if resume_button:
		resume_button.grab_focus()

	print("Game paused")


## Resume the game
func resume_game() -> void:
	_is_paused = false
	get_tree().paused = false
	hide()

	# Resume level session timer
	if LevelSession:
		LevelSession.resume_session()

	print("Game resumed")


## Resume button pressed
func _on_resume_pressed() -> void:
	resume_game()


## Restart button pressed
func _on_restart_pressed() -> void:
	# Resume first (unpause the tree)
	get_tree().paused = false
	_is_paused = false

	# Restart current level
	if GameManager:
		GameManager.load_level(GameManager.current_level_index)


## Settings button pressed
func _on_settings_pressed() -> void:
	# Open settings menu (overlay on top of pause menu)
	# For now, just show a message
	print("Settings menu - TODO")
	# In full implementation:
	# var settings_menu = preload("res://scenes/ui/settings_menu.tscn").instantiate()
	# add_child(settings_menu)


## Quit button pressed
func _on_quit_pressed() -> void:
	# Show confirmation dialog for commercial game
	# For now, direct quit to menu
	get_tree().paused = false
	_is_paused = false

	if GameManager:
		GameManager.return_to_level_select()
