extends CanvasLayer

## Game UI - Displays score and collectible count during gameplay
## CanvasLayer is used for 2D UI elements that display on top of the 3D game

# UI element references - these will be set in _ready() by finding child nodes
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var collectibles_label: Label = $MarginContainer/VBoxContainer/CollectiblesLabel


func _ready() -> void:
	# Connect to GameManager signals to update UI when game state changes
	# This is an example of the Observer pattern - the UI observes the game state
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.collectible_gathered.connect(_on_collectible_gathered)

	# Initialize the UI with current values
	_update_score(GameManager.score)
	_update_collectibles(GameManager.collectibles_gathered, GameManager.total_collectibles)


## Called when the score changes in GameManager
func _on_score_changed(new_score: int) -> void:
	_update_score(new_score)


## Called when a collectible is gathered
func _on_collectible_gathered(current: int, total: int) -> void:
	_update_collectibles(current, total)


## Updates the score display
func _update_score(score: int) -> void:
	score_label.text = "Score: %d" % score


## Updates the collectibles counter display
func _update_collectibles(current: int, total: int) -> void:
	collectibles_label.text = "Collectibles: %d/%d" % [current, total]
