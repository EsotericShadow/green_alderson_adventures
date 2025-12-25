# Context File: Spell Hotbar System Implementation

**Date**: Current Session  
**Commit**: 3C - Spell Selection & Hotbar (Complete)  
**Status**: Fully implemented, tested, and refined

---

## Overview

This document provides context for the spell hotbar system implementation (Commit 3C). It documents what was built, how it was implemented, and important context for future development.

**Recent Updates**:
- Element-specific projectile scenes and impacts (no longer hue-shifted)
- Element-specific spell icons with color modulation
- Scene directory reorganization (projectiles/, effects/, characters/, etc.)
- Projectile cleanup system (pooling for fire, queue_free for others)

---

## What Was Implemented

### 1. Spell Hotbar UI System
- **10-slot spell hotbar** (keys 1-9, 0)
- **Visual spell selection** with gold border highlighting
- **Element-specific spell icons** loaded per element (fire, water, earth, air)
- **Click-to-select** functionality
- **Race condition fix**: Pending spells queue for initialization

### 2. Multi-Element Spell System
- **SpellData resources** for each element (fire, water, earth, air)
- **Dynamic damage calculation** based on:
  - Base damage from SpellData
  - Player Intelligence stat (INT * 2)
  - Element level bonus ((level - 1) * 5)
- **Element-specific XP gain** on spell hit
- **Element leveling system** with XP tracking

### 3. Spell Selection & Casting
- **Number key selection** (1-9, 0) for spell slots
- **Visual feedback** when selecting spells
- **Dynamic mana cost** and cooldown per spell
- **Element-specific projectiles** (each element has its own scene)
- **Element-specific impact effects** (each element has its own impact scene)

---

## How It Was Implemented

### File Structure

```
scripts/
├── resources/
│   └── spell_data.gd              # SpellData resource class (moved from data/)
├── systems/
│   └── spell_system.gd            # Autoload singleton for spell progression
├── ui/
│   ├── spell_bar.gd               # Main hotbar controller
│   └── spell_slot.gd              # Individual slot component
├── player.gd                      # Player coordinator (modified)
└── projectiles/
    └── spell_projectile.gd        # Generic projectile script (renamed from fireball.gd)

scenes/
├── projectiles/                   # Projectile scenes
│   ├── fireball.tscn             # Fire projectile scene
│   ├── waterball.tscn            # Water projectile scene
│   ├── earthball.tscn            # Earth projectile scene
│   └── airball.tscn              # Air projectile scene
├── effects/                       # Impact effect scenes
│   ├── fire_impact.tscn          # Fire impact effect
│   ├── water_impact.tscn         # Water impact effect
│   ├── earth_impact.tscn         # Earth impact effect
│   └── air_impact.tscn           # Air impact effect
└── ui/
    ├── spell_bar.tscn            # Hotbar scene (CanvasLayer)
    └── spell_slot.tscn           # Individual slot scene

resources/
└── spells/
    ├── fireball.tres             # Fire spell resource
    ├── waterball.tres            # Water spell resource
    ├── earthball.tres            # Earth spell resource
    └── airball.tres              # Air spell resource
```

### Key Components

#### 1. SpellData Resource (`scripts/resources/spell_data.gd`)
- Custom resource class defining spell properties
- **Location**: Moved from `scripts/data/` to `scripts/resources/` during reorganization
- Properties: `id`, `display_name`, `description`, `icon`, `element`, `base_damage`, `mana_cost`, `cooldown`, `hue_shift`, `projectile_speed`
- Used as data containers for spell definitions

#### 2. SpellSystem Autoload (`scripts/systems/spell_system.gd`)
- **Purpose**: Manages elemental spell progression and damage calculation
- **Key Features**:
  - Tracks XP and levels for each element separately
  - Calculates spell damage: `base_damage + (INT * 2) + ((level - 1) * 5)`
  - Validates spell casting (mana check)
  - Emits signals for XP gain and level-ups
