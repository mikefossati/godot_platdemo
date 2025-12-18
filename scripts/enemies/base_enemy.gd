class_name BaseEnemy
extends CharacterBody3D

## BaseEnemy - Foundation for all enemies in the game
## Includes health, basic AI state, and player interaction.

# ========== COMPONENTS ==========
@onready var health_component: HealthComponent = SceneValidator.validate_node_path(self, "HealthComponent")
@onready var detection_area: Area3D = SceneValidator.validate_node_path(self, "DetectionArea")
@onready var hurtbox: Area3D = SceneValidator.validate_node_path(self, "Hurtbox")
@onready var animation_player: AnimationPlayer = SceneValidator.validate_node_path(self, "CharacterModel/AnimationPlayer")

# ========== EXPORTED PARAMETERS ==========
@export_group("AI Settings")
@export var move_speed: float = 2.0
@export var patrol_points: Array[Node3D] = []
@export var detection_range: float = 8.0

@export_group("Combat")
@export var damage_to_player: int = 1
@export var coins_dropped: int = 3

# ========== AI STATE ==========
var current_patrol_index: int = 0
var player_reference: Player = null

enum AIState { IDLE, PATROL, CHASE, ATTACK, SWOOP, RETURN }
var current_state: AIState = AIState.PATROL

# ========== INITIALIZATION ==========
func _ready() -> void:
	# Connect signals
	if health_component:
		health_component.died.connect(_on_died)
	else:
		push_error("Enemy scene is missing a HealthComponent node: %s" % get_parent().name if get_parent() else self.name)
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_exited)
	hurtbox.body_entered.connect(_on_hurtbox_entered)

	# Set detection range
	var detection_shape = detection_area.get_child(0) as CollisionShape3D
	if detection_shape and detection_shape.shape is SphereShape3D:
		detection_shape.shape.radius = detection_range


# ========== MAIN PHYSICS LOOP ==========
func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Run state machine
	match current_state:
		AIState.IDLE:
			_state_idle(delta)
		AIState.PATROL:
			_state_patrol(delta)
		AIState.CHASE:
			_state_chase(delta)
		AIState.ATTACK:
			_state_attack(delta)

	move_and_slide()

	# Handle enemy separation to prevent merging
	_apply_enemy_separation()


# ========== STATE MACHINE LOGIC (VIRTUAL FUNCTIONS) ==========
func _state_idle(_delta: float) -> void:
	# Default idle behavior: do nothing
	velocity.x = 0
	velocity.z = 0
	if animation_player and animation_player.has_animation("Idle"):
		animation_player.play("Idle")

func _state_patrol(delta: float) -> void:
	# Default patrol behavior: move between patrol points
	if patrol_points.size() < 2:
		current_state = AIState.IDLE
		return

	var target_point = patrol_points[current_patrol_index].global_position
	var direction = (target_point - global_position).normalized()
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	look_at(Vector3(target_point.x, global_position.y, target_point.z), Vector3.UP)
	if animation_player.has_animation("Walk"):
		animation_player.play("Walk")

	if global_position.distance_to(target_point) < 0.5:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func _state_chase(delta: float) -> void:
	# Default chase behavior: move towards the player
	if player_reference:
		var player_pos = player_reference.global_position
		var direction = (player_pos - global_position).normalized()
		
		velocity.x = direction.x * move_speed * 1.5 # Chase faster
		velocity.z = direction.z * move_speed * 1.5
		
		look_at(Vector3(player_pos.x, global_position.y, player_pos.z), Vector3.UP)
		if animation_player.has_animation("Run"):
			animation_player.play("Run")
	else:
		# Player lost, return to patrol
		current_state = AIState.PATROL

func _state_attack(_delta: float) -> void:
	# Default attack behavior: stop and play attack animation
	velocity.x = 0
	velocity.z = 0
	if animation_player.has_animation("Attack"):
		animation_player.play("Attack")


# ========== SIGNAL HANDLERS ==========
func _on_player_detected(body: Node3D) -> void:
	if body is Player:
		player_reference = body
		current_state = AIState.CHASE

func _on_player_exited(body: Node3D) -> void:
	if body is Player:
		player_reference = null
		current_state = AIState.PATROL

func _on_hurtbox_entered(body: Node3D) -> void:
	if body is Player:
		var player = body as Player
		# Check if player is jumping on top of the enemy (jumping DOWN onto the enemy)
		# Player needs to be above the enemy's center and falling downward
		var player_bottom = player.global_position.y
		var enemy_center = global_position.y

		# For jump attacks, player must be above enemy center and falling
		if player_bottom > enemy_center and player.velocity.y < 0:
			# Player successfully jumped on enemy
			take_jump_damage(player)
		else:
			# Player touched enemy from side or below
			damage_player(player)

func _on_died() -> void:
	# Spawn coins, play death animation, and disappear
	if GameManager:
		GameManager.add_coins(coins_dropped)

	# Disable physics and collisions immediately
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	# Disconnect signals to prevent errors during death
	if hurtbox and hurtbox.body_entered.is_connected(_on_hurtbox_entered):
		hurtbox.body_entered.disconnect(_on_hurtbox_entered)
	if detection_area and detection_area.body_entered.is_connected(_on_player_detected):
		detection_area.body_entered.disconnect(_on_player_detected)

	# Shrink the model (not the enemy itself to avoid basis issues)
	var tween = create_tween()
	tween.set_parallel(true)

	# Scale down the CharacterModel instead of the CharacterBody3D
	if has_node("CharacterModel"):
		var model = get_node("CharacterModel")
		tween.tween_property(model, "scale", Vector3.ZERO, 0.5)
		tween.tween_property(model, "position", model.position + Vector3(0, -2, 0), 0.5)

	tween.chain().tween_callback(queue_free)


# ========== ENEMY SEPARATION ==========
func _apply_enemy_separation() -> void:
	# Push away from nearby enemies to prevent merging/stacking
	const SEPARATION_DISTANCE: float = 1.5
	const SEPARATION_STRENGTH: float = 2.0

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		# Check if we collided with another enemy
		if collider is BaseEnemy:
			var other_enemy = collider as BaseEnemy
			var direction_away = (global_position - other_enemy.global_position).normalized()

			# Only apply horizontal separation (don't affect vertical position)
			direction_away.y = 0
			if direction_away.length() > 0.01:
				direction_away = direction_away.normalized()

				# Push away from the other enemy
				var separation_force = direction_away * SEPARATION_STRENGTH
				velocity.x += separation_force.x
				velocity.z += separation_force.z


# ========== COMBAT LOGIC ==========
func take_jump_damage(player: Player) -> void:
	# This is called when the player successfully jumps on the enemy
	if GameManager:
		GameManager.record_jump_kill()
	
	health_component.take_damage(1)
	player.bounce_on_enemy()

func damage_player(player: Player) -> void:
	# This is called when the enemy touches the player
	var health_comp = player.get_node("HealthComponent") as HealthComponent
	if health_comp:
		health_comp.take_damage(damage_to_player)
