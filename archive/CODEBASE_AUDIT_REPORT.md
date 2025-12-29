# Codebase Audit Report: Suspicious Patterns & Refactor Issues

**Date**: 2025-12-28  
**Purpose**: Comprehensive audit for suspicious patterns, duplicates, and refactor leftovers

---

## 🔴 Critical Issues Found

### 1. Backup Files in Production Directory
**Location**: `scripts/systems/`
- ❌ `player_stats.gd.backup` - Should be removed
- ❌ `player_stats.gd.bak` - Should be removed
- ❌ `player_stats_backup.gd.uid` - Orphaned UID file
- ❌ `resource_manager_backup.gd.uid` - Orphaned UID file

**Impact**: Clutters codebase, potential confusion
**Action**: Delete these files

---

### 2. Orphaned UID Files (Dead References)
**Location**: Various directories
- ❌ `scripts/systems/player/base_stat_leveling.gd.uid` - System was removed, UID remains
- ❌ `scripts/ui/health_bar.gd.uid` - File doesn't exist
- ❌ `scripts/ui/quick_belt_tab.gd.uid` - File doesn't exist

**Impact**: Godot may show warnings, clutters file system
**Action**: Delete orphaned UID files

---

### 3. Duplicate Constants Files (VERIFIED - Unused)
**Location**: `scripts/`
- ⚠️ `scripts/constants.gd` - Old constants file (FireballConfig) - **NOT USED ANYWHERE**
- ✅ `scripts/constants/game_constants.gd` - New organized location

**Issue**: `constants.gd` contains `FireballConfig` class but is not imported/used anywhere in the codebase.

**Action**: 
- ✅ **SAFE TO DELETE** - `constants.gd` is unused
- Remove `scripts/constants.gd` and `scripts/constants.gd.uid`

---

## ⚠️ Potential Duplications

### 4. Damage Calculation Methods (VERIFIED - Correct Delegation)
**Found in:**
1. `scripts/systems/player/player_stats.gd` - `calculate_damage_reduction()` ✅ **DELEGATES** to StatFormulas
2. `scripts/systems/combat/combat_system.gd` - `calculate_damage_reduction()` ✅ **DELEGATES** to StatFormulas
3. `scripts/utils/stats/stat_formulas.gd` - `calculate_damage_reduction()` ✅ **ACTUAL IMPLEMENTATION**

**Analysis**: ✅ **CORRECT** - Both PlayerStats and CombatSystem delegate to StatFormulas utility function. This is the correct pattern:
- PlayerStats (facade) → StatFormulas (utility)
- CombatSystem (system) → StatFormulas (utility)
- StatFormulas (utility) → Actual implementation

**Status**: ✅ No action needed - delegation is correct

---

### 5. Equipment Stat/Damage Calculations (DUPLICATE CODE FOUND)
**Found in:**
1. `scripts/systems/inventory/inventory_system.gd` - ❌ **DUPLICATES** all three methods:
   - `get_total_stat_bonus()` (lines 328-346)
   - `get_total_damage_bonus()` (lines 349-356)
   - `get_total_damage_percentage()` (lines 359-365)
2. `scripts/utils/stats/equipment_stat_calculator.gd` - ✅ **UTILITY IMPLEMENTATION** (same logic)

**Analysis**: ❌ **ISSUE** - InventorySystem has duplicate implementations instead of delegating to EquipmentStatCalculator. This violates DRY principle.

**Current Code (Duplicate):**
```gdscript
# InventorySystem.gd - DUPLICATE
func get_total_stat_bonus(stat_name: String) -> int:
    var total: int = 0
    for slot_name in equipment:
        var item: EquipmentData = equipment[slot_name]
        if item != null:
            match stat_name:
                StatConstants.STAT_RESILIENCE, "str":
                    total += item.resilience_bonus
                # ... etc
    return total

func get_total_damage_bonus() -> int:
    var total: int = 0
    for slot_name in equipment:
        var item: EquipmentData = equipment[slot_name]
        if item != null:
            total += item.flat_damage_bonus
    return total
```

