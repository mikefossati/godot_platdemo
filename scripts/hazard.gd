extends Area3D

## Hazard - Base class for dangerous obstacles that kill the player
## Designed for commercial game with clear visual feedback and fair gameplay

## Hazard type for categorization
enum HazardType {
	SPIKES,          ## Static spikes that kill on contact
	FALLING_BLOCK,   ## Platform that falls when player steps on it
	FIRE,            ## Animated fire hazard
	LASER,           ## Toggleable laser beam
	CRUSHER          ## Moving crushing hazard
}

@export_group("Hazard Settings")
@export var hazard_type: HazardType = HazardType.SPIKES
@export var instant_death: bool = true  ## If false, deals damage instead
@export var damage_amount: int = 1  ## Damage if not instant death
@export var respawn_delay: float = 0.0  ## Delay before hazard reappears after triggering

@export_group("Visual Feedback")
@export var warning_enabled: bool = true  ## Show visual warning before activating
@export var warning_duration: float = 1.0  ## How long warning shows (seconds)
@export var danger_color: Color = Color(1, 0, 0, 0.8)  ## Color for danger state
@export var warning_color: Color = Color(1, 1, 0, 0.6)  ## Color for warning state

@export_group("Audio")
@export var trigger_sound: AudioStream  ## Sound when hazard is triggered
@export var warning_sound: AudioStream  ## Sound for warning
@export var ambient_sound: AudioStream  ## Looping ambient sound

# Internal state
var _is_active: bool = true
var _is_warning: bool = false
var _warning_timer: float = 0.0
var _respawn_timer: float = 0.0
var _original_position: Vector3
var _audio_player: AudioStreamPlayer3D


func _ready() -> void:
	_original_position = global_position

	# Set up collision detection
	body_entered.connect(_on_body_entered)

	# Add to hazards group
	add_to_group("hazards")

	# Set up audio player
	_audio_player = AudioStreamPlayer3D.new()
	add_child(_audio_player)

	# Play ambient sound if set
	if ambient_sound != null:
		_audio_player.stream = ambient_sound
		_audio_player.play()

	# Type-specific initialization
	_initialize_hazard_type()


func _process(delta: float) -> void:
	# Handle warning state
	if _is_warning:
		_warning_timer -= delta
		if _warning_timer <= 0:
			_is_warning = false
			_activate_hazard()

	# Handle respawn delay
	if not _is_active and respawn_delay > 0:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_reactivate_hazard()

	# Update visual state
	_update_visual_feedback()


## Initialize hazard based on type
func _initialize_hazard_type() -> void:
	match hazard_type:
		HazardType.SPIKES:
			# Spikes are always active, no warning needed
			warning_enabled = false

		HazardType.FALLING_BLOCK:
			# Falling blocks need warning
			warning_enabled = true

		HazardType.FIRE:
			# Animated fire (implementation depends on visual assets)
			pass

		HazardType.LASER:
			# Toggleable laser
			pass

		HazardType.CRUSHER:
			# Moving crusher
			pass


## Called when player or other body enters hazard
func _on_body_entered(body: Node3D) -> void:
	if not _is_active:
		return

	# Check if it's the player
	if body.has_method("die"):
		if warning_enabled and not _is_warning:
			# Start warning phase
			_start_warning()
		else:
			# Trigger hazard immediately
			_trigger_hazard(body)


## Start warning phase
func _start_warning() -> void:
	_is_warning = true
	_warning_timer = warning_duration

	# Play warning sound
	if warning_sound != null:
		_audio_player.stream = warning_sound
		_audio_player.play()


## Activate hazard after warning
func _activate_hazard() -> void:
	# Type-specific activation
	match hazard_type:
		HazardType.FALLING_BLOCK:
			_trigger_falling_block()
		HazardType.LASER:
			_trigger_laser()
		HazardType.CRUSHER:
			_trigger_crusher()


## Trigger the hazard effect on player
func _trigger_hazard(body: Node3D) -> void:
	if instant_death:
		# Kill player instantly
		if body.has_method("die"):
			body.die()
	else:
		# Deal damage (if damage system exists)
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)

	# Play trigger sound
	if trigger_sound != null:
		_audio_player.stream = trigger_sound
		_audio_player.play()

	# Deactivate if respawn delay is set
	if respawn_delay > 0:
		_deactivate_hazard()


## Deactivate hazard temporarily
func _deactivate_hazard() -> void:
	_is_active = false
	_respawn_timer = respawn_delay
	monitoring = false
	hide()


## Reactivate hazard after respawn delay
func _reactivate_hazard() -> void:
	_is_active = true
	monitoring = true
	show()
	global_position = _original_position


## Update visual feedback based on state
func _update_visual_feedback() -> void:
	# This will be overridden by specific hazard implementations
	# or connected to visual materials/shaders

	# For now, basic modulation
	if _is_warning:
		modulate = warning_color
	elif _is_active:
		modulate = danger_color
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.3)  # Inactive/respawning


## Type-specific: Falling block behavior
func _trigger_falling_block() -> void:
	# Start falling animation
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", global_position.y - 20, 2.0)
	tween.finished.connect(_on_fall_complete)


## Called when falling block finishes falling
func _on_fall_complete() -> void:
	if respawn_delay > 0:
		_deactivate_hazard()


## Type-specific: Laser activation
func _trigger_laser() -> void:
	# Enable laser collision
	monitoring = true
	# Visual would show laser beam
	pass


## Type-specific: Crusher activation
func _trigger_crusher() -> void:
	# Start crushing animation
	# Move crusher to crush position then back
	pass


## Reset hazard to initial state (for level reset)
func reset_hazard() -> void:
	_is_active = true
	_is_warning = false
	_warning_timer = 0.0
	_respawn_timer = 0.0
	global_position = _original_position
	monitoring = true
	show()
