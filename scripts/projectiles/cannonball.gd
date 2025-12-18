extends Area3D

## Cannonball - A simple projectile that moves forward and damages the player.

@export var speed: float = 10.0
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	# Connect the body_entered signal to handle collisions
	body_entered.connect(_on_body_entered)

	# Free the cannonball after its lifetime expires
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Move the cannonball forward
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	# Check if the body is the player
	if body is Player:
		var player = body as Player
		var health_comp = player.get_node_or_null("HealthComponent") as HealthComponent
		if health_comp:
			health_comp.take_damage(1)
	
	# Free the cannonball on impact with anything other than an enemy
	if not body is BaseEnemy:
		queue_free()