**Should Be (Delegation):**
```gdscript
# InventorySystem.gd - DELEGATE
func get_total_stat_bonus(stat_name: String) -> int:
    return EquipmentStatCalculator.get_total_stat_bonus(equipment, stat_name)

func get_total_damage_bonus() -> int:
    return EquipmentStatCalculator.get_total_damage_bonus(equipment)

func get_total_damage_percentage() -> float:
    return EquipmentStatCalculator.get_total_damage_percentage(equipment)
```

**Action**: Refactor InventorySystem to delegate to EquipmentStatCalculator (follows DRY principle, reduces code by ~30 lines)

---

## 📝 TODO Comments Found

### 6. Incomplete Implementations
**Location**: `scripts/state/game_state.gd`
- `# TODO: Implement inventory sync:` (line 54)

**Location**: `scripts/ui/bars/tool_belt.gd`
- `# TODO: Implement item usage logic (consumables, potions, etc.)` (line 67)

**Location**: `scripts/resources/merchant_data.gd`
- `## TODO: Implement when milestone 5 (Currency & Merchant) is reached` (line 4)

**Action**: These are expected for incomplete milestones, but should be tracked

---

## 🔍 Suspicious Patterns

### 7. Old Stat Name References in Comments
**Found in:**
- `scripts/systems/player/player_stats.gd` - Comments mention "Formerly base_str", "Formerly base_dex"
- `scripts/systems/player/xp_leveling_system.gd` - May have old references
- `scripts/data/equipment_data.gd` - Comments mention "Formerly str_bonus", "Formerly dex_bonus"

**Analysis**: These are documentation comments explaining the rename, which is fine. But verify no actual code uses old names.

**Action**: Verify no actual code uses `str_bonus`, `dex_bonus`, `base_str`, `base_dex` (only comments)

---

### 8. Files in Root Scripts Directory
**Location**: `scripts/`
- `scripts/constants.gd` - Should be in `scripts/constants/` or removed
- `scripts/stat_constants.gd` - Should be in `scripts/constants/` for consistency

**Action**: Consider moving `stat_constants.gd` to `scripts/constants/stat_constants.gd` for consistency

---

### 9. Direct Load() Calls vs ResourceManager
**Found**: Multiple files use `load()` directly instead of `ResourceManager`:
- `scripts/ui/slots/spell_slot.gd` - `load(icon_path)`
- `scripts/ui/slots/equip_slot.gd` - `load(icon_path)`
- `scripts/ui/rows/base_stat_row.gd` - `load(icon_path)`
- `scripts/systems/resources/game_balance.gd` - `load(DEFAULT_CONFIG_PATH)`
- `scripts/systems/combat/enemy_respawn_manager.gd` - `load("res://scenes/enemies/orc_1.tscn")`

**Issue**: SPEC.md says "All resource loading should go through ResourceManager"

**Action**: 
- For icons/textures: May be acceptable (small resources, frequent access)
- For scenes: Should use ResourceManager
- For config: Should use ResourceManager

---

## ✅ Good Patterns Found

### 10. Consistent Use of StatConstants
**Status**: ✅ Good - No magic strings found for stat names
- All code uses `StatConstants.STAT_RESILIENCE`, `StatConstants.STAT_AGILITY`, etc.

### 11. Hierarchical Organization
**Status**: ✅ Good - Files are properly organized in subdirectories
- Systems organized by domain (combat/, inventory/, movement/, etc.)
- UI organized by type (bars/, slots/, tabs/, etc.)
- Utils organized by domain (combat/, stats/, cooldowns/, etc.)

### 12. Base Classes Used Consistently
**Status**: ✅ Good - BaseEntity and BaseWorker used properly
- Player and Enemy extend BaseEntity
- Workers extend BaseWorker

---

## 📋 Recommended Actions

### Immediate (Cleanup)
1. **Delete backup files:**
   ```bash
   rm scripts/systems/player_stats.gd.backup
   rm scripts/systems/player_stats.gd.bak
   rm scripts/systems/player_stats_backup.gd.uid
   rm scripts/systems/resource_manager_backup.gd.uid
   ```

