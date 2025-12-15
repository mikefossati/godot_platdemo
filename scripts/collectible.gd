extends Area3D

## Collectible Item - Represents items the player can collect
## Uses Area3D for overlap detection (doesn't block movement, just detects collision)

# Visual feedback parameters
@export var rotation_speed: float = GameConstants.COLLECTIBLE_ROTATION_SPEED  ## Speed of the spinning animation
@export var bob_height: float = GameConstants.COLLECTIBLE_BOB_HEIGHT  ## How high the item bobs up and down
@export var bob_speed: float = GameConstants.COLLECTIBLE_BOB_SPEED  ## Speed of the bobbing animation

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
		# Disable collision detection to prevent collecting the same item multiple times
		set_deferred("monitoring", false)

		# Play the pickup animation (Punch) on the player character
		if body.has_method("play_collect_animation"):
			body.play_collect_animation()

		# Call the player's collect_item method
		body.collect_item()

		# Wait for the punch animation to complete before removing the star
		await get_tree().create_timer(GameConstants.COLLECTIBLE_PICKUP_DELAY).timeout

		# Check if this collectible is managed by a pool
		var pool_manager = get_tree().get_first_node_in_group("collectible_pool")
		if pool_manager and pool_manager.has_method("release_collectible"):
			# Return to pool instead of destroying
			pool_manager.release_collectible(self)
		else:
			# No pool manager, use traditional destruction
			queue_free()


## Reset this collectible for reuse from object pool
func reset_pooled_object() -> void:
	# Reset animation state
	time_passed = 0.0

	# Re-enable collision detection
	monitoring = true
	monitorable = true

	# Reset visual state (will be set by bobbing animation)
	# Position will be set by the spawner