- **Initialization**: All elements start at level 1, 0 XP
- **XP Formula**: `XP_PER_LEVEL_MULTIPLIER * level` (currently 100)

#### 3. SpellBar UI (`scripts/ui/spell_bar.gd` + `scenes/ui/spell_bar.tscn`)
- **Type**: CanvasLayer (layer = 19, below inventory layer 20)
- **Structure**:
  - Root: `CanvasLayer` (SpellBar)
  - Child: `Control` (positioning/anchor)
  - Child: `HBoxContainer` (slot container)
- **Functionality**:
  - Creates 10 `SpellSlot` instances
  - Manages selection state
  - Connects to player for spell setup
  - Emits `spell_selected` signal
- **Race Condition Fix**: Implements `_pending_spells` queue to handle spells arriving before `_ready()` completes

#### 4. SpellSlot Component (`scripts/ui/spell_slot.gd` + `scenes/ui/spell_slot.tscn`)
- **Type**: PanelContainer with `class_name SpellSlot`
- **Features**:
  - Displays element-specific spell icons
  - Shows key label (1-9, 0)
  - Selection highlighting (gold border)
- **Icon Loading**: Loads element-specific icon files:
  - `spell_icon_lvl_1(red).png` for fire
  - `spell_icon_lvl_1(cyan).png` for water
  - `spell_icon_lvl_1(green).png` for earth
  - `spell_icon_lvl_1(lightblue).png` for air
- **Fallback**: Falls back to blue icon with color modulation if element-specific icon not found
- **Theme Override**: Uses `get_theme_stylebox()` and `add_theme_stylebox_override()` for border color

#### 5. Player Integration (`scripts/player.gd`)
- **New Variables**:
  - `equipped_spells: Array[SpellData]` (size 10)
  - `selected_spell_index: int`
  - `spell_bar: Node` (reference to UI CanvasLayer)
- **New Methods**:
  - `get_selected_spell() -> SpellData`
  - `_select_spell(index: int)`
  - `_find_spell_bar()`
- **Modified Methods**:
  - `_ready()`: Loads default spells, finds spell bar
  - `_physics_process()`: Handles spell selection via number keys
  - `_can_cast()`: Uses spell's mana cost
  - `_start_fireball_cast()`: Uses spell's cooldown
  - `_spawn_fireball()`: Passes SpellData to spawner

#### 6. Projectile System (`scripts/projectiles/spell_projectile.gd`)
- **Renamed**: From `fireball.gd` to `spell_projectile.gd` (element-agnostic)
- **Properties**:
  - `spell_data: SpellData` property
  - `impact_scene: PackedScene` (element-specific impact scene)
- **Dynamic Damage**: Uses `SpellSystem.get_spell_damage(spell_data)`
- **XP Gain**: `SpellSystem.gain_xp(spell_data.element, max(1, int(final_damage / 2.0)))` on hit
- **Visual**: Each projectile scene uses pre-colored sprites (no hue shift)
- **Cleanup**: 
  - Fire projectiles return to pool
  - Other elements use `queue_free()`

#### 7. Impact System (`scripts/projectiles/impact.gd`)
- **Dynamic Animation**: Determines animation name based on element
  - `fireball_impact_left`, `waterball_impact_left`, etc.
- **Element-specific**: Each impact scene has element-specific animations

#### 8. Spell Spawner (`scripts/workers/spell_spawner.gd`)
- **Modified `spawn_fireball()`**: Loads element-specific projectile scenes
  - `fireball.tscn` for fire
  - `waterball.tscn` for water
  - `earthball.tscn` for earth
  - `airball.tscn` for air
- **Pooling**: Only uses pool for fire element (pool pre-filled with fireballs)
- **Instantiation**: Other elements instantiate directly from scene

---

## Technical Details

