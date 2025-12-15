extends Node

## SettingsManager - Manages game settings and preferences
## Autoload singleton for persisting player preferences
## Critical for commercial game - respects player preferences

# Settings file path
const SETTINGS_PATH: String = "user://settings.cfg"

# Default settings
const DEFAULT_SETTINGS: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"muted": false
	},
	"display": {
		"fullscreen": false,
		"vsync": true,
		"resolution_index": 0,  # 0 = 1280x720, 1 = 1920x1080, 2 = 2560x1440
		"window_mode": 0  # 0 = windowed, 1 = fullscreen, 2 = borderless
	},
	"gameplay": {
		"camera_shake": true,
		"screen_flash": true,
		"show_timer": true,
		"show_fps": false
	},
	"accessibility": {
		"colorblind_mode": 0,  # 0 = none, 1 = protanopia, 2 = deuteranopia, 3 = tritanopia
		"high_contrast": false,
		"large_text": false
	}
}

# Available resolutions
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),   # 720p
	Vector2i(1920, 1080),  # 1080p
	Vector2i(2560, 1440),  # 1440p
	Vector2i(3840, 2160)   # 4K
]

# Current settings (loaded from file or defaults)
var current_settings: Dictionary = {}

# Signals for settings changes
signal settings_changed(category: String, key: String, value: Variant)
signal audio_settings_changed
signal display_settings_changed
signal gameplay_settings_changed


func _ready() -> void:
	# Load settings or use defaults
	load_settings()

	# Apply settings to engine
	apply_all_settings()

	print("SettingsManager: Initialized")


## Load settings from file
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err != OK:
		# No settings file, use defaults
		print("SettingsManager: No settings file found, using defaults")
		current_settings = DEFAULT_SETTINGS.duplicate(true)
		save_settings()  # Create settings file
		return

	# Load each category
	current_settings = {}
	for category in DEFAULT_SETTINGS.keys():
		current_settings[category] = {}
		for key in DEFAULT_SETTINGS[category].keys():
			var value = config.get_value(category, key, DEFAULT_SETTINGS[category][key])
			current_settings[category][key] = value

	print("SettingsManager: Settings loaded from %s" % SETTINGS_PATH)


## Save settings to file
func save_settings() -> void:
	var config = ConfigFile.new()

	# Save each category
	for category in current_settings.keys():
		for key in current_settings[category].keys():
			config.set_value(category, key, current_settings[category][key])

	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: Failed to save settings: %d" % err)
	else:
		print("SettingsManager: Settings saved to %s" % SETTINGS_PATH)


## Apply all settings to the engine
func apply_all_settings() -> void:
	apply_audio_settings()
	apply_display_settings()
	apply_gameplay_settings()


## Apply audio settings
func apply_audio_settings() -> void:
	var audio = current_settings.audio

	# Set master volume
	var master_db = linear_to_db(audio.master_volume) if audio.master_volume > 0 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), audio.muted)

	# Set music volume (bus index 1)
	if AudioServer.get_bus_count() > 1:
		var music_db = linear_to_db(audio.music_volume) if audio.music_volume > 0 else -80.0
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_db)

	# Set SFX volume (bus index 2)
	if AudioServer.get_bus_count() > 2:
		var sfx_db = linear_to_db(audio.sfx_volume) if audio.sfx_volume > 0 else -80.0
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_db)

	audio_settings_changed.emit()


## Apply display settings
func apply_display_settings() -> void:
	var display = current_settings.display

	# Set window mode
	match display.window_mode:
		0:  # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:  # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:  # Borderless
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	# Set resolution (only in windowed mode)
	if display.window_mode == 0:
		var resolution = RESOLUTIONS[display.resolution_index]
		DisplayServer.window_set_size(resolution)
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - resolution) / 2
		DisplayServer.window_set_position(window_pos)

	# Set VSync
	if display.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	display_settings_changed.emit()


## Apply gameplay settings
func apply_gameplay_settings() -> void:
	# These are queried by other systems as needed
	# No direct engine settings to apply
	gameplay_settings_changed.emit()


## Get a setting value
func get_setting(category: String, key: String, default_value: Variant = null) -> Variant:
	if current_settings.has(category) and current_settings[category].has(key):
		return current_settings[category][key]
	return default_value


## Set a setting value
func set_setting(category: String, key: String, value: Variant) -> void:
	if not current_settings.has(category):
		current_settings[category] = {}

	current_settings[category][key] = value
	settings_changed.emit(category, key, value)

	# Auto-save settings
	save_settings()

	# Apply relevant settings
	match category:
		"audio":
			apply_audio_settings()
		"display":
			apply_display_settings()
		"gameplay":
			apply_gameplay_settings()


## Set master volume (0.0 to 1.0)
func set_master_volume(volume: float) -> void:
	set_setting("audio", "master_volume", clamp(volume, 0.0, 1.0))


## Set music volume (0.0 to 1.0)
func set_music_volume(volume: float) -> void:
	set_setting("audio", "music_volume", clamp(volume, 0.0, 1.0))


## Set SFX volume (0.0 to 1.0)
func set_sfx_volume(volume: float) -> void:
	set_setting("audio", "sfx_volume", clamp(volume, 0.0, 1.0))


## Toggle mute
func toggle_mute() -> void:
	var muted = get_setting("audio", "muted", false)
	set_setting("audio", "muted", not muted)


## Set fullscreen mode
func set_fullscreen(enabled: bool) -> void:
	set_setting("display", "window_mode", 1 if enabled else 0)


## Set resolution by index
func set_resolution_index(index: int) -> void:
	if index >= 0 and index < RESOLUTIONS.size():
		set_setting("display", "resolution_index", index)


## Set VSync
func set_vsync(enabled: bool) -> void:
	set_setting("display", "vsync", enabled)


## Get current resolution
func get_current_resolution() -> Vector2i:
	var index = get_setting("display", "resolution_index", 0)
	return RESOLUTIONS[index]


## Reset all settings to defaults
func reset_to_defaults() -> void:
	current_settings = DEFAULT_SETTINGS.duplicate(true)
	apply_all_settings()
	save_settings()
	print("SettingsManager: Settings reset to defaults")


## Get resolution name for display
func get_resolution_name(index: int) -> String:
	if index >= 0 and index < RESOLUTIONS.size():
		var res = RESOLUTIONS[index]
		match res:
			Vector2i(1280, 720):
				return "1280x720 (HD)"
			Vector2i(1920, 1080):
				return "1920x1080 (Full HD)"
			Vector2i(2560, 1440):
				return "2560x1440 (2K)"
			Vector2i(3840, 2160):
				return "3840x2160 (4K)"
			_:
				return "%dx%d" % [res.x, res.y]
	return "Unknown"


## Convert linear volume to decibels
func linear_to_db(linear: float) -> float:
	return 20.0 * log(linear) / log(10.0)
