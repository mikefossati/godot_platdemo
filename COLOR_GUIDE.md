# Quick Color Guide

## Game Element Colors

```
┌──────────────────────────────────────────────────────────┐
│  GAME ELEMENT          COLOR           RGB VALUES        │
├──────────────────────────────────────────────────────────┤
│  🔵 PLAYER             Bright Blue     (0.2, 0.6, 1.0)   │
│  ⭐ COLLECTIBLES       Shiny Gold      (1.0, 0.85, 0.1)  │
│  🟫 PLATFORMS          Sandy Brown     (0.7, 0.55, 0.35) │
│  🟩 GROUND             Forest Green    (0.25, 0.5, 0.25) │
│  ☁️  BACKGROUND         Sky Blue        (0.4, 0.6, 0.9)  │
└──────────────────────────────────────────────────────────┘
```

## What You'll See In-Game

### The Player (You)
- **Appearance**: Blue capsule/cylinder
- **Height**: About 2 units tall
- **Why Blue**: Stands out against all environments
- **Easy to spot**: Yes! Clearly visible at all times

### Collectibles (Items to Collect)
- **Appearance**: Golden spinning rings (toruses)
- **Special Effect**: Slight glow + shiny metallic surface
- **Animation**: Rotates and bobs up/down
- **Why Gold**: Maximum visibility, clearly valuable
- **Count**: 5 total in the level

### Platforms (Where You Jump)
- **Appearance**: Brown rectangular blocks
- **Color**: Sandy tan/brown (like wood or stone)
- **Sizes**: 4x4 units each
- **Heights**: Various (1 to 3 units high)
- **Why Brown**: Natural, distinct from ground

### Ground (Base Floor)
- **Appearance**: Large green platform
- **Color**: Dark forest green (like grass)
- **Size**: 20x20 units (main play area)
- **Why Green**: Suggests safe ground, contrasts platforms

### Background (Sky/Void)
- **Appearance**: Light blue empty space
- **Color**: Sky blue
- **Why Blue**: Creates sense of open space, depth

## Visual Hierarchy

```
MOST NOTICEABLE
    ↓
✨ Gold Collectibles (shiny, glowing)
    ↓
🔵 Blue Player (bright, solid color)
    ↓
🟫 Brown Platforms (mid-tone, functional)
    ↓
🟩 Green Ground (darker, base layer)
    ↓
☁️ Blue Sky (lightest, background)
    ↓
LEAST NOTICEABLE
```

## Lighting

- **Sun (Directional Light)**: Warm white, casts shadows
- **Ambient Light**: Cool bluish-white, fills shadows
- **Result**: Objects are clearly defined with good depth

## Tips for Playing

1. **Look for gold** - Collectibles are the shiniest objects
2. **Follow the blue** - You're always visible (blue capsule)
3. **Brown = Safe** - You can land on brown platforms
4. **Green = Ground** - The base level you start on
5. **Shadows help** - Show platform heights and distances

## Color Accessibility

- **Colorblind Consideration**:
  - High contrast between all elements
  - Shape differences (capsule vs ring vs box)
  - Collectibles also glow (luminance difference)
  - Different heights create depth even without color

## Material Properties

```
Element      Shiny?   Glows?   Metallic?   Matte?
Player       Medium   No       Slightly    -
Collectible  VERY     YES      YES         -
Platform     -        No       No          YES
Ground       -        No       No          YES
```

## Quick Reference Card

**IF YOU SEE:**

| Visual | It's the... | What to do |
|--------|-------------|------------|
| 🔵 Blue capsule | Player (YOU) | Control with WASD |
| ⭐ Shiny gold ring | Collectible | Touch to collect! |
| 🟫 Brown box | Platform | Jump on it |
| 🟩 Green flat area | Ground | Safe base |
| ☁️ Light blue void | Background | Don't fall in! |
| 🌑 Dark shadow | Shadow | Shows depth |

## RGB Values (For Reference)

If you want to modify colors in the Godot editor:

```gdscript
# Player Material
Color(0.2, 0.6, 1.0, 1.0)  # RGBA: Blue

# Collectible Material
Color(1.0, 0.85, 0.1, 1.0)  # RGBA: Gold

# Platform Material
Color(0.7, 0.55, 0.35, 1.0)  # RGBA: Brown

# Ground Material
Color(0.25, 0.5, 0.25, 1.0)  # RGBA: Green

# Background Color
Color(0.4, 0.6, 0.9, 1.0)  # RGBA: Sky Blue
```

## Material Locations in Project

- **Player**: `scenes/player/player.tscn` → StandardMaterial3D_player
- **Collectible**: `scenes/collectibles/collectible.tscn` → StandardMaterial3D_collectible
- **Platforms**: `scenes/level/main_level.tscn` → StandardMaterial3D_platform
- **Ground**: `scenes/level/main_level.tscn` → StandardMaterial3D_ground

All materials use **StandardMaterial3D** (PBR shader).