### Z-Index/Layer System
- **HUD**: CanvasLayer layer = 10 (health, mana, stamina bars)
- **Spell Bar**: CanvasLayer layer = 19 (above game, below inventory)
- **Inventory**: CanvasLayer layer = 20 (topmost UI)

### Input Actions
- `spell_1` through `spell_9`: Keys 1-9
- `spell_0`: Key 0
- All mapped in `project.godot`

### Spell Resources
- **Fireball**: `base_damage=15`, `mana_cost=10`, `cooldown=0.6`, `hue_shift=0.0`
- **Waterball**: `base_damage=12`, `mana_cost=12`, `cooldown=0.7`, `hue_shift=0.5` (cyan)
- **Earthball**: `base_damage=20`, `mana_cost=15`, `cooldown=0.9`, `hue_shift=0.3` (green)
- **Airball**: `base_damage=10`, `mana_cost=8`, `cooldown=0.4`, `hue_shift=0.55` (light blue)

### Element Colors
- **Fire**: Red (RGB: 1.0, 0.2, 0.2)
- **Water**: Cyan (HSV: 0.5, 1.0, 1.0)
- **Earth**: Green (HSV: 0.3, 1.0, 1.0)
- **Air**: Light Blue (HSV: 0.55, 1.0, 1.0)

### Damage Formula
```
final_damage = base_damage + (PlayerStats.get_total_int() * 2) + ((element_level - 1) * 5)
```

### XP Gain Formula
```
xp_gained = max(1, int(final_damage / 2.0))
```
Note: Uses float division then casts to int to avoid integer division warnings.

---

## Current State

### ✅ Completed
- Spell hotbar UI with 10 slots
- Multi-element spell system (fire, water, earth, air)
- Spell selection via number keys
- Visual selection highlighting
- Element-specific icons, projectiles, and impacts
- Element-specific XP and leveling
- Dynamic damage calculation
- SpellSystem autoload singleton
- Projectile cleanup system (pooling + queue_free)
- Scene directory reorganization

### ⚠️ Known Issues / Incomplete
- **Default spells**: Currently hardcoded in `player.gd` `_ready()`
- **Spell unlocking**: No system for unlocking new spells yet
- **Spell bar visibility**: Always visible (no toggle)

### 🔧 Recent Fixes
- Fixed race condition in spell bar initialization (pending spells queue)
- Fixed integer division warnings (use float division then cast)
- Fixed variable shadowing warning in `base_enemy.gd`
- Fixed UI size override warnings (use `set_deferred()`)
- Organized scenes directory into logical subdirectories
- Removed unused script files and directories
- Created stub classes for ItemData, EquipmentData, MerchantData

---

## Important Context

### Design Decisions
1. **Element-based progression**: Each element levels independently (not a general "magic" skill)
2. **Element-specific assets**: Each element has its own projectile scene, impact scene, and icon (no longer hue-shifted)
3. **10-slot hotbar**: Matches standard RPG conventions (1-9, 0)
4. **CanvasLayer separation**: Spell bar is separate from HUD for proper z-ordering
5. **Projectile pooling**: Only fire projectiles use the pool (others instantiate directly)

### Code Patterns
- **Worker pattern**: Player coordinator delegates to workers (spell_spawner, etc.)
- **Signal-based communication**: Spell bar emits `spell_selected`, player connects
- **Resource-based data**: Spells defined as `.tres` resources for easy editing
- **Autoload singletons**: SpellSystem, PlayerStats, EventBus, InventorySystem
- **Scene organization**: Logical subdirectories (projectiles/, effects/, characters/, etc.)

### Asset Requirements
- **Spell icons**: Element-specific files in `assets/animations/UI/spell_hotbar_icons/spell_ball_blast/`
  - `spell_icon_lvl_1(red).png` (fire)
  - `spell_icon_lvl_1(cyan).png` (water)
  - `spell_icon_lvl_1(green).png` (earth)
  - `spell_icon_lvl_1(lightblue).png` (air)
