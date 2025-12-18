extends BaseEnemy

## FlyingBat - An aerial enemy that swoops down to attack.

@onready var swoop_detector: RayCast3D = $SwoopDetector

@export_group("Bat Settings")
@export var swoop_speed: float = 8.0
@export var patrol_height: float = 4.0
@export var sine_wave_frequency: float = 2.0
@export var sine_wave_amplitude: float = 0.5
@export var circle_radius: float = 4.0
@export var circle_speed: float = 1.0

var base_patrol_position: Vector3
var time: float = 0.0
var angle: float = 0.0

func _ready() -> void:
	super._ready()

	# Bat-specific properties
	health_component.max_health = 1
	move_speed = 3.0
	coins_dropped = 3
	detection_range = 12.0

	# Bats start in the patrol state
	current_state = AIState.PATROL
	base_patrol_position = global_position

	# Try to play any available flying animation
	_setup_animations()


func _physics_process(delta: float) -> void:
	# Override the base physics process to remove gravity
	time += delta

	# Run state machine
	match current_state:
		AIState.PATROL:
			_state_patrol(delta)
		AIState.SWOOP:
			_state_swoop(delta)
		AIState.RETURN:
			_state_return(delta)

	move_and_slide()


func _state_patrol(delta: float) -> void:
	# Move between patrol points
	if patrol_points.size() > 0:
		var target_point = patrol_points[current_patrol_index].global_position
		var direction = (target_point - global_position).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		look_at(Vector3(target_point.x, global_position.y, target_point.z), Vector3.UP)

		if global_position.distance_to(target_point) < 1.0:
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		# If no patrol points, fly in a circular pattern around the base position
		angle += circle_speed * delta

		# Calculate circular movement
		var offset_x = cos(angle) * circle_radius
		var offset_z = sin(angle) * circle_radius
		var target_pos = base_patrol_position + Vector3(offset_x, 0, offset_z)

		# Move towards the target position on the circle
		var direction = (target_pos - global_position).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		# Face the direction of movement
		if velocity.length() > 0.1:
			var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
			look_at(look_target, Vector3.UP)

	# Add sine wave vertical movement for natural bobbing
	velocity.y = sin(time * sine_wave_frequency) * sine_wave_amplitude

	# Check if player is below
	if not swoop_detector:
		push_error("Bat scene is missing a RayCast3D node named SwoopDetector!")
		return

	if swoop_detector.is_colliding() and swoop_detector.get_collider() is Player:
		player_reference = swoop_detector.get_collider() as Player
		current_state = AIState.SWOOP


func _state_swoop(delta: float) -> void:
	if not player_reference:
		current_state = AIState.RETURN
		return

	# Dive towards the player's position
	var direction = (player_reference.global_position - global_position).normalized()
	velocity = direction * swoop_speed

	# If we've reached or passed the player's y-level, return
	if global_position.y <= player_reference.global_position.y + 0.5:
		current_state = AIState.RETURN


func _state_return(delta: float) -> void:
	# Fly back up to the original patrol height
	var target_pos = Vector3(global_position.x, base_patrol_position.y, global_position.z)
	var direction = (target_pos - global_position).normalized()
	velocity = direction * move_speed

	# If we're close to the patrol height, switch back to patrol
	if abs(global_position.y - base_patrol_position.y) < 0.5:
		player_reference = null
		current_state = AIState.PATROL


func _setup_animations() -> void:
	# Try to find and play animations from the Bee model
	# First check if base AnimationPlayer has animations
	if animation_player and animation_player.get_animation_list().size() > 0:
		var anim_name = animation_player.get_animation_list()[0]
		animation_player.play(anim_name, -1, 1.0, false)
		# Set the animation to loop
		var anim = animation_player.get_animation(anim_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		print("Bat: Playing looping animation from base AnimationPlayer: ", anim_name)
		return

	# Check if the Bee model itself has an AnimationPlayer
	var bee_node = get_node_or_null("CharacterModel/Bee")
	if bee_node:
		# Look for AnimationPlayer in Bee's children
		for child in bee_node.get_children():
			if child is AnimationPlayer:
				var anim_list = child.get_animation_list()
				if anim_list.size() > 0:
					var anim_name = anim_list[0]
					child.play(anim_name, -1, 1.0, false)
					# Set the animation to loop
					var anim = child.get_animation(anim_name)
					if anim:
						anim.loop_mode = Animation.LOOP_LINEAR
					print("Bat: Playing looping animation from Bee's AnimationPlayer: ", anim_name)
					return

		# Check Armature for AnimationPlayer
		var armature = bee_node.get_node_or_null("Armature")
		if armature:
			for child in armature.get_children():
				if child is AnimationPlayer:
					var anim_list = child.get_animation_list()
					if anim_list.size() > 0:
						var anim_name = anim_list[0]
						child.play(anim_name, -1, 1.0, false)
						# Set the animation to loop
						var anim = child.get_animation(anim_name)
						if anim:
							anim.loop_mode = Animation.LOOP_LINEAR
						print("Bat: Playing looping animation from Armature's AnimationPlayer: ", anim_name)
						return

	print("Bat: No animations found in Bee model")
