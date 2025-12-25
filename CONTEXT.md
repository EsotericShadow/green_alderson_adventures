# Context File: Spell Hotbar System Implementation

**Date**: Current Session  
**Commit**: 3C - Spell Selection & Hotbar  
**Status**: Implemented and tested

---

## Overview

This document provides context for the spell hotbar system implementation (Commit 3C). It documents what was built, how it was implemented, and important context for future development.

---

## What Was Implemented

### 1. Spell Hotbar UI System
- **10-slot spell hotbar** (keys 1-9, 0)
- **Visual spell selection** with gold border highlighting
- **Hue-shifted spell icons** based on element
- **Cooldown overlay** visualization (not yet fully integrated)
- **Click-to-select** functionality

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
- **Hue-shifted projectiles** matching spell element

---

## How It Was Implemented

### File Structure

```
scripts/
├── data/
│   └── spell_data.gd              # SpellData resource class
├── systems/
│   └── spell_system.gd            # Autoload singleton for spell progression
├── ui/
│   ├── spell_bar.gd               # Main hotbar controller
│   └── spell_slot.gd              # Individual slot component
├── player.gd                      # Player coordinator (modified)
└── projectiles/
    └── fireball.gd               # Projectile script (modified for multi-element)

scenes/
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

#### 1. SpellData Resource (`scripts/data/spell_data.gd`)
- Custom resource class defining spell properties
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

#### 4. SpellSlot Component (`scripts/ui/spell_slot.gd` + `scenes/ui/spell_slot.tscn`)
- **Type**: PanelContainer with `class_name SpellSlot`
- **Features**:
  - Displays spell icon with hue shift
  - Shows key label (1-9, 0)
  - Cooldown overlay (ColorRect)
  - Selection highlighting (gold border)
- **Icon Loading**: Uses `spell_icon_lvl_1(blue).png` with hue modulation
- **Theme Override**: Uses `get_theme_stylebox()` and `add_theme_stylebox_override()` for border color

#### 5. Player Integration (`scripts/player.gd`)
- **New Variables**:
  - `equipped_spells: Array[SpellData]` (size 10)
  - `selected_spell_index: int`
  - `spell_bar: Control` (reference to UI)
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

#### 6. Projectile System (`scripts/projectiles/fireball.gd`)
- **Modified to accept SpellData**:
  - `spell_data: SpellData` property
  - `hue_shift: float` for visual element representation
- **Dynamic Damage**: Uses `SpellSystem.get_spell_damage(spell_data)`
- **XP Gain**: `SpellSystem.gain_xp(spell_data.element, max(1, final_damage / 2))` on hit
- **Visual**: Applies hue shift to `AnimatedSprite2D.modulate`

#### 7. Spell Spawner (`scripts/workers/spell_spawner.gd`)
- **Modified `spawn_fireball()`**: Now accepts `data: SpellData` parameter
- Passes SpellData to fireball's `setup()` method

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
- **Waterball**: `base_damage=12`, `mana_cost=12`, `cooldown=0.7`, `hue_shift=0.55`
- **Earthball**: `base_damage=20`, `mana_cost=15`, `cooldown=0.9`, `hue_shift=0.3`
- **Airball**: `base_damage=10`, `mana_cost=8`, `cooldown=0.4`, `hue_shift=0.75`

### Hue Shift Colors
- **Fire**: 0.0 (red)
- **Water**: 0.55 (cyan)
- **Earth**: 0.3 (brown/green)
- **Air**: 0.75 (light blue)

### Damage Formula
```
final_damage = base_damage + (PlayerStats.get_total_int() * 2) + ((element_level - 1) * 5)
```

### XP Gain Formula
```
xp_gained = max(1, final_damage / 2)
```

---

## Current State

### ✅ Completed
- Spell hotbar UI with 10 slots
- Multi-element spell system (fire, water, earth, air)
- Spell selection via number keys
- Visual selection highlighting
- Hue-shifted icons and projectiles
- Element-specific XP and leveling
- Dynamic damage calculation
- SpellSystem autoload singleton

### ⚠️ Known Issues / Incomplete
- **Cooldown overlay**: Implemented but not fully connected to player cooldown system
- **Spell bar positioning**: May need adjustment based on screen size
- **Default spells**: Currently hardcoded in `player.gd` `_ready()`
- **Spell unlocking**: No system for unlocking new spells yet
- **Spell bar visibility**: Always visible (no toggle)

### 🔧 Recent Fixes
- Fixed `theme_override_styles` access (use `get_theme_stylebox()` / `add_theme_stylebox_override()`)
- Added `class_name SpellSlot` for type recognition
- Fixed duplicate variable declaration in `_start_fireball_cast()`
- Set spell bar z-index to layer 19 (below inventory)

---

## Important Context

### Design Decisions
1. **Element-based progression**: Each element levels independently (not a general "magic" skill)
2. **Hue shifting**: Reuses same assets with color modulation for different elements
3. **10-slot hotbar**: Matches standard RPG conventions (1-9, 0)
4. **CanvasLayer separation**: Spell bar is separate from HUD for proper z-ordering

### Code Patterns
- **Worker pattern**: Player coordinator delegates to workers (spell_spawner, etc.)
- **Signal-based communication**: Spell bar emits `spell_selected`, player connects
- **Resource-based data**: Spells defined as `.tres` resources for easy editing
- **Autoload singletons**: SpellSystem, PlayerStats, EventBus, InventorySystem

### Asset Requirements
- **Spell icons**: `assets/animations/UI/spell_hotbar_icons/spell_ball_blast/spell_icon_lvl_1(blue).png`
- **Projectile animations**: Reuses fireball animation with hue shift
- **Impact effects**: Reuses impact animation with hue shift

---

## Next Steps / Future Work

### Immediate (if needed)
1. Connect cooldown overlay to actual player cooldown timers
2. Add spell bar toggle (show/hide)
3. Test spell selection and casting thoroughly

### Short-term
1. Spell unlocking system
2. Spell tooltips/descriptions in UI
3. Spell level display in hotbar
4. Multiple spell types per element

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
- `scripts/projectiles/fireball.gd` - Projectile with SpellData integration

### Resource Files
- `resources/spells/*.tres` - Spell definitions
- `scenes/ui/spell_bar.tscn` - Hotbar scene
- `scenes/ui/spell_slot.tscn` - Slot scene

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
6. Hue shift on icons and projectiles
7. Z-index ordering (spell bar above game, below inventory)

### Logging
- SpellSystem logs all XP gains, level-ups, and damage calculations
- Player logs spell selection and casting
- Look for `[SPELL_SYSTEM]` and `[PLAYER]` prefixes

---

## Troubleshooting

### Common Issues
1. **Spell bar not appearing**: Check CanvasLayer layer and node path in player script
2. **Icons not loading**: Verify asset path in `_load_spell_icon()`
3. **No XP gain**: Check that `SpellSystem.gain_xp()` is called in `fireball.gd`
4. **Wrong damage**: Verify INT stat and element level in SpellSystem
5. **Selection not working**: Check signal connections in `_find_spell_bar()`

### Debug Commands
- Check spell bar: `get_tree().current_scene.get_node("SpellBar")`
- Check SpellSystem: `SpellSystem.get_level("fire")`
- Check player spells: `get_tree().get_first_node_in_group("player").equipped_spells`

---

## Commit History Context

- **Commit 3C**: Spell Selection & Hotbar (current)
- **Commit 3B**: Multi-Element Projectiles
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
8. **Hue shifting**: Reuse assets with color modulation

---

**End of Context File**

