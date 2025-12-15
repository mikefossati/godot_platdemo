extends Control

## Level Select Screen - Displays all available levels and allows player to choose

@onready var level_grid: GridContainer = $MarginContainer/VBoxContainer/LevelGrid
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	# Connect back button
	back_button.pressed.connect(_on_back_button_pressed)

	# Populate level buttons
	_populate_level_buttons()


## Create buttons for each level in the registry
func _populate_level_buttons() -> void:
	# Clear existing buttons
	for child in level_grid.get_children():
		child.queue_free()

	# Create button for each level
	for i in range(GameManager.level_registry.size()):
		var level_data: LevelData = GameManager.level_registry[i]
		var button = _create_level_button(i, level_data)
		level_grid.add_child(button)


## Create a level button with appropriate styling
func _create_level_button(index: int, level_data: LevelData) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(250, 150)

	# Check if level is unlocked
	var is_unlocked = GameManager.is_level_unlocked(level_data.level_id)

	# Check if level is completed
	var is_completed = false
	var best_score = 0
	if GameManager.level_stats.has(level_data.level_id):
		is_completed = GameManager.level_stats[level_data.level_id].get("completed", false)
		best_score = GameManager.level_stats[level_data.level_id].get("best_score", 0)

	# Build button text
	var button_text = ""
	button_text += level_data.level_name + "\n"
	button_text += "★ ".repeat(level_data.difficulty) + "\n"

	if not is_unlocked:
		button_text += "🔒 LOCKED"
		button.disabled = true
		button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif is_completed:
		button_text += "✓ Best: %d" % best_score
		button.modulate = Color(0.7, 1.0, 0.7, 1.0)
	else:
		button_text += "Start Level"

	button.text = button_text
	button.pressed.connect(_on_level_button_pressed.bind(index))

	return button


## Called when a level button is pressed
func _on_level_button_pressed(level_index: int) -> void:
	GameManager.load_level(level_index)


## Called when back button is pressed
func _on_back_button_pressed() -> void:
	GameManager.return_to_menu()