2. **Delete orphaned UID files:**
   ```bash
   rm scripts/systems/player/base_stat_leveling.gd.uid
   rm scripts/ui/health_bar.gd.uid
   rm scripts/ui/quick_belt_tab.gd.uid
   ```

### Short-term (Verification)
3. **Verify damage calculation delegation:**
   - Check if `PlayerStats.calculate_damage_reduction()` delegates to `CombatSystem`
   - Check if `InventorySystem.get_total_damage_bonus()` delegates to `EquipmentStatCalculator`
   - If not delegating, fix to follow facade pattern

4. **Verify constants.gd usage:**
   - Check if `FireballConfig` from `constants.gd` is still used
   - If used, decide: move to `constants/` or keep in root
   - If unused, remove

5. **Consider moving stat_constants.gd:**
   - Move to `scripts/constants/stat_constants.gd` for consistency
   - Update all imports

### Medium-term (Improvements)
6. **Resource loading consistency:**
   - Consider using ResourceManager for all resource loads
   - Or document exceptions (e.g., icon loading can be direct)

7. **Track TODOs:**
   - Create issue tracker for TODO comments
   - Link to milestones

---

## 🔍 Detailed Findings

### Backup Files Analysis
```
scripts/systems/
├── player_stats.gd.backup (644 lines - old version)
├── player_stats.gd.bak (573 lines - old version)
├── player_stats_backup.gd.uid (orphaned)
└── resource_manager_backup.gd.uid (orphaned)
```

**Recommendation**: These are from the refactor. Safe to delete if current code works.

---

### Damage Calculation Analysis

**PlayerStats.calculate_damage_reduction():**
- Should delegate to `CombatSystem.calculate_damage_reduction()`
- If it does, this is correct facade pattern
- If it doesn't, it's duplicate code

**CombatSystem.calculate_damage_reduction():**
- Should be the actual implementation
- May delegate to `StatFormulas.calculate_damage_reduction()`

**StatFormulas.calculate_damage_reduction():**
- Utility function for stat calculations
- Should be used by CombatSystem

**Action**: Verify the delegation chain is correct.

---

### Constants Files Analysis

**constants.gd:**
- Contains `FireballConfig` class
- Old location (before reorganization)
- May still be used by projectile system

**constants/game_constants.gd:**
- New organized location
- Contains game-wide constants

**Action**: Check if `FireballConfig` is imported/used anywhere.

---

## Summary

### Critical Issues: 3
1. Backup files in production directory (4 files)
2. Orphaned UID files (3 files)
3. Unused constants file (constants.gd)

### Code Duplications: 1
1. ✅ Damage calculation methods (VERIFIED - correct delegation)
2. ❌ Equipment stat/damage calculations (DUPLICATE - 3 methods need refactor)
   - `get_total_stat_bonus()` - duplicates EquipmentStatCalculator
   - `get_total_damage_bonus()` - duplicates EquipmentStatCalculator
   - `get_total_damage_percentage()` - duplicates EquipmentStatCalculator

### Minor Issues: 3
1. Files in root scripts directory
2. Direct load() calls vs ResourceManager
3. TODO comments (expected for incomplete milestones)

### Good Patterns: 3
1. Consistent StatConstants usage
2. Hierarchical organization
3. Base classes used consistently

---

## Priority Actions

**High Priority:**
1. Delete backup files (5 minutes)
2. Delete orphaned UID files (2 minutes)
3. Delete unused constants.gd (1 minute)
4. Refactor InventorySystem to delegate to EquipmentStatCalculator (20 minutes)
   - Replace `get_total_stat_bonus()` with delegation
   - Replace `get_total_damage_bonus()` with delegation
   - Replace `get_total_damage_percentage()` with delegation
   - Test to ensure functionality unchanged

**Medium Priority:**
5. Consider ResourceManager consistency (30 minutes)

**Low Priority:**
6. Move stat_constants.gd to constants/ (5 minutes + update imports)

---

**Overall Assessment**: Codebase is in good shape. Main issues are cleanup (backup files) and verification (delegation patterns). No critical architectural issues found.

---

**End of Audit Report**

