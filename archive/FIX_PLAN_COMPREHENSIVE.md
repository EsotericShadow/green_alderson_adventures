# Comprehensive Fix Plan: Codebase Cleanup & Refactoring

**Date**: 2025-12-28  
**Purpose**: Fix all issues found in codebase audit

---

## Executive Summary

This plan addresses:
1. **Cleanup**: Backup files, orphaned UID files, unused constants
2. **Code Duplication**: InventorySystem duplicate methods
3. **Constants Migration**: Move useful constants from FireballConfig to proper location

**Estimated Time**: 45-60 minutes total

---

## Issue 1: Why constants.gd Isn't Used

### Analysis

**FireballConfig** (`scripts/constants.gd`) was replaced by **SpellData** resource system:

| FireballConfig Constant | Replaced By | Status |
|------------------------|-------------|--------|
| `DEFAULT_SPEED: 450.0` | `SpellData.projectile_speed` (300.0 default, configurable per spell) | ✅ Better - data-driven |
| `DEFAULT_LIFETIME: 1.5` | Hardcoded in `spell_projectile.gd` as `@export var lifetime: float = 1.5` | ⚠️ Could be in SpellData |
| `DEFAULT_COOLDOWN: 0.8` | `SpellData.cooldown` (0.5 default, configurable per spell) | ✅ Better - data-driven |
| `CAST_DELAY: 0.5` | Not found in codebase | ❌ Unused |
| `COLLISION_LAYER_TERRAIN: 1` | Hardcoded in multiple places (spell_projectile.gd line 34, 166) | ⚠️ Should use constant |
| `COLLISION_LAYER_PROJECTILE: 2` | Not explicitly used | ⚠️ Could be useful |
| `GROUP_FIREBALL: "fireball"` | Used in `spell_projectile.gd` line 129 | ⚠️ Should use constant |
| `GROUP_PLAYER: "player"` | Used in multiple places (spell_projectile.gd, base_enemy.gd) | ⚠️ Should use constant |

### Conclusion

**FireballConfig was replaced by SpellData** - a better, data-driven approach. However:
- Some constants (collision layers, groups) are still hardcoded and should use constants
- `GROUP_PLAYER` is used but hardcoded as string `"player"`

**Action**: 
1. Delete `constants.gd` (unused)
2. Move useful constants (collision layers, groups) to `game_constants.gd`
3. Update code to use constants instead of magic numbers/strings

---

## Fix Plan: Step-by-Step

### Phase 1: Cleanup (10 minutes)

#### Step 1.1: Delete Backup Files
**Files to Delete:**
```bash
scripts/systems/player_stats.gd.backup
scripts/systems/player_stats.gd.bak
scripts/systems/player_stats_backup.gd.uid
scripts/systems/resource_manager_backup.gd.uid
```

**Action:**
```bash
cd "/Users/main/Desktop/GameDev/untitled folder 2"
rm scripts/systems/player_stats.gd.backup
rm scripts/systems/player_stats.gd.bak
rm scripts/systems/player_stats_backup.gd.uid
rm scripts/systems/resource_manager_backup.gd.uid
```

**Verification**: Check that files are deleted
```bash
ls scripts/systems/*.backup scripts/systems/*.bak scripts/systems/*backup*.uid 2>/dev/null || echo "All backup files deleted"
```

---

#### Step 1.2: Delete Orphaned UID Files
**Files to Delete:**
```bash
scripts/systems/player/base_stat_leveling.gd.uid
scripts/ui/health_bar.gd.uid
scripts/ui/quick_belt_tab.gd.uid
```

**Action:**
```bash
rm scripts/systems/player/base_stat_leveling.gd.uid
rm scripts/ui/health_bar.gd.uid
rm scripts/ui/quick_belt_tab.gd.uid
```

**Verification**: Check that files are deleted
```bash
ls scripts/systems/player/base_stat_leveling.gd.uid scripts/ui/health_bar.gd.uid scripts/ui/quick_belt_tab.gd.uid 2>/dev/null || echo "All orphaned UID files deleted"
```

---

#### Step 1.3: Migrate Useful Constants, Then Delete constants.gd

**Step 1.3a: Extract Useful Constants**

From `constants.gd`, these might still be useful:
- `COLLISION_LAYER_TERRAIN: 1` - Used in spell_projectile.gd (hardcoded as part of collision_mask = 9)
- `COLLISION_LAYER_PROJECTILE: 2` - Not currently used, but might be useful
- `GROUP_PLAYER: "player"` - Used in spell_projectile.gd line 114 (hardcoded as string)

**Action**: Add to `scripts/constants/game_constants.gd`:

