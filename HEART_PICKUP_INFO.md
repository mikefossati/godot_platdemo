# Heart Pickup - How It Works

## Expected Behavior

**Hearts can ONLY be collected when the player is damaged!** ❤️

This is intentional game design - hearts are for healing, not for collection at full health.

## Collection Requirements

1. ✅ Player must have less than maximum health
2. ✅ Player must touch the heart (collision detection)
3. ✅ Player must be in the "player" group

## Why Can't I Collect It?

If you can't collect the heart, it's because:
- **You're at full health!** (Most common reason)
- The player needs to take damage first

## How to Test in Showcase Level

### Heart Section (Southeast)
1. Jump on the **spike** (located at -2, 2, 0 in Heart Section)
2. You'll take damage and lose 1 HP
3. Now you can collect the heart!
4. Heart restores 1 HP

### Visual Indicators
- **Red pulsing glow** - Heart is present
- **Bobbing animation** - Heart is active
- **Debug console** shows:
  - `"HeartPickup: Body entered - Player"`
  - `"HeartPickup: Player HP = X/Y"`
  - Either collects or shows "Player at full health, cannot collect"

## Debug Output

When in debug build, the console will show:

```
HeartPickup: Body entered - Player
HeartPickup: Player HP = 3/3
HeartPickup: Player at full health, cannot collect
```

After taking damage from spike:
```
HeartPickup: Body entered - Player
HeartPickup: Player HP = 2/3
HeartPickup: Healed player for 1 HP (was 2/3, now 3/3)
```

## Code Logic

```gdscript
func collect(player_node: Node3D) -> void:
    var health_component = player_node.get_node("HealthComponent")
    var current_hp = health_component.current_health
    var max_hp = health_component.max_health

    # Can only collect if damaged
    if current_hp >= max_hp:
        return  # At full health, don't collect

    # Heal the player
    health_component.heal(1)
    queue_free()  # Remove heart
```

## Design Rationale

### Why This Design?

1. **Prevents Waste** - Can't "stock up" on hearts
2. **Strategic Placement** - Hearts go before difficult sections
3. **Risk/Reward** - Players must manage when to use them
4. **Classic Design** - Matches many platformer conventions (Mario, Zelda, etc.)

### Alternative Behaviors (Not Implemented)

- ❌ Collect hearts for inventory
- ❌ Extra points when collected at full health
- ❌ Over-healing (health above maximum)

## Level Design Usage

Place hearts:
- Before boss battles
- After difficult platforming sections
- Near hazards (spikes, enemies)
- After checkpoint areas

Don't place hearts:
- At level start (player at full health)
- Far from any damage sources
- In safe exploration areas

## Troubleshooting

### "Nothing happens when I touch it"
→ You're at full health. Take damage from a spike or enemy first.

### "I touched the spike but still can't collect"
→ Check debug console. You may need to wait a moment or touch the heart directly.

### "No debug messages appear"
→ Make sure you're running in debug mode (not release build).

### "Heart disappeared without healing"
→ Check if another system removed it or if there was a script error.

## Future Enhancements (Phase 8)

- Visual feedback when heart can't be collected (gray out or dim)
- Tooltip showing "Full health!" when trying to collect
- Particle effect showing healing amount
- Sound effect for healing
- Animation on player when healed

## Testing Checklist

- [ ] Heart visible and pulsing
- [ ] Can't collect at full health
- [ ] Taking spike damage reduces HP
- [ ] Can collect heart after taking damage
- [ ] Heart restores 1 HP correctly
- [ ] Heart disappears after collection
- [ ] Debug messages appear in console
- [ ] Collision detection works properly
