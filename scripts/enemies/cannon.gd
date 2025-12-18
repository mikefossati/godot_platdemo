extends Node3D

## Cannon - A stationary turret that fires projectiles at the player.

const CANNONBALL_SCENE = preload("res://scenes/projectiles/cannonball.tscn")

@export_group("Cannon Settings")
@export var detection_range: float = 10.0
@export var fire_rate: float = 2.0
@export var rotation_speed: float = 2.0

@onready var detection_area: Area3D = $DetectionArea
@onready var cannon_barrel: Node3D = $CannonBarrel

var fire_timer: float = 0.0
var player_reference: Player = null

func _ready() -> void:
	# Set detection range
	var detection_shape = detection_area.get_child(0) as CollisionShape3D
	if detection_shape and detection_shape.shape is SphereShape3D:
		detection_shape.shape.radius = detection_range
	
	# Connect signals
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)

func _process(delta: float) -> void:
	fire_timer -= delta

	if player_reference:
		# Smoothly rotate towards the player
		var target_direction = (player_reference.global_position - global_position).normalized()
		var current_forward = -global_transform.basis.z
		var new_forward = current_forward.slerp(target_direction, delta * rotation_speed)
		look_at(global_position + new_forward, Vector3.UP)

		# Fire if the timer is ready
		if fire_timer <= 0:
			fire_cannonball()
			fire_timer = fire_rate

func fire_cannonball() -> void:
	if not CANNONBALL_SCENE:
		push_error("Cannonball scene not loaded!")
		return

	var ball = CANNONBALL_SCENE.instantiate() as Area3D
	get_tree().root.add_child(ball)
	ball.global_position = cannon_barrel.global_position
	ball.direction = -cannon_barrel.global_transform.basis.z

func _on_player_entered(body: Node3D) -> void:
	if body is Player:
		player_reference = body
		fire_timer = fire_rate # Start the timer when player enters

func _on_player_exited(body: Node3D) -> void:
	if body is Player:
		player_reference = null
