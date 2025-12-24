extends Node3D
class_name TreasureChest

## Treasure Chest - Hidden collectible with interaction
## Part of Phase 3: Collectibles & Economy System
## 1-2 per level, contains coins or costume pieces

# Chest properties
@export var chest_id: String = "chest_1"  ## Unique ID per level
@export var coin_value: int = 10  ## Default: 10 coins
@export var contents_type: String = "coins"  ## "coins" or "costume"
@export var costume_id: String = ""  ## If contents_type is "costume"

# Interaction settings
@export var interaction_prompt: String = "Press E to open"
@export var interaction_radius: float = 2.0

# Internal state
var is_opened: bool = false
var player_nearby: bool = false
var player_ref: Node3D = null

# Node references
@onready var chest_model: Node3D = $ChestModel if has_node("ChestModel") else null
@onready var animation_player: AnimationPlayer = $ChestModel/AnimationPlayer if has_node("ChestModel/AnimationPlayer") else null
@onready var interaction_area: Area3D = $InteractionArea if has_node("InteractionArea") else null
@onready var prompt_label: Label3D = $PromptLabel if has_node("PromptLabel") else null
@onready var particles: GPUParticles3D = $OpenParticles if has_node("OpenParticles") else null

# Signals
signal chest_opened(chest_id: String, contents_type: String)


func _ready() -> void:
	# Set up interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

	# Hide prompt initially
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = interaction_prompt

	# Set chest to closed state initially
	if animation_player:
		if OS.is_debug_build():
			print("TreasureChest: AnimationPlayer found, available animations: %s" % animation_player.get_animation_list())

		if animation_player.has_animation("Chest_Close"):
			animation_player.play("Chest_Close")
			# Seek to the END of Chest_Close animation (fully closed state)
			var anim_length = animation_player.get_animation("Chest_Close").length
			animation_player.seek(anim_length, true)
			animation_player.pause()
			if OS.is_debug_build():
				print("TreasureChest: Set to closed state (Chest_Close at %f)" % anim_length)
		else:
			if OS.is_debug_build():
				print("TreasureChest: Warning - Chest_Close animation not found!")
	else:
		if OS.is_debug_build():
			print("TreasureChest: Warning - AnimationPlayer not found at path: ChestModel/AnimationPlayer")

	# Wait for level data to be set, then check persistence
	await get_tree().process_frame
	_check_persistence()


func _process(_delta: float) -> void:
	# Check for interaction input
	if player_nearby and not is_opened and Input.is_action_just_pressed("interact"):
		open_chest()

	# Make prompt face camera
	if prompt_label and prompt_label.visible:
		var camera = get_viewport().get_camera_3d()
		if camera:
			prompt_label.look_at(camera.global_position, Vector3.UP)
			prompt_label.rotate_object_local(Vector3.UP, PI)


func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_opened:
		player_nearby = true
		player_ref = body
		if prompt_label:
			prompt_label.visible = true


func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null
		if prompt_label:
			prompt_label.visible = false


func open_chest() -> void:
	if is_opened:
		if OS.is_debug_build():
			print("TreasureChest: Chest %s already opened, ignoring" % chest_id)
		return

	is_opened = true

	# Hide prompt
	if prompt_label:
		prompt_label.visible = false

	# Play opening animation
	_play_open_animation()

	# Spawn contents
	_spawn_contents()

	# Mark as opened in persistence
	_mark_as_opened()

	# Play sound
	_play_sound("chest_open")

	# Emit signal
	chest_opened.emit(chest_id, contents_type)

	print("TreasureChest: Chest %s opened! Contents: %s" % [chest_id, contents_type])


func _play_open_animation() -> void:
	# Play the built-in chest opening animation
	if animation_player and animation_player.has_animation("Chest_Open"):
		if OS.is_debug_build():
			print("TreasureChest: Playing Chest_Open animation for chest %s" % chest_id)
		animation_player.play("Chest_Open")
		# Don't pause - let it play through
	else:
		# Fallback: rotate the entire chest if no animation available
		if OS.is_debug_build():
			print("TreasureChest: No animation_player found, using fallback rotation")
		if chest_model:
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_BACK)
			tween.tween_property(chest_model, "rotation_degrees:x", -60, 0.5)

	# Play particles
	if particles:
		particles.emitting = true


func _spawn_contents() -> void:
	match contents_type:
		"coins":
			_spawn_coins()
		"costume":
			_unlock_costume()
		_:
			push_warning("Unknown contents type: %s" % contents_type)


func _spawn_coins() -> void:
	# Spawn coins in an arc around the chest
	var coin_scene = load("res://scenes/collectibles/coin.tscn")
	if not coin_scene:
		push_error("TreasureChest: Failed to load coin scene!")
		return

	var num_coins = coin_value
	if OS.is_debug_build():
		print("TreasureChest: Spawning %d coins from chest %s" % [num_coins, chest_id])

	for i in range(num_coins):
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)

		# Calculate arc position
		var angle = (float(i) / float(num_coins)) * TAU
		var offset = Vector3(
			cos(angle) * 0.5,
			0.5 + (float(i) * 0.1),  # Stagger heights
			sin(angle) * 0.5
		)

		coin.global_position = global_position + offset + Vector3(0, 1, 0)  # Spawn above chest

		# Coins don't have physics bodies, so we can't apply impulse
		# They will fall naturally if they have gravity


func _unlock_costume() -> void:
	# TODO: Implement costume unlock system in Phase 5
	print("TreasureChest: Costume unlocked: %s" % costume_id)
	if player_ref:
		# Could show a popup or notification
		pass


func _play_sound(sound_name: String) -> void:
	# TODO: Implement in Phase 8 (Audio & Polish)
	if OS.is_debug_build():
		print("Playing sound: %s" % sound_name)


func _check_persistence() -> void:
	# Check if this chest was already opened
	if not GameManager.current_level_data:
		if OS.is_debug_build():
			print("TreasureChest: No level data yet, chest %s will be closed" % chest_id)
		return

	var level_id = GameManager.current_level_data.level_id
	is_opened = _is_chest_opened(level_id, chest_id)

	if OS.is_debug_build():
		print("TreasureChest: Level=%s, Chest=%s, Opened=%s" % [level_id, chest_id, is_opened])

	if is_opened:
		# Set chest to opened state immediately
		if animation_player and animation_player.has_animation("Chest_Open"):
			animation_player.play("Chest_Open")
			# Seek to end of animation (fully open)
			var anim_length = animation_player.get_animation("Chest_Open").length
			animation_player.seek(anim_length, true)
			animation_player.pause()
			if OS.is_debug_build():
				print("TreasureChest: Set to opened state (Chest_Open at end)")
		elif chest_model:
			# Fallback
			chest_model.rotation_degrees.x = -60  # Open position

		if interaction_area:
			interaction_area.queue_free()  # Remove interaction
		if prompt_label:
			prompt_label.queue_free()  # Remove prompt


func _mark_as_opened() -> void:
	# Mark chest as opened in GameManager
	if GameManager.current_level_data:
		var level_id = GameManager.current_level_data.level_id
		_save_chest_state(level_id, chest_id, true)


func _is_chest_opened(level_id: String, chest_identifier: String) -> bool:
	return GameManager.is_chest_opened(level_id, chest_identifier)


func _save_chest_state(level_id: String, chest_identifier: String, opened: bool) -> void:
	if opened:
		GameManager.mark_chest_opened(level_id, chest_identifier)
