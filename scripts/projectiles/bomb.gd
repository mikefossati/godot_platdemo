extends Area3D

## Bomb - An explosive projectile thrown by the Goblin King.
## Follows an arc trajectory and explodes on impact or after a timer.

@export_group("Bomb Settings")
@export var launch_speed: float = 10.0
@export var arc_height: float = 5.0
@export var fuse_time: float = 3.0
@export var explosion_radius: float = 2.5
@export var damage: int = 1

var velocity: Vector3 = Vector3.ZERO
var time_alive: float = 0.0
var has_exploded: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Set up collision layers
	collision_layer = 0
	collision_mask = 1  # Hit player and world geometry

	# Auto-explode after fuse time
	var fuse_timer = get_tree().create_timer(fuse_time)
	fuse_timer.timeout.connect(explode)


func _physics_process(delta: float) -> void:
	if has_exploded:
		return

	time_alive += delta

	# Apply gravity
	velocity.y -= gravity * delta

	# Move the bomb
	global_position += velocity * delta

	# Rotate for visual effect (tumbling)
	rotate_y(delta * 5.0)
	rotate_x(delta * 3.0)


func launch_at_target(target_position: Vector3) -> void:
	# Calculate launch velocity to reach target with an arc
	var to_target = target_position - global_position
	var horizontal_distance = Vector3(to_target.x, 0, to_target.z).length()
	var time_to_target = horizontal_distance / launch_speed

	# Horizontal velocity
	var horizontal_direction = Vector3(to_target.x, 0, to_target.z).normalized()
	velocity = horizontal_direction * launch_speed

	# Vertical velocity to create arc
	# v_y = (h + 0.5 * g * t^2) / t
	velocity.y = (arc_height + 0.5 * gravity * time_to_target * time_to_target) / time_to_target


func _on_body_entered(body: Node3D) -> void:
	if has_exploded:
		return

	# Don't explode on the boss who threw it
	if body is Boss:
		return

	# Explode on any other collision
	explode()


func explode() -> void:
	if has_exploded:
		return

	has_exploded = true

	# Damage nearby entities
	create_explosion_damage()

	# Spawn explosion effect (particles + visual)
	spawn_explosion_effect()

	# Camera shake
	shake_camera()

	# Remove the bomb
	queue_free()


func create_explosion_damage() -> void:
	# Create temporary Area3D for explosion
	var explosion_area = Area3D.new()
	get_tree().root.add_child(explosion_area)
	explosion_area.global_position = global_position
	explosion_area.collision_layer = 0
	explosion_area.collision_mask = 1  # Hit player

	# Add collision shape
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = explosion_radius
	shape.shape = sphere
	explosion_area.add_child(shape)

	# Wait one frame for physics to update
	await get_tree().process_frame

	# Damage all overlapping bodies
	var bodies = explosion_area.get_overlapping_bodies()
	for body in bodies:
		if body is Player:
			var player = body as Player
			var health_comp = player.get_node_or_null("HealthComponent") as HealthComponent
			if health_comp:
				health_comp.take_damage(damage)

				# Apply knockback
				var knockback_direction = (player.global_position - global_position).normalized()
				player.velocity = knockback_direction * 8.0 + Vector3.UP * 5.0

	# Clean up explosion area
	explosion_area.queue_free()


func spawn_explosion_effect() -> void:
	# TODO: Add particle effect when available
	# For now, create a simple visual feedback
	var explosion_visual = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = explosion_radius
	sphere_mesh.height = explosion_radius * 2
	explosion_visual.mesh = sphere_mesh

	# Orange/red material for explosion
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.0, 0.7)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.3, 0.0)
	material.emission_energy_multiplier = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	explosion_visual.material_override = material

	get_tree().root.add_child(explosion_visual)
	explosion_visual.global_position = global_position

	# Animate expansion and fade
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(explosion_visual, "scale", Vector3.ONE * 2.0, 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(explosion_visual.queue_free)


func shake_camera() -> void:
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(5.0, 0.3)
