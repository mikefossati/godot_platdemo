extends Node

## Game Constants - Centralized configuration values
## This file contains all magic numbers and measurements used throughout the game

# ==============================================================================
# MODEL DIMENSIONS (Quaternius Platform Pack)
# ==============================================================================
# These values are measured from the actual GLTF models
# All Quaternius models use a 2x2x2 base size before scaling

## Platform Cube Models (Cube_Grass_Single, Cube_Dirt_Single)
const PLATFORM_CUBE_BASE_SIZE := Vector3(2.0, 2.0, 2.0)
const PLATFORM_CUBE_MESH_AABB_SIZE := Vector3(2.233, 1.996, 2.233)  # Actual mesh bounds
const PLATFORM_CUBE_PIVOT_OFFSET := Vector3(0.0, -0.002, 0.0)  # Slight offset from center

## Character Model
const CHARACTER_BASE_SIZE := Vector3(1.0, 2.0, 1.0)  # Approximate
const CHARACTER_COLLISION_RADIUS := 0.5
const CHARACTER_COLLISION_HEIGHT := 2.0

## Collectible (Star) Model
const STAR_BASE_SIZE := Vector3(1.0, 1.0, 1.0)  # Approximate
const STAR_COLLISION_RADIUS := 0.6


# ==============================================================================
# COMMON SCALES
# ==============================================================================
# Standard platform configurations used throughout levels

## Ground tiles - large flat base
const GROUND_TILE_SCALE := Vector3(5.0, 0.5, 5.0)
# Results in: 10x1x10 visual size per tile

## Standard platform - most common
const PLATFORM_SCALE_STANDARD := Vector3(2.0, 0.5, 2.0)
# Results in: 4x1x4 visual size (approx 4.5x1x4.5 with mesh bounds)

## Large platform (if needed in future)
const PLATFORM_SCALE_LARGE := Vector3(3.0, 0.5, 3.0)
# Results in: 6x1x6 visual size

## Tall platform (if needed in future)
const PLATFORM_SCALE_TALL := Vector3(2.0, 1.0, 2.0)
# Results in: 4x2x4 visual size


# ==============================================================================
# COLLISION DIMENSIONS
# ==============================================================================
# Calculated collision shapes based on scaled models

## Ground collision (3x3 grid of tiles)
const GROUND_COLLISION_SIZE := Vector3(30.0, 1.0, 30.0)

## Standard platform collision
const PLATFORM_COLLISION_SIZE_STANDARD := Vector3(4.5, 1.0, 4.5)
# Note: Slightly larger than 4x1x4 to account for mesh bounds (2.233 vs 2.0)


# ==============================================================================
# COLLISION POSITIONING
# ==============================================================================
# Y-offsets for collision shapes relative to parent body

## Ground collision offset
const GROUND_COLLISION_Y_OFFSET := 0.25

## Platform collision offset (relative to parent)
const PLATFORM_COLLISION_Y_OFFSET := 0.25

## Platform model offset (relative to parent)
const PLATFORM_MODEL_Y_OFFSET := 0.25


# ==============================================================================
# CAMERA OFFSETS
# ==============================================================================
# Camera positioning for different level difficulties

## Level 1 - Easy (platforms up to Y=3)
const CAMERA_OFFSET_EASY := Vector3(0.0, 5.0, 8.0)

## Level 2 - Medium (platforms up to Y=4.5)
const CAMERA_OFFSET_MEDIUM := Vector3(0.0, 6.0, 10.0)

## Level 3 - Hard (platforms up to Y=8)
const CAMERA_OFFSET_HARD := Vector3(0.0, 8.0, 12.0)


# ==============================================================================
# VALIDATION TOLERANCES
# ==============================================================================
# Acceptable differences when validating collision alignment

## Position tolerance (units)
const POSITION_TOLERANCE := 0.1

## Size tolerance (units)
const SIZE_TOLERANCE := 0.2


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

## Calculate collision size for a scaled platform model
func calculate_platform_collision_size(model_scale: Vector3) -> Vector3:
	return PLATFORM_CUBE_MESH_AABB_SIZE * model_scale