- **Projectile scenes**: Element-specific scenes in `scenes/projectiles/`
- **Impact scenes**: Element-specific scenes in `scenes/effects/`

---

## Next Steps / Future Work

### Immediate (if needed)
1. Spell unlocking system
2. Spell bar toggle (show/hide)
3. Spell tooltips/descriptions in UI

### Short-term
1. Spell level display in hotbar
2. Multiple spell types per element
3. Cooldown visualization improvements

### Long-term
1. Spell crafting/upgrading
2. Spell combinations
3. Elemental resistances/weaknesses
4. Spell mastery bonuses

---

## Key Files to Review

### Critical Files
- `scripts/systems/spell_system.gd` - Core spell progression logic
- `scripts/ui/spell_bar.gd` - Hotbar UI controller
- `scripts/player.gd` - Player spell selection and casting
- `scripts/projectiles/spell_projectile.gd` - Generic projectile script
- `scripts/workers/spell_spawner.gd` - Element-specific projectile spawning

### Resource Files
- `resources/spells/*.tres` - Spell definitions
- `scenes/ui/spell_bar.tscn` - Hotbar scene
- `scenes/ui/spell_slot.tscn` - Slot scene
- `scenes/projectiles/*.tscn` - Projectile scenes
- `scenes/effects/*.tscn` - Impact effect scenes

### Configuration
- `project.godot` - Input actions, autoloads

---

## Testing Notes

### What to Test
1. Spell selection via number keys (1-9, 0)
2. Visual selection highlighting (gold border)
3. Spell casting with different elements
4. XP gain on hit (check logs for `[SPELL_SYSTEM] ✨ Fire gained X XP`)
5. Damage calculation (should increase with INT and level)
6. Element-specific icons, projectiles, and impacts
7. Z-index ordering (spell bar above game, below inventory)
8. Projectile cleanup (fire returns to pool, others are freed)

### Logging
- SpellSystem logs all XP gains, level-ups, and damage calculations
- Player logs spell selection and casting
- Look for `[SPELL_SYSTEM]` and `[PLAYER]` prefixes

---

## Troubleshooting

### Common Issues
1. **Spell bar not appearing**: Check CanvasLayer layer and node path in player script
2. **Icons not loading**: Verify asset path in `_load_spell_icon()` - check element-specific files exist
3. **No XP gain**: Check that `SpellSystem.gain_xp()` is called in `spell_projectile.gd`
4. **Wrong damage**: Verify INT stat and element level in SpellSystem
5. **Selection not working**: Check signal connections in `_find_spell_bar()`
6. **Projectiles not cleaning up**: Check element type - only fire uses pool

### Debug Commands
- Check spell bar: `get_tree().current_scene.get_node("SpellBar")`
- Check SpellSystem: `SpellSystem.get_level("fire")`
- Check player spells: `get_tree().get_first_node_in_group("player").equipped_spells`

---

## Commit History Context

- **Latest**: Scene reorganization and compilation fixes
- **Commit 3C**: Spell Selection & Hotbar (complete)
- **Commit 3B**: Multi-Element Projectiles (element-specific assets)
- **Commit 3A**: Spell System Foundation
- Previous commits: Inventory, Equipment, UI systems

---

## Notes for New Agent

1. **Do NOT commit/push** unless explicitly asked by user
2. **Follow SPEC.md** for standardization
3. **Use existing patterns**: Worker pattern, signal-based communication
4. **Test thoroughly** before suggesting completion
5. **Check logs** for debugging (comprehensive logging is in place)
6. **Respect z-index layers**: HUD=10, SpellBar=19, Inventory=20
7. **Element independence**: Each element levels separately
8. **Asset organization**: Element-specific assets (not hue-shifted)
9. **Scene organization**: Use logical subdirectories (projectiles/, effects/, etc.)
10. **Race conditions**: Use pending queues if initialization order matters

---

**End of Context File**
