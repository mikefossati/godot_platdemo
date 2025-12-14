extends Area3D

## Collectible Item - Represents items the player can collect
## Uses Area3D for overlap detection (doesn't block movement, just detects collision)

# Visual feedback parameters
@export var rotation_speed: float = 2.0  ## Speed of the spinning animation
@export var bob_height: float = 0.3  ## How high the item bobs up and down
@export var bob_speed: float = 2.0  ## Speed of the bobbing animation

# Starting position for bobbing animation
var start_y: float = 0.0
var time_passed: float = 0.0


func _ready() -> void:
	# Store the initial Y position for the bobbing animation
	start_y = position.y

	# Connect the body_entered signal to detect when the player touches this collectible
	# Area3D emits this signal when another physics body enters its collision area
	body_entered.connect(_on_body_entered)

	# Increment the total collectibles count in the game manager
	GameManager.total_collectibles += 1


func _process(delta: float) -> void:
	## Visual effects - rotate and bob the collectible for visual appeal
	## This makes the item more noticeable and attractive to collect

	# Rotate around the Y axis (vertical rotation)
	rotate_y(rotation_speed * delta)

	# Create a bobbing motion using a sine wave
	# sin() creates smooth up and down motion
	time_passed += delta * bob_speed
	position.y = start_y + sin(time_passed) * bob_height


## Called when any physics body enters the Area3D
func _on_body_entered(body: Node3D) -> void:
	# Check if the body that entered is the player
	# We check if it has the "collect_item" method to ensure it's the player
	if body.has_method("collect_item"):
		# Call the player's collect_item method
		body.collect_item()

		# Remove this collectible from the scene
		# queue_free() safely deletes the node at the end of the current frame
		queue_free()