```gdscript
# Collision Layers
const COLLISION_LAYER_TERRAIN: int = 1
const COLLISION_LAYER_PROJECTILE: int = 2
const COLLISION_LAYER_HITBOX: int = 4
const COLLISION_LAYER_HURTBOX: int = 8

# Groups
const GROUP_PLAYER: StringName = "player"
const GROUP_ENEMY: StringName = "enemy"
const GROUP_FIREBALL: StringName = "fireball"  # Legacy, but still used
```

**Step 1.3b: Update Code to Use Constants**

Update multiple files to use constants:

**`scripts/projectiles/spell_projectile.gd`:**
- Line 34: `collision_mask = 9` → `collision_mask = GameConstants.COLLISION_LAYER_TERRAIN | GameConstants.COLLISION_LAYER_HURTBOX`
- Line 114: `body.is_in_group("player")` → `body.is_in_group(GameConstants.GROUP_PLAYER)`
- Line 129: `area.is_in_group("fireball")` → `area.is_in_group(GameConstants.GROUP_FIREBALL)`
- Line 137: `hurtbox.owner_node.is_in_group("player")` → `hurtbox.owner_node.is_in_group(GameConstants.GROUP_PLAYER)`
- Line 166: `area.collision_layer & 1` → `area.collision_layer & GameConstants.COLLISION_LAYER_TERRAIN`
- Line 211: `body.is_in_group("enemy")` → `body.is_in_group(GameConstants.GROUP_ENEMY)`

**`scripts/enemies/base_enemy.gd`:**
- Line 182: `body.is_in_group("player")` → `body.is_in_group(GameConstants.GROUP_PLAYER)`
- Line 439: `body.is_in_group("player")` → `body.is_in_group(GameConstants.GROUP_PLAYER)`

**`scripts/workers/combat/hurtbox.gd`:**
- Line 19: `collision_layer = 8` → `collision_layer = GameConstants.COLLISION_LAYER_HURTBOX`

**`scripts/workers/combat/hitbox.gd`:**
- Line 17: `collision_layer = 4` → `collision_layer = GameConstants.COLLISION_LAYER_HITBOX`
- Line 18: `collision_mask = 8` → `collision_mask = GameConstants.COLLISION_LAYER_HURTBOX`

**Step 1.3c: Delete constants.gd**

```bash
rm scripts/constants.gd
rm scripts/constants.gd.uid
```

**Verification**: 
- Check that game_constants.gd has the new constants
- Check that spell_projectile.gd uses the constants
- Check that constants.gd is deleted

---

### Phase 2: Code Refactoring (20-30 minutes)

#### Step 2.1: Refactor InventorySystem to Use EquipmentStatCalculator

**Current Issue**: InventorySystem has duplicate implementations of:
- `get_total_stat_bonus()` (lines 328-346)
- `get_total_damage_bonus()` (lines 349-356)
- `get_total_damage_percentage()` (lines 359-365)

**Action**: Replace with delegation to EquipmentStatCalculator

**Before:**
```gdscript
func get_total_stat_bonus(stat_name: String) -> int:
    var total: int = 0
    for slot_name in equipment:
        var item: EquipmentData = equipment[slot_name]
        if item != null:
            match stat_name:
                StatConstants.STAT_RESILIENCE, "str":
                    total += item.resilience_bonus
                StatConstants.STAT_AGILITY, "dex":
                    total += item.agility_bonus
                StatConstants.STAT_INT:
                    total += item.int_bonus
                StatConstants.STAT_VIT:
                    total += item.vit_bonus
    return total

func get_total_damage_bonus() -> int:
    var total: int = 0
    for slot_name in equipment:
        var item: EquipmentData = equipment[slot_name]
        if item != null:
            total += item.flat_damage_bonus
    return total

func get_total_damage_percentage() -> float:
    var total: float = 0.0
    for slot_name in equipment:
        var item: EquipmentData = equipment[slot_name]
        if item != null:
            total += item.damage_percentage_bonus
    return total
```

**After:**
```gdscript
func get_total_stat_bonus(stat_name: String) -> int:
    """Returns sum of stat bonuses from all equipped items.
    
    Args:
        stat_name: StatConstants.STAT_RESILIENCE, STAT_AGILITY, STAT_INT, or STAT_VIT
                   (also supports "str"/"dex" for backwards compatibility)
    
    Returns: Total stat bonus from all equipped items
    """
    return EquipmentStatCalculator.get_total_stat_bonus(equipment, stat_name)


func get_total_damage_bonus() -> int:
    """Returns sum of flat damage bonuses from all equipped items."""
    return EquipmentStatCalculator.get_total_damage_bonus(equipment)


func get_total_damage_percentage() -> float:
    """Returns sum of percentage damage bonuses from all equipped items."""
    return EquipmentStatCalculator.get_total_damage_percentage(equipment)
```

