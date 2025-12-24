# Phase 3 Showcase Level

**Level ID**: `level_phase3_showcase`
**Level Name**: Phase 3 Showcase
**Scene**: `scenes/levels/level_phase3_showcase.tscn`

## Overview

This level is a demonstration area showcasing all Phase 3 Collectibles & Economy features. It's designed to let players explore and test every new collectible type in a structured, easy-to-navigate environment.

## Level Layout

The level is organized into 6 distinct sections arranged around a central ground area:

```
                 [Coin Trail]
                      ↑
                      |
    [Coins] ← [Center Ground] → [Crystals]
       ↓                              ↓
   [Chests]                       [Hearts]
                      ↓
                 [Power-ups]
```

### Section Coordinates

1. **Coin Section** - Northwest (-15, 0, -10)
2. **Crystal Section** - Northeast (15, 0, -10)
3. **Chest Section** - Southwest (-15, 0, 10)
4. **Heart Section** - Southeast (15, 0, 10)
5. **Power-up Section** - South (0, 0, 15)
6. **Coin Trail** - North (0, 0, -15)

## Collectibles Showcase

### 1. Coin Section (Northwest)
**Label**: "COINS AREA - Regular (1) | Big (5) | Hidden (10)"

**Platform**: Large grass platform at Y=1

**Coins Included**:
- 3× Regular Coins (yellow, 1 value each)
- 1× Big Coin (blue, 5 value)
- 1× Hidden Coin (gold, 10 value)

**Total Value**: 18 coins

### 2. Crown Crystal Section (Northeast)
**Label**: "CROWN CRYSTALS - Main Objective (3 per level)"

**Platforms**: 3 small platforms at ascending heights (Y=1, 2, 3)

**Crystals**:
- Crystal 0 at (-3, 3, 0)
- Crystal 1 at (0, 4, 0)
- Crystal 2 at (3, 5, 0)

**Features**:
- Dramatic collection sequence
- Light pillars for visibility
- Pulsing glow effects

### 3. Treasure Chest Section (Southwest)
**Label**: "TREASURE CHESTS - Press E to Open"

**Platform**: Large grass platform at Y=1

**Chests**:
- Chest 1 (ID: "showcase_chest_1") - 10 coins
- Chest 2 (ID: "showcase_chest_2") - 15 coins

**Features**:
- Persistent opened state
- Interactive with "E" key
- Coins spawn in arc pattern

### 4. Heart Pickup Section (Southeast)
**Label**: "HEART PICKUPS - Restores 1 Health"

**Platform**: Medium grass platform at Y=1

**Hearts**:
- 1× Heart Pickup at (0, 2.5, 0)

**Features**:
- Pulsing red glow
- Only collectable when damaged
- Restores 1 HP

### 5. Power-up Section (South)
**Label**: "POWER-UPS - Speed | Invincibility | Magnet | 2x Coins"

**Platforms**: 1 large central platform + 4 small elevated platforms

**Power-ups**:
- Speed Boost (Yellow) at (-6, 3.5, 0)
- Invincibility Star (White) at (-2, 3.5, 0)
- Coin Magnet (Purple) at (2, 3.5, 0)
- Double Coins (Gold) at (6, 3.5, 0)

**Duration**: 10 seconds each (configurable)

### 6. Coin Trail (North)
**Label**: "COIN COLLECTION PATH - Follow the trail!"

**Platforms**: 5 small platforms creating ascending stairs

**Coins**: 10 coins forming a trail
- 9× Regular coins along the path
- 1× Big coin at the end (8, 7, 0)

**Total Value**: 14 coins

### Additional Ground Coins
9 regular coins scattered around the central ground area for easy collection.

**Total Value**: 9 coins

## Total Collectibles

| Type | Quantity | Total Value |
|------|----------|-------------|
| Regular Coins | 27 | 27 |
| Big Coins | 2 | 10 |
| Hidden Coins | 1 | 10 |
| **Total Coins** | **30** | **47** |
| Crown Crystals | 3 | 150 points |
| Treasure Chests | 2 | 25 coins |
| Hearts | 1 | - |
| Power-ups | 4 | - |

