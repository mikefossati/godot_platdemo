# Settings System Guide

## Overview

The settings system provides comprehensive player customization for a commercial-quality game. It includes audio, display, gameplay, and accessibility settings with automatic persistence.

## Architecture

### Components

1. **SettingsManager** (Autoload)
   - Manages all settings state
   - Persists to `user://settings.cfg`
   - Applies settings to engine (audio, display, etc.)
   - Provides signals for settings changes

2. **SettingsMenu** (UI Scene)
   - User interface for adjusting settings
   - Tabbed interface (Audio, Display, Gameplay)
   - Real-time preview of changes
   - Can be used standalone or in pause menu

3. **Audio Bus Layout**
   - Master bus (all audio)
   - Music bus (background music)
   - SFX bus (sound effects)

4. **GameHUD** (In-game display)
   - Respects gameplay settings
   - Shows/hides timer based on preferences
   - Shows FPS counter if enabled

## Settings Categories

### Audio Settings

**Master Volume** (0-100%)
- Controls overall game volume
- Applied to Master audio bus

**Music Volume** (0-100%)
- Controls background music
- Applied to Music audio bus

**SFX Volume** (0-100%)
- Controls sound effects
- Applied to SFX audio bus

**Mute Toggle**
- Mutes all audio when enabled

### Display Settings

**Window Mode**
- 0 = Windowed
- 1 = Fullscreen
- 2 = Borderless Fullscreen

**Resolution** (Windowed mode only)
- 1280x720 (HD)
- 1920x1080 (Full HD)
- 2560x1440 (2K)
- 3840x2160 (4K)

**VSync**
- Enable/disable vertical sync
- Prevents screen tearing
- May impact performance

### Gameplay Settings

**Camera Shake** (bool)
- Enable/disable camera shake effects
- For players sensitive to motion

**Screen Flash** (bool)
- Enable/disable screen flash effects
- Accessibility option

**Show Timer** (bool)
- Show/hide level timer in HUD
- For players who prefer no pressure

**Show FPS** (bool)
- Show/hide FPS counter
- Debug/performance monitoring

### Accessibility Settings (Future)

**Colorblind Mode**
- None
- Protanopia (red-blind)
- Deuteranopia (green-blind)
- Tritanopia (blue-blind)

**High Contrast Mode** (bool)
- Increases visual contrast

**Large Text** (bool)
- Increases UI text size

## Usage in Code

### Getting Settings

```gdscript
# Get a specific setting
var show_timer = SettingsManager.get_setting("gameplay", "show_timer", true)

# Check camera shake setting
if SettingsManager.get_setting("gameplay", "camera_shake", true):
    apply_camera_shake()
```

### Setting Settings

```gdscript
# Set a specific setting
SettingsManager.set_setting("audio", "master_volume", 0.8)

# Use convenience methods
SettingsManager.set_master_volume(0.8)
SettingsManager.set_fullscreen(true)
SettingsManager.set_vsync(false)
```

### Listening for Changes

```gdscript
func _ready():
    SettingsManager.audio_settings_changed.connect(_on_audio_changed)
    SettingsManager.display_settings_changed.connect(_on_display_changed)
    SettingsManager.gameplay_settings_changed.connect(_on_gameplay_changed)

func _on_audio_changed():
    # Reload audio-related settings
    pass
```

## Creating the Settings Menu Scene

### Scene Structure

```
SettingsMenu (Control) - attach settings_menu.gd
├── TabContainer
│   ├── Audio (VBoxContainer)
│   │   ├── MasterVolume (HBoxContainer)
│   │   │   ├── Label ("Master Volume")
│   │   │   ├── Slider (HSlider, min=0, max=1, step=0.01)
│   │   │   └── ValueLabel (Label, "100%")
│   │   ├── MusicVolume (HBoxContainer)
│   │   │   ├── Label ("Music Volume")
│   │   │   ├── Slider (HSlider)
│   │   │   └── ValueLabel (Label)
│   │   ├── SFXVolume (HBoxContainer)
│   │   │   ├── Label ("SFX Volume")
│   │   │   ├── Slider (HSlider)
│   │   │   └── ValueLabel (Label)
│   │   └── MuteCheckBox (CheckBox, "Mute All")
│   │
│   ├── Display (VBoxContainer)
│   │   ├── FullscreenCheckBox (CheckBox, "Fullscreen")
│   │   ├── VsyncCheckBox (CheckBox, "VSync")
│   │   └── ResolutionOption (OptionButton)
│   │
│   └── Gameplay (VBoxContainer)
│       ├── CameraShakeCheckBox (CheckBox, "Camera Shake")
│       ├── ScreenFlashCheckBox (CheckBox, "Screen Flash")
│       ├── ShowTimerCheckBox (CheckBox, "Show Timer")
│       └── ShowFPSCheckBox (CheckBox, "Show FPS")
│
└── BottomButtons (HBoxContainer)
    ├── ApplyButton (Button, "Apply")
    ├── ResetButton (Button, "Reset to Defaults")
    └── CloseButton (Button, "Close")
```

