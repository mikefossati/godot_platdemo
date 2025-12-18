extends Area3D

## Cannonball - A simple projectile that moves forward and damages the player.

@export var speed: float = 10.0
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD
var lifetime_timer: float = 0.0

func _ready() -> void:
	# Connect the body_entered signal to handle collisions
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Reset lifetime timer when spawned
	lifetime_timer = lifetime

func _physics_process(delta: float) -> void:
	# Move the cannonball forward
	global_position += direction * speed * delta

	# Track lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		_despawn()

func _on_body_entered(body: Node3D) -> void:
	# Check if the body is the player
	if body is Player:
		var player = body as Player
		var health_comp = player.get_node_or_null("HealthComponent") as HealthComponent
		if health_comp:
			health_comp.take_damage(1)

	# Despawn the cannonball on impact with anything other than an enemy
	# Use call_deferred to avoid modifying physics during physics callback
	if not body is BaseEnemy:
		call_deferred("_despawn")

## Despawn cannonball (works with both pooled and non-pooled objects)
func _despawn() -> void:
	if is_in_group("pooled_objects"):
		# Pooled object - always return to pool, never free
		ProjectilePool.return_object(self)
	else:
		# Non-pooled object - free it
		queue_free()

## Reset state when returned to pool
func reset_pool_state() -> void:
	direction = Vector3.FORWARD
	lifetime_timer = lifetime
	global_position = Vector3.ZERO
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

## Called when spawned from pool (called by pool after get_object)
func _on_spawn() -> void:
	lifetime_timer = lifetime
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
