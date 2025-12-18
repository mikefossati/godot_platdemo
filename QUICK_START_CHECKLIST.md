# Phase 2 Quick Start Checklist

**Before you can test Phase 2, complete these steps:**

---

## ☑️ Step 1: Configure Collision Layers (5 minutes)

**In Godot:** Project → Project Settings → Layer Names → 3D Physics

Set these layer names:

```
Layer 1: World
Layer 2: Player
Layer 3: Player Hurtbox
Layer 4: Enemies
Layer 5: Enemy Hurtbox
Layer 6: Projectiles
```

**Why:** Enemies need to detect the player, projectiles need to hit correctly.

---

## ☑️ Step 2: Create Goblin King Boss Scene (10 minutes)

1. **Create new scene:** `scenes/bosses/goblin_king.tscn`

2. **Root node:** CharacterBody3D named "GoblinKing"

3. **Add script:** Attach `scripts/bosses/goblin_king.gd`

4. **Add child nodes:**
   ```
   GoblinKing (CharacterBody3D)
   ├── HealthComponent (Node) ← Use scripts/components/health_component.gd
   ├── CollisionShape3D ← CapsuleShape3D, height=2, radius=0.5
   ├── CharacterModel (Node3D)
   │   └── MeshInstance3D ← Any mesh (cube/capsule/Quaternius model)
   └── [Optional: Platform nodes for phase 3 despawn]
   ```

5. **Configure collision:**
   - GoblinKing → Layer: 4 (Enemies)
   - GoblinKing → Mask: 1, 2 (World, Player)

6. **Save scene**

---

## ☑️ Step 3: Test Combat Showcase Level (5 minutes)

1. **Open:** `scenes/levels/level_combat_showcase.tscn`

2. **Add enemies to test:**
   - Drag `scenes/enemies/goblin.tscn` into level
   - Drag `scenes/enemies/bat.tscn` into level
   - Drag `scenes/enemies/cannon.tscn` into level

3. **For enemies with patrol:**
   - Add 2-3 Node3D nodes as waypoints
   - Select enemy → Inspector → Patrol Points
   - Drag waypoint nodes into array

4. **Run level:** F6

5. **Test:**
   - [ ] Jump on goblin's head - should damage it
   - [ ] Player bounces after jump attack
   - [ ] Hearts show in top-left (3 filled hearts)
   - [ ] Taking damage decreases hearts
   - [ ] Combo counter appears after 2+ kills
   - [ ] Coins increase on enemy death

---

## ☑️ Step 4: Test Boss Fight (10 minutes)

1. **Create boss arena level** OR add to combat showcase:
   - Instance `scenes/bosses/goblin_king.tscn`
   - Position boss in open area
   - Add some platforms around boss

2. **Run level:** F6

3. **Test boss:**
   - [ ] Boss has 10 HP
   - [ ] Boss throws bombs at player
   - [ ] Bombs arc through the air
   - [ ] Bombs explode on impact
   - [ ] Phase 2 at 7 HP: spawns minions
   - [ ] Phase 3 at 4 HP: faster attacks

---

## ☑️ Step 5: Fix Any Issues

### Common Problems

**"Player doesn't take damage from enemies"**
- Check collision layers are configured
- Verify player has HealthComponent node
- Check player is in "player" group (Node → Groups)

**"Can't jump on enemies"**
- Enemies need Hurtbox (Area3D) child node
- Check Hurtbox collision shape exists

**"Bombs don't spawn"**
- Verify `scenes/projectiles/bomb.tscn` exists
- Check console for errors

**"Hearts don't show"**
- Verify `assets/ui/heart_full.svg` exists
- Check HUD scene has HeartsContainer (HBoxContainer)

---

## ✅ Done!

Once all 5 steps are complete and tested, Phase 2 is ready!

**Next:** Proceed to Phase 3 (Collectibles & Economy System)

---

## 📂 Quick Reference

**Key Files:**
- Health: `scripts/components/health_component.gd`
- Enemies: `scripts/enemies/*.gd`
- Boss: `scripts/bosses/goblin_king.gd`
- Projectiles: `scripts/projectiles/*.gd`

**Documentation:**
- Full guide: `PHASE_2_SETUP_GUIDE.md`
- Fix summary: `PHASE_2_FIXES_SUMMARY.md`
- Testing: See PHASE_2_SETUP_GUIDE.md "Testing Checklist"

**Need Help?**
- Check troubleshooting in PHASE_2_SETUP_GUIDE.md
- All enemy scenes inherit from `base_enemy.tscn`
- Console errors will show missing nodes/scenes