**Total Coin Value**: 47 + 25 (from chests) = **72 coins**

## Medal Requirements

To earn all 3 medals in this level:

⭐ **Medal 1**: Collect all 3 Crown Crystals
⭐ **Medal 2**: Collect 100 coins (requires multiple playthroughs or additional coins to be added)
⭐ **Medal 3**: Complete under 60 seconds (Gold), 90 seconds (Silver), or 120 seconds (Bronze)

## Level Properties

- **Difficulty**: 1 (Tutorial/Easy)
- **Gold Time**: 60 seconds
- **Silver Time**: 90 seconds
- **Bronze Time**: 120 seconds
- **Require All Collectibles**: Yes (for completion)
- **Require Perfect Run**: No
- **Prerequisites**: None (always unlocked)

## Features Demonstrated

### Coin System ✅
- Magnetic attraction to player
- Visual differentiation (yellow/blue/gold)
- Different coin values
- Rotation and bobbing animations

### Crown Crystal System ✅
- Primary level objective
- Dramatic collection sequence
- Light pillar beacons
- Persistence tracking

### Treasure Chest System ✅
- Interaction prompts
- Opening animations
- Coin spawning
- Persistence (stays open)

### Heart Pickup System ✅
- Health restoration
- Conditional collection
- Pulsing visuals

### Power-up System ✅
- All 4 power-up types
- Visual differentiation by color
- Temporary duration effects
- Fast rotation for visibility

## Testing Checklist

Use this level to verify:

- [ ] Coins attract to player when nearby
- [ ] Different coin types have correct values
- [ ] Crown Crystals show dramatic collection sequence
- [ ] Crystal collection freezes game briefly
- [ ] Treasure chests can be opened with E key
- [ ] Chest contents spawn properly
- [ ] Chests stay open after opening
- [ ] Chests remember opened state on level restart
- [ ] Hearts only collect when player is damaged
- [ ] Speed boost makes player faster
- [ ] Invincibility prevents damage
- [ ] Coin magnet increases collection radius
- [ ] Double coins multiplier works
- [ ] Power-ups last correct duration (10 seconds)
- [ ] Coin counter updates in HUD
- [ ] Medal tracking works correctly
- [ ] Level can be completed by collecting all crystals

## Design Notes

### Educational Purpose
This level is designed to:
1. Introduce players to all Phase 3 features
2. Provide a testing ground for developers
3. Serve as a reference for level designers

### Platform Heights
Platforms are intentionally at different heights to:
- Show vertical platforming
- Test jump mechanics
- Demonstrate coin collection at various elevations
- Create visual interest

### Coin Distribution
Current coin count (72) is below the 100 needed for Medal 2. This is intentional to:
- Allow testing without requiring perfect collection
- Demonstrate that medals are independent
- Show that levels can require multiple playthroughs

To make Medal 2 achievable, add 28 more regular coins throughout the level.

### Power-up Placement
Power-ups are on separate platforms to:
- Allow individual testing
- Prevent accidental multi-collection
- Show clear visual distinction
- Make it easy to observe each effect

## Future Enhancements

Potential additions for this showcase level:

1. **More Coins**: Add 28+ coins to reach 100 total
2. **Combo System**: Add enemies to test combat combos with coins
3. **Secret Areas**: Hidden platforms with bonus collectibles
4. **Shop Access**: Add a shop trigger to test purchases
5. **Moving Platforms**: Show coins on moving platforms
6. **Hazards**: Add spikes to test invincibility power-up
7. **Enemies**: Add basic enemies to test heart pickups
8. **Signage**: More detailed labels explaining each feature

## Integration with Main Game

This level is:
- ✅ Always unlocked (no prerequisites)
- ✅ Registered in GameManager
- ✅ Appears in level select menu
- ✅ Fully playable
- ✅ Tracks medals and completion
- ✅ Saves progress

Perfect for:
- New player onboarding
- Feature demonstrations
- Testing Phase 3 systems
- Level design reference
- Quality assurance