## Calculate collision position for a scaled platform model
func calculate_platform_collision_position(_model_scale: Vector3) -> Vector3:
	# Model is offset by 0.25, collision should match
	# Note: Position is constant regardless of scale (always centered at Y=0.25)
	return Vector3(0, PLATFORM_MODEL_Y_OFFSET, 0)


## Get expected camera offset for a level difficulty
func get_camera_offset_for_difficulty(difficulty: int) -> Vector3:
	match difficulty:
		1: return CAMERA_OFFSET_EASY
		2: return CAMERA_OFFSET_MEDIUM
		3: return CAMERA_OFFSET_HARD
		_: return CAMERA_OFFSET_EASY


## Validate if two positions are within tolerance
func positions_match(pos1: Vector3, pos2: Vector3, tolerance: float = POSITION_TOLERANCE) -> bool:
	return pos1.distance_to(pos2) < tolerance


## Validate if two sizes are within tolerance
func sizes_match(size1: Vector3, size2: Vector3, tolerance: float = SIZE_TOLERANCE) -> bool:
	return (abs(size1.x - size2.x) < tolerance and
			abs(size1.y - size2.y) < tolerance and
			abs(size1.z - size2.z) < tolerance)


# ==============================================================================
# ANIMATION DURATIONS
# ==============================================================================
# Animation timing constants to prevent magic numbers in code

## How long to persist landing signal (in seconds)
## Ensures state machine has time to process the landing transition
const LANDING_SIGNAL_DURATION: float = 0.083  # 5 frames at 60fps

## Punch animation duration for collectible pickup (in seconds)
const PUNCH_ANIMATION_DURATION: float = 0.5

## Wave animation duration for level completion celebration (in seconds)
const WAVE_ANIMATION_DURATION: float = 2.0

## How long to wait after victory animation before showing level complete screen (in seconds)
const VICTORY_WAIT_DURATION: float = 5.0

## How long collectible remains visible during pickup animation (in seconds)
const COLLECTIBLE_PICKUP_DELAY: float = 0.5


# ==============================================================================
# PHYSICS & GAMEPLAY
# ==============================================================================

## Default Y position below which the player dies (falls off level)
## Can be overridden per-level if needed
const DEFAULT_DEATH_Y: float = -10.0


# ==============================================================================
# SCORING
# ==============================================================================

## Points awarded for collecting a single collectible
const COLLECTIBLE_POINTS: int = 10


# ==============================================================================
# CAMERA SETTINGS
# ==============================================================================

## How quickly camera follows player (lerp speed)
const DEFAULT_CAMERA_FOLLOW_SPEED: float = 5.0

## Safety margin for SpringArm collision detection
const DEFAULT_CAMERA_COLLISION_MARGIN: float = 0.3


# ==============================================================================
# COLLECTIBLES
# ==============================================================================

## Default rotation speed for collectible spinning animation (radians per second)
const COLLECTIBLE_ROTATION_SPEED: float = 2.0

## Height of bobbing animation for collectibles
const COLLECTIBLE_BOB_HEIGHT: float = 0.3

## Speed of bobbing animation for collectibles
const COLLECTIBLE_BOB_SPEED: float = 2.0


# ==============================================================================
# SAVE SYSTEM
# ==============================================================================

## Path to save file
const SAVE_PATH: String = "user://game_save.cfg"

## Save file version for migration purposes
const SAVE_VERSION: String = "1.0"


# ==============================================================================
# ANIMATION HELPER FUNCTIONS
# ==============================================================================

## Convert seconds to frames at 60fps
static func seconds_to_frames(seconds: float) -> int:
	return int(seconds * 60.0)

## Get landing signal duration in frames
static func get_landing_frames() -> int:
	return seconds_to_frames(LANDING_SIGNAL_DURATION)

## Get punch animation duration in frames
static func get_punch_frames() -> int:
	return seconds_to_frames(PUNCH_ANIMATION_DURATION)

## Get wave animation duration in frames
static func get_wave_frames() -> int:
	return seconds_to_frames(WAVE_ANIMATION_DURATION)
