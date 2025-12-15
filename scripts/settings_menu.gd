extends Control

## SettingsMenu - UI for adjusting game settings
## Can be used standalone or as overlay in pause menu

# UI References - Audio Tab
@onready var master_volume_slider: HSlider = $TabContainer/Audio/VBoxContainer/MasterVolume/Slider
@onready var master_volume_label: Label = $TabContainer/Audio/VBoxContainer/MasterVolume/ValueLabel
@onready var music_volume_slider: HSlider = $TabContainer/Audio/VBoxContainer/MusicVolume/Slider
@onready var music_volume_label: Label = $TabContainer/Audio/VBoxContainer/MusicVolume/ValueLabel
@onready var sfx_volume_slider: HSlider = $TabContainer/Audio/VBoxContainer/SFXVolume/Slider
@onready var sfx_volume_label: Label = $TabContainer/Audio/VBoxContainer/SFXVolume/ValueLabel
@onready var mute_checkbox: CheckBox = $TabContainer/Audio/VBoxContainer/MuteCheckBox

# UI References - Display Tab
@onready var fullscreen_checkbox: CheckBox = $TabContainer/Display/VBoxContainer/FullscreenCheckBox
@onready var vsync_checkbox: CheckBox = $TabContainer/Display/VBoxContainer/VsyncCheckBox
@onready var resolution_option: OptionButton = $TabContainer/Display/VBoxContainer/ResolutionOption

# UI References - Gameplay Tab
@onready var camera_shake_checkbox: CheckBox = $TabContainer/Gameplay/VBoxContainer/CameraShakeCheckBox
@onready var screen_flash_checkbox: CheckBox = $TabContainer/Gameplay/VBoxContainer/ScreenFlashCheckBox
@onready var show_timer_checkbox: CheckBox = $TabContainer/Gameplay/VBoxContainer/ShowTimerCheckBox
@onready var show_fps_checkbox: CheckBox = $TabContainer/Gameplay/VBoxContainer/ShowFPSCheckBox

# UI References - Buttons
@onready var apply_button: Button = $BottomButtons/ApplyButton
@onready var reset_button: Button = $BottomButtons/ResetButton
@onready var close_button: Button = $BottomButtons/CloseButton

# State
var _has_unsaved_changes: bool = false


func _ready() -> void:
	# Connect all signals
	_connect_audio_signals()
	_connect_display_signals()
	_connect_gameplay_signals()
	_connect_button_signals()

	# Load current settings
	load_current_settings()

	# Initially hidden if used as overlay
	if get_parent().name == "PauseMenu":
		hide()


## Connect audio tab signals
func _connect_audio_signals() -> void:
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if mute_checkbox:
		mute_checkbox.toggled.connect(_on_mute_toggled)


## Connect display tab signals
func _connect_display_signals() -> void:
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	if vsync_checkbox:
		vsync_checkbox.toggled.connect(_on_vsync_toggled)
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_selected)


## Connect gameplay tab signals
func _connect_gameplay_signals() -> void:
	if camera_shake_checkbox:
		camera_shake_checkbox.toggled.connect(_on_camera_shake_toggled)
	if screen_flash_checkbox:
		screen_flash_checkbox.toggled.connect(_on_screen_flash_toggled)
	if show_timer_checkbox:
		show_timer_checkbox.toggled.connect(_on_show_timer_toggled)
	if show_fps_checkbox:
		show_fps_checkbox.toggled.connect(_on_show_fps_toggled)


## Connect button signals
func _connect_button_signals() -> void:
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


## Load current settings into UI
func load_current_settings() -> void:
	if not SettingsManager:
		return

	# Audio settings
	if master_volume_slider:
		master_volume_slider.value = SettingsManager.get_setting("audio", "master_volume", 1.0)
		_update_volume_label(master_volume_label, master_volume_slider.value)

	if music_volume_slider:
		music_volume_slider.value = SettingsManager.get_setting("audio", "music_volume", 0.8)
		_update_volume_label(music_volume_label, music_volume_slider.value)

	if sfx_volume_slider:
		sfx_volume_slider.value = SettingsManager.get_setting("audio", "sfx_volume", 1.0)
		_update_volume_label(sfx_volume_label, sfx_volume_slider.value)

	if mute_checkbox:
		mute_checkbox.button_pressed = SettingsManager.get_setting("audio", "muted", false)

	# Display settings
	if fullscreen_checkbox:
		var window_mode = SettingsManager.get_setting("display", "window_mode", 0)
		fullscreen_checkbox.button_pressed = (window_mode == 1)

	if vsync_checkbox:
		vsync_checkbox.button_pressed = SettingsManager.get_setting("display", "vsync", true)

	if resolution_option:
		resolution_option.clear()
		for i in range(SettingsManager.RESOLUTIONS.size()):
			resolution_option.add_item(SettingsManager.get_resolution_name(i))
		resolution_option.selected = SettingsManager.get_setting("display", "resolution_index", 0)

	# Gameplay settings
	if camera_shake_checkbox:
		camera_shake_checkbox.button_pressed = SettingsManager.get_setting("gameplay", "camera_shake", true)

	if screen_flash_checkbox:
		screen_flash_checkbox.button_pressed = SettingsManager.get_setting("gameplay", "screen_flash", true)

	if show_timer_checkbox:
		show_timer_checkbox.button_pressed = SettingsManager.get_setting("gameplay", "show_timer", true)

	if show_fps_checkbox:
		show_fps_checkbox.button_pressed = SettingsManager.get_setting("gameplay", "show_fps", false)

	_has_unsaved_changes = false


## Update volume label display
func _update_volume_label(label: Label, value: float) -> void:
	if label:
		label.text = "%d%%" % int(value * 100)


# Audio callbacks
func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	_update_volume_label(master_volume_label, value)


func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	_update_volume_label(music_volume_label, value)


func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	_update_volume_label(sfx_volume_label, value)
	# Play test sound effect here


func _on_mute_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("audio", "muted", pressed)


# Display callbacks
func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_fullscreen(pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	SettingsManager.set_vsync(pressed)


func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution_index(index)


# Gameplay callbacks
func _on_camera_shake_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay", "camera_shake", pressed)


func _on_screen_flash_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay", "screen_flash", pressed)


func _on_show_timer_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay", "show_timer", pressed)


func _on_show_fps_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("gameplay", "show_fps", pressed)


# Button callbacks
func _on_apply_pressed() -> void:
	# Settings are applied immediately, this just saves
	SettingsManager.save_settings()
	_has_unsaved_changes = false
	print("Settings applied")


func _on_reset_pressed() -> void:
	# Confirm before resetting
	SettingsManager.reset_to_defaults()
	load_current_settings()
	print("Settings reset to defaults")


func _on_close_pressed() -> void:
	# If used as overlay in pause menu, hide
	if get_parent().name == "PauseMenu":
		hide()
	else:
		# If standalone, return to main menu
		if GameManager:
			GameManager.return_to_menu()
