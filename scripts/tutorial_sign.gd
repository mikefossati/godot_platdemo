extends Node3D
class_name TutorialSign

## Tutorial Sign - Display helpful messages to the player
## Part of Phase 4: World 1 Production
## Shows tutorial text when player approaches

# Sign properties
@export_multiline var message_text: String = "Welcome to the game!"
@export var auto_show: bool = true  ## Show automatically when player enters area
@export var show_duration: float = 5.0  ## How long to display message (0 = infinite)
@export var interaction_radius: float = 3.0  ## Detection range

# Visual parameters
@export var label_offset: Vector3 = Vector3(0, 2, 0)
@export var font_size: int = 32

# State
var player_in_range: bool = false
var message_shown: bool = false

# Node references
@onready var detection_area: Area3D = $DetectionArea if has_node("DetectionArea") else null
@onready var sign_label: Label3D = $SignLabel if has_node("SignLabel") else null
@onready var prompt_label: Label3D = $PromptLabel if has_node("PromptLabel") else null
@onready var sign_post: MeshInstance3D = $SignPost if has_node("SignPost") else null


func _ready() -> void:
	# Connect signals
	if detection_area:
		detection_area.body_entered.connect(_on_player_entered)
		detection_area.body_exited.connect(_on_player_exited)

		# Set detection radius
		var shape = detection_area.get_child(0) as CollisionShape3D
		if shape and shape.shape is SphereShape3D:
			shape.shape.radius = interaction_radius

	# Configure sign label
	if sign_label:
		sign_label.text = message_text
		sign_label.visible = false
		sign_label.position = label_offset

		# Set Label3D properties directly (no label_settings in Label3D)
		sign_label.font_size = font_size
		sign_label.outline_size = 8
		sign_label.outline_modulate = Color.BLACK

	# Configure prompt label
	if prompt_label:
		prompt_label.text = "Press E to read" if not auto_show else ""
		prompt_label.visible = false


func _process(_delta: float) -> void:
	# Handle interaction input
	if player_in_range and not message_shown and not auto_show:
		if Input.is_action_just_pressed("interact"):
			show_message()

	# Make labels face camera
	var camera = get_viewport().get_camera_3d()
	if camera:
		if sign_label and sign_label.visible:
			sign_label.look_at(camera.global_position, Vector3.UP)
			sign_label.rotate_object_local(Vector3.UP, PI)

		if prompt_label and prompt_label.visible:
			prompt_label.look_at(camera.global_position, Vector3.UP)
			prompt_label.rotate_object_local(Vector3.UP, PI)


func _on_player_entered(body: Node3D) -> void:
	if OS.is_debug_build():
		print("TutorialSign: Body entered - %s" % body.name)

	if body.is_in_group("player"):
		player_in_range = true

		if auto_show and not message_shown:
			show_message()
		elif not message_shown:
			# Show interaction prompt
			if prompt_label:
				prompt_label.visible = true


func _on_player_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

		# Hide prompt
		if prompt_label:
			prompt_label.visible = false


func show_message() -> void:
	if message_shown:
		return

	message_shown = true

	# Show the message
	if sign_label:
		sign_label.visible = true

	# Hide prompt
	if prompt_label:
		prompt_label.visible = false

	# Play sound
	_play_sound("sign_read")

	if OS.is_debug_build():
		print("TutorialSign: Showing message: '%s'" % message_text)

	# Auto-hide after duration (if set)
	if show_duration > 0:
		await get_tree().create_timer(show_duration).timeout
		if sign_label:
			sign_label.visible = false


func _play_sound(sound_name: String) -> void:
	# TODO: Implement in Phase 8 (Audio & Polish)
	if OS.is_debug_build():
		print("Playing sound: %s" % sound_name)


## Reset sign (for reuse)
func reset() -> void:
	message_shown = false
	if sign_label:
		sign_label.visible = false
	if prompt_label:
		prompt_label.visible = false
