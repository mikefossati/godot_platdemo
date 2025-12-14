# 3D Platformer Prototype - Godot 4.5.1

A simple 3D platformer game prototype built with Godot 4.5.1 and GDScript, featuring player movement, collectibles, and a complete game loop.

**Tested and verified on Godot 4.5.1**

## Features

- **Player Controller**: WASD movement with spacebar jump
- **Physics-based Movement**: Gravity, collision detection, and smooth character control
- **Collectible System**: 5 glowing gold collectibles scattered across platforms
- **Camera System**: Smooth third-person camera that follows the player
- **UI System**: Real-time score and collectible counter
- **Game Flow**: Main menu, gameplay, and game over screens
- **Fall Detection**: Player respawns when falling off the level
- **Visual Clarity**: Color-coded materials (blue player, gold collectibles, brown platforms, green ground)
- **Lighting**: Enhanced lighting with shadows for better depth perception

## Project Structure

```
plat_godot/
├── project.godot              # Main project configuration
├── icon.svg                   # Project icon
├── scripts/                   # All GDScript files
│   ├── game_manager.gd        # Global game state management (Autoload)
│   ├── player.gd              # Player movement and physics
│   ├── collectible.gd         # Collectible item behavior
│   ├── camera_follow.gd       # Camera following system
│   ├── game_ui.gd             # In-game UI controller
│   ├── main_menu.gd           # Main menu controller
│   └── game_over.gd           # Game over screen controller
├── scenes/                    # All scene files (.tscn)
│   ├── player/
│   │   └── player.tscn        # Player character scene
│   ├── collectibles/
│   │   └── collectible.tscn   # Collectible item scene
│   ├── level/
│   │   └── main_level.tscn    # Main game level
│   └── ui/
│       ├── main_menu.tscn     # Main menu screen
│       ├── game_over.tscn     # Game over screen
│       └── game_ui.tscn       # In-game HUD
└── assets/                    # Assets folder (currently empty)
```

## How to Run

1. Open Godot 4.5.1 (or compatible 4.5.x version)
2. Click "Import" and select the `project.godot` file
3. Click "Import & Edit"
4. Press F5 or click the Play button to run the game

## Version Requirements

- **Godot Engine**: 4.5.1 or later
- **Renderer**: Forward+ (default for 3D in Godot 4.5+)
- **Platform**: Windows, macOS, Linux

## Controls

- **W/A/S/D**: Move forward/left/backward/right
- **Spacebar**: Jump
- **Mouse**: Navigate menus

## Game Mechanics

### Player Movement
The player controller uses `CharacterBody3D` which provides built-in physics and collision handling:
- Movement is frame-rate independent using delta time
- Gravity is applied when not on the ground
- Smooth rotation toward movement direction
- Jump only works when grounded (no double-jumping)

### Collectibles
- 5 collectibles are placed throughout the level
- Each collectible rotates and bobs up and down for visibility
- Worth 10 points each
- Uses Area3D for overlap detection

### Camera
- Third-person follow camera
- Smooth interpolation (lerp) for fluid movement
- Always looks at the player
- Positioned behind and above the player

### Game Flow
1. **Main Menu**: Start game or quit
2. **Gameplay**: Collect items while platforming
3. **Game Over**: Triggered when falling off the level
4. **Results**: Shows final score and collectibles collected

## Core Concepts Explained

### Autoload (Singleton Pattern)
`GameManager` is configured as an autoload, meaning it persists across all scenes and can be accessed from anywhere using `GameManager.function_name()`. This is ideal for managing global state like score and scene transitions.

### Signals (Observer Pattern)
The game uses Godot's signal system for decoupled communication:
- `GameManager` emits signals when score/collectibles change
- UI elements listen to these signals and update automatically
- This keeps code modular and maintainable

### Physics Layers
The project uses physics layers for collision filtering:
- Layer 1: World (platforms, ground)
- Layer 2: Player
- Layer 3: Collectibles

### Scene Instancing
Collectibles use scene instancing - a single `collectible.tscn` is reused multiple times in the level. Changes to the original scene automatically propagate to all instances.

## Extending the Game

### Adding More Levels
1. Duplicate `main_level.tscn`
2. Modify the platforms and collectible positions
3. Update `GameManager.start_game()` to load your new level

### Adding Power-ups
1. Create a new script similar to `collectible.gd`
2. Use Area3D for detection
3. Add new behavior in the `_on_body_entered` function

### Improving Graphics
1. Import 3D models into the `assets/` folder
2. Replace the simple mesh instances with your models
3. Add materials and textures for better visuals

### Adding Sound
1. Add AudioStreamPlayer nodes to scenes
2. Import audio files to `assets/`
3. Play sounds on events (jump, collect, etc.)

## Design Patterns Used

- **Singleton**: GameManager autoload for global state
- **Observer**: Signal-based communication between systems
- **Component**: Modular scripts attached to scene nodes
- **Scene Tree**: Hierarchical organization of game objects

## Godot 4.5.1 Compatibility

This project has been specifically configured and tested for Godot 4.5.1:

- **Project features**: Set to "4.5" for full compatibility
- **Scene format**: All scenes use format 3 (current Godot 4.x standard)
- **Environment setup**: WorldEnvironment includes proper Environment and Sky resources
- **Physics system**: Uses current CharacterBody3D and Area3D APIs
- **Signal syntax**: Uses Godot 4.x signal connection style with `.connect()`
- **Type hints**: GDScript 2.0 static typing throughout
- **Input system**: Uses new input action system with `Input.get_vector()`

All features used are stable and supported in Godot 4.5.1 with no deprecation warnings.

## Educational Notes

This prototype demonstrates fundamental 3D game development concepts:
- Character controller physics
- Collision detection and response
- Camera systems
- Game state management
- UI integration with game logic
- Scene transitions
- Input handling

Each script is heavily commented to explain the "why" behind the code, not just the "what".

## Asset Credits

### 3D Models
All 3D models are from the **Ultimate Platformer Pack** by Quaternius:
- **Character Model**: Animated platformer character
- **Star Collectibles**: Star pickup model
- **Platform Models**: Grass-themed modular platforms

**Source**: https://quaternius.com/packs/ultimateplatformer.html
**License**: CC0 (Public Domain) - Free for personal and commercial use
**Attribution**: Not required but appreciated

Thank you to Quaternius for providing high-quality, free 3D assets to the game development community!

## License

This is a learning prototype - feel free to use and modify for educational purposes.

Game code and scripts: Created for educational purposes
3D Assets: CC0 by Quaternius (see Asset Credits above)