### Node Configuration

**HSlider (Volume Sliders):**
- Min Value: 0
- Max Value: 1
- Step: 0.01
- Allow Greater: false
- Allow Lesser: false

**OptionButton (Resolution):**
- Items populated by script

**CheckBox:**
- Default state matches DEFAULT_SETTINGS

## Integration with Pause Menu

Update `pause_menu.gd`:

```gdscript
func _on_settings_pressed() -> void:
    var settings_menu = preload("res://scenes/ui/settings_menu.tscn").instantiate()
    add_child(settings_menu)
```

Or create a persistent settings menu child that shows/hides.

## Creating the Game HUD Scene

### Scene Structure

```
GameHUD (CanvasLayer) - attach game_hud.gd
├── TopLeft (VBoxContainer)
│   ├── TimerLabel (Label, "Time: 00:00.00")
│   ├── CollectiblesLabel (Label, "Stars: 0/5")
│   ├── ScoreLabel (Label, "Score: 0")
│   └── DeathCounterLabel (Label, "Deaths: 0")
│
└── TopRight (VBoxContainer)
    └── FPSLabel (Label, "FPS: 60")
```

Add to each level scene as a child node.

## File Locations

**Settings File:**
- Windows: `%APPDATA%\Godot\app_userdata\[ProjectName]\settings.cfg`
- Linux: `~/.local/share/godot/app_userdata/[ProjectName]/settings.cfg`
- macOS: `~/Library/Application Support/Godot/app_userdata/[ProjectName]/settings.cfg`

## Default Values

All defaults defined in `SettingsManager.DEFAULT_SETTINGS`:

```gdscript
{
    "audio": {
        "master_volume": 1.0,
        "music_volume": 0.8,
        "sfx_volume": 1.0,
        "muted": false
    },
    "display": {
        "fullscreen": false,
        "vsync": true,
        "resolution_index": 0,
        "window_mode": 0
    },
    "gameplay": {
        "camera_shake": true,
        "screen_flash": true,
        "show_timer": true,
        "show_fps": false
    }
}
```

## Audio Implementation

### Playing Music

```gdscript
var music_player = AudioStreamPlayer.new()
music_player.bus = "Music"  # Use Music bus
music_player.stream = preload("res://audio/music/level_1.ogg")
music_player.play()
```

### Playing SFX

```gdscript
var sfx_player = AudioStreamPlayer3D.new()
sfx_player.bus = "SFX"  # Use SFX bus
sfx_player.stream = preload("res://audio/sfx/jump.wav")
sfx_player.play()
```

### Audio Buses Hierarchy

```
Master (index 0)
├── Music (index 1)
└── SFX (index 2)
```

## Best Practices

1. **Always use SettingsManager for settings**
   - Don't store settings in other places
   - Use signals for updates

2. **Respect player preferences**
   - Check camera shake before applying
   - Check screen flash before effects
   - Honor timer visibility

3. **Provide defaults**
   - All settings have sensible defaults
   - Reset to defaults option available

4. **Auto-save**
   - Settings save immediately on change
   - No need to click "Apply" (but button exists for familiarity)

5. **Audio bus usage**
   - Music → "Music" bus
   - SFX → "SFX" bus
   - UI sounds → "SFX" bus

## Testing Checklist

- [ ] Settings persist between sessions
- [ ] Volume sliders work and update audio
- [ ] Fullscreen toggles correctly
- [ ] Resolution changes apply (windowed mode)
- [ ] VSync toggles
- [ ] Timer shows/hides based on setting
- [ ] FPS counter shows/hides based on setting
- [ ] Reset to defaults works
- [ ] Settings menu accessible from pause menu
- [ ] All settings survive game restart

## Future Enhancements

1. **Input Remapping**
   - Allow players to customize controls
   - Gamepad support configuration

2. **Accessibility**
   - Colorblind modes implementation
   - Screen reader support
   - Subtitle options

3. **Graphics Quality**
   - Shadow quality
   - Particle density
   - Anti-aliasing options

4. **Language Selection**
   - Multi-language support
   - Localization system

5. **Cloud Save**
   - Optional cloud sync of settings
   - Cross-device preferences