**Benefits:**
- Reduces code by ~30 lines
- Follows DRY principle
- Single source of truth for equipment calculations
- Easier to maintain and test

**Testing**: 
- Test equipping items
- Test stat bonuses apply correctly
- Test damage bonuses apply correctly
- Verify all existing functionality works

---

### Phase 3: Verification (10 minutes)

#### Step 3.1: Build & Test
1. **Build project**: Ensure no compilation errors
2. **Run system validator**: All 36 tests should pass
3. **Manual test**: 
   - Test inventory system
   - Test equipment system
   - Test spell projectiles (verify collision still works)
   - Test player group detection

#### Step 3.2: Code Review
- Verify no broken references
- Verify constants are used consistently
- Verify delegation works correctly

---

## Detailed Implementation Steps

### Step 1: Update game_constants.gd

**File**: `scripts/constants/game_constants.gd`

**Current Content:**
```gdscript
extends RefCounted
class_name GameConstants
## Non-balance game constants (technical/visual/animation values).
## Balance-related constants should be in GameBalanceConfig.

# Screen shake
const SCREEN_SHAKE_RATE: int = 30  # Shakes per second
```

**Add:**
```gdscript
extends RefCounted
class_name GameConstants
## Non-balance game constants (technical/visual/animation values).
## Balance-related constants should be in GameBalanceConfig.

# Screen shake
const SCREEN_SHAKE_RATE: int = 30  # Shakes per second

# Collision Layers
const COLLISION_LAYER_TERRAIN: int = 1
const COLLISION_LAYER_PROJECTILE: int = 2
const COLLISION_LAYER_HITBOX: int = 4
const COLLISION_LAYER_HURTBOX: int = 8

# Groups
const GROUP_PLAYER: StringName = "player"
const GROUP_ENEMY: StringName = "enemy"
```

---

### Step 2: Update Multiple Files to Use Constants

#### Step 2.1: Update spell_projectile.gd

**File**: `scripts/projectiles/spell_projectile.gd`

**Line 34 - Change:**
```gdscript
# Before:
collision_mask = 9  # Layer 1 (terrain) + Layer 8 (hurtbox) = 1 + 8 = 9

# After:
collision_mask = GameConstants.COLLISION_LAYER_TERRAIN | GameConstants.COLLISION_LAYER_HURTBOX
```

**Multiple lines to update:**

**Line 34:**
```gdscript
# Before:
collision_mask = 9  # Layer 1 (terrain) + Layer 8 (hurtbox) = 1 + 8 = 9

# After:
collision_mask = GameConstants.COLLISION_LAYER_TERRAIN | GameConstants.COLLISION_LAYER_HURTBOX
```

**Line 114:**
```gdscript
# Before:
if body == owner_node or body.is_in_group("player"):

# After:
if body == owner_node or body.is_in_group(GameConstants.GROUP_PLAYER):
```

**Line 129:**
```gdscript
# Before:
if area.is_in_group("fireball"):

# After:
if area.is_in_group(GameConstants.GROUP_FIREBALL):
```

**Line 137:**
```gdscript
# Before:
if hurtbox.owner_node == owner_node or hurtbox.owner_node.is_in_group("player"):

# After:
if hurtbox.owner_node == owner_node or hurtbox.owner_node.is_in_group(GameConstants.GROUP_PLAYER):
```

**Line 166:**
```gdscript
# Before:
if area.collision_layer & 1:  # Layer 1 = terrain

# After:
if area.collision_layer & GameConstants.COLLISION_LAYER_TERRAIN:
```

**Line 211:**
```gdscript
# Before:
if body.is_in_group("enemy"):

# After:
if body.is_in_group(GameConstants.GROUP_ENEMY):
```

---

#### Step 2.2: Update base_enemy.gd

**File**: `scripts/enemies/base_enemy.gd`

**Line 182:**
```gdscript
# Before:
if body.is_in_group("player"):

# After:
if body.is_in_group(GameConstants.GROUP_PLAYER):
```

**Line 439:**
```gdscript
# Before:
if body.is_in_group("player"):

# After:
if body.is_in_group(GameConstants.GROUP_PLAYER):
```

#### Step 2.3: Update hurtbox.gd

**File**: `scripts/workers/combat/hurtbox.gd`

**Line 19:**
```gdscript
# Before:
collision_layer = 8

# After:
collision_layer = GameConstants.COLLISION_LAYER_HURTBOX
```

#### Step 2.4: Update hitbox.gd

**File**: `scripts/workers/combat/hitbox.gd`

**Line 17:**
```gdscript
# Before:
collision_layer = 4

# After:
collision_layer = GameConstants.COLLISION_LAYER_HITBOX
```

**Line 18:**
```gdscript
# Before:
collision_mask = 8

# After:
collision_mask = GameConstants.COLLISION_LAYER_HURTBOX
```

---

### Step 3: Refactor InventorySystem

**File**: `scripts/systems/inventory/inventory_system.gd`

**Replace lines 328-365 with:**
```gdscript
func get_total_stat_bonus(stat_name: String) -> int:
    """Returns sum of stat bonuses from all equipped items.
    
    Args:
        stat_name: StatConstants.STAT_RESILIENCE, STAT_AGILITY, STAT_INT, or STAT_VIT
                   (also supports "str"/"dex" for backwards compatibility)
    
    Returns: Total stat bonus from all equipped items
    """
    return EquipmentStatCalculator.get_total_stat_bonus(equipment, stat_name)


func get_total_damage_bonus() -> int:
    """Returns sum of flat damage bonuses from all equipped items."""
    return EquipmentStatCalculator.get_total_damage_bonus(equipment)


func get_total_damage_percentage() -> float:
    """Returns sum of percentage damage bonuses from all equipped items."""
    return EquipmentStatCalculator.get_total_damage_percentage(equipment)
```

---

## Testing Checklist

### After Cleanup
- [ ] Project builds without errors
- [ ] No missing file warnings in Godot
- [ ] All systems initialize correctly

### After Constants Migration
- [ ] Spell projectiles collide correctly with terrain
- [ ] Spell projectiles don't hit player
- [ ] No magic numbers in collision code

### After InventorySystem Refactor
- [ ] Equipment stat bonuses apply correctly
- [ ] Equipment damage bonuses apply correctly
- [ ] All existing inventory functionality works
- [ ] System validator tests pass (36 tests)

---

## Rollback Plan

If anything breaks:

1. **Git Checkout**: Restore deleted files
   ```bash
   git checkout HEAD -- scripts/systems/player_stats.gd.backup
   # etc.
   ```

2. **Revert Code Changes**: Use git to revert refactoring
   ```bash
   git diff scripts/systems/inventory/inventory_system.gd
   git checkout HEAD -- scripts/systems/inventory/inventory_system.gd
   ```

3. **Restore Constants**: Re-add constants.gd if needed
   ```bash
   git checkout HEAD -- scripts/constants.gd
   ```

---

## Expected Outcomes

### Code Reduction
- **Backup files**: -4 files
- **Orphaned UID files**: -3 files
- **Unused constants**: -1 file
- **Code duplication**: -30 lines (InventorySystem refactor)

### Code Quality Improvements
- ✅ No backup files cluttering codebase
- ✅ No orphaned references
- ✅ Constants used instead of magic numbers/strings
- ✅ DRY principle followed (no duplicate code)
- ✅ Single source of truth for equipment calculations

### Maintainability Improvements
- ✅ Easier to find constants (all in game_constants.gd)
- ✅ Easier to modify equipment calculations (one place)
- ✅ Better code organization
- ✅ Consistent patterns

---

## Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1.1 | Delete backup files | 2 min | ⏳ Pending |
| 1.2 | Delete orphaned UID files | 1 min | ⏳ Pending |
| 1.3a | Add constants to game_constants.gd | 5 min | ⏳ Pending |
| 1.3b | Update all files to use constants | 15 min | ⏳ Pending |
| 1.3c | Delete constants.gd | 1 min | ⏳ Pending |
| 2.1 | Refactor InventorySystem | 20 min | ⏳ Pending |
| 3.1 | Build & test | 5 min | ⏳ Pending |
| 3.2 | Code review | 5 min | ⏳ Pending |
| **Total** | | **54 min** | |

---

## Notes

### Why FireballConfig Was Replaced

The system evolved from:
- **Old**: Hardcoded constants in FireballConfig
- **New**: Data-driven SpellData resources

**Benefits of SpellData:**
- Each spell can have different speed/cooldown
- Easy to create new spells without code changes
- Better balance control (per-spell configuration)
- More flexible and maintainable

**What Was Lost:**
- Collision layer constants (now hardcoded in multiple files)
- Group constants (now hardcoded strings in multiple files)

**Current State:**
- Collision layers hardcoded in: spell_projectile.gd, hurtbox.gd, hitbox.gd
- Group strings hardcoded in: spell_projectile.gd, base_enemy.gd

**Solution**: Move collision/group constants to game_constants.gd and update all files to use them. This improves:
- Maintainability (change in one place)
- Type safety (constants vs strings)
- Consistency (all files use same values)

---

## Success Criteria

✅ All backup files deleted  
✅ All orphaned UID files deleted  
✅ Constants migrated to game_constants.gd  
✅ Code uses constants instead of magic numbers/strings  
✅ InventorySystem delegates to EquipmentStatCalculator  
✅ All tests pass  
✅ No compilation errors  
✅ No broken functionality  

---

**End of Fix Plan**

