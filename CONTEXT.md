# Context File: Green Alderson Adventures - Complete System Overview

**Date**: Current Session  
**Last Updated**: After Health Bar Refactor & Stat System Overhaul  
**Status**: Milestone 3 Complete, Milestone 2 Partial, Moving to Milestone 4

---

## Overview

This document provides comprehensive context for the entire Green Alderson Adventures project. It documents all major systems, recent changes, architectural decisions, and important context for future development.

**Project Type**: Top-down action RPG with multi-element spell system, base stat leveling, inventory/equipment, and melee enemy AI.

**Engine**: Godot 4.5.1

---

## Recent Major Changes

### Stat System Refactor (Major Overhaul)
- **STR → Resilience**: Renamed and redefined
  - Affects: Carry weight, defense, damage reduction
  - Formula: `max_carry_weight = 45.0 + (resilience * 2.0) kg`
  - Damage reduction: `damage_reduction = resilience * 0.15` (15% per point)
- **DEX → Agility**: Renamed and redefined
  - Affects: Max stamina, stamina consumption multiplier, movement speed
  - Formula: `max_stamina = agility * 10`
  - Stamina consumption: `multiplier = 1.0 - (agility * 0.02)` (2% reduction per point)
  - Movement speed: `multiplier = 1.0 + (agility * 0.03)` (3% increase per point)
- **INT (Intelligence)**: Unchanged concept
  - Affects: Max mana, mana regeneration, magic sustain
  - Formula: `max_mana = int * 15`
  - Mana regen: `rate = BASE_MANA_REGEN * (1.0 + int * 0.1)`
- **VIT (Vitality)**: Unchanged concept
  - Affects: Max health, health regeneration
  - Formula: `max_health = vit * 20`
  - Health regen: `rate = BASE_HEALTH_REGEN * (1.0 + vit * 0.1)`

### Base Stat Leveling System (NEW)
- **Separate from PlayerStats**: Modular `BaseStatLeveling` autoload singleton
- **XP Gain Methods**:
  - **Resilience**: Active (taking/dealing damage), Passive (carrying heavy items >90% weight, distance-based)
  - **Agility**: Using stamina (consumption-based)
  - **Intelligence**: Casting spells (lands or not)
  - **Vitality**: Auto-gain from other stats (1 VIT XP per 8 XP in Resilience/Agility/Intelligence)
- **Cooldown System**: 0.1 second cooldown per stat to prevent spamming
- **Max Level**: 64 for all base stats
- **XP Formula**: `XP_PER_LEVEL = level * 100` (same as element levels)
- **Vitality XP**: Respects cooldown of source stat (Resilience/Agility/Intelligence)

### Health Bar Refactor
- **Replaced**: Animated dragon health bar with static PNG image + fill bar system
- **New System**: Uses `resource_bar.gd` (same system as mana/stamina bars)
- **Features**: 
  - Static PNG overlay (half size, higher z-index)
  - Red fill bar with dark grey background
  - Configurable offsets, scaling, and dimensions
  - Positioned above mana/stamina bars

### Utility Classes Extraction (Modularization)
- **DirectionUtils**: Centralized directional logic (vector_to_dir8, dir_to_vector, etc.)
- **StatFormulas**: Complex stat calculations (damage reduction, carry weight, stamina consumption, movement speed)
- **DamageCalculator**: Centralized damage calculation (spell damage, equipment bonuses)
- **GameLogger**: Centralized logging utility (renamed from Logger to avoid Godot 4.5 conflict)
- **CooldownManager**: General-purpose cooldown system
- **XPCooldown**: Specialized XP gain cooldown manager
- **ActionCooldown**: Convenience wrapper for action cooldowns
- **RateLimiter**: Utility for rate limiting actions

### Running System Improvements
- **Modifier Key Detection**: Command/Control key detection for running
- **Running While Walking**: Can now activate running while already moving
- **Auto-Disable**: Running auto-disables when stamina depleted
- **State Management**: Requires re-pressing run key to re-enable after depletion

### ItemData/EquipmentData Implementation
- **Fully Implemented**: No longer stubs
- **ItemData**: Base class with id, display_name, description, icon, stackable, max_stack, item_type, weight
- **EquipmentData**: Extends ItemData with slot, resilience_bonus, agility_bonus, int_bonus, vit_bonus, flat_damage_bonus, damage_percentage_bonus
- **Equipment Slots**: head, body, gloves, boots, weapon, book, ring1, ring2, legs, amulet

---

## System Architecture

### Autoload Singletons

#### PlayerStats (`scripts/systems/player_stats.gd`)
- **Purpose**: Core player attributes and resource management
- **Base Stats**: Resilience, Agility, Intelligence, Vitality (all start at 5)
- **Resources**: Health, Mana, Stamina, Gold
- **Regeneration**: All resources regenerate over time (scaled by relevant stats)
- **Signals**: health_changed, mana_changed, stamina_changed, gold_changed, stat_changed, player_died
- **Key Methods**: 
  - `get_total_resilience()`, `get_total_agility()`, `get_total_int()`, `get_total_vit()`
  - `get_max_health()`, `get_max_mana()`, `get_max_stamina()`
  - `get_max_carry_weight()`, `get_current_carry_weight()`
  - `take_damage()`, `heal()`, `consume_mana()`, `consume_stamina()`

#### BaseStatLeveling (`scripts/systems/base_stat_leveling.gd`)
- **Purpose**: Base stat XP tracking and leveling (separate from PlayerStats for modularity)
- **XP Tracking**: Dictionary for resilience, agility, int, vit
- **XP Gain Methods**: 
  - `gain_base_stat_xp(stat_name, amount, source)` - Main XP gain method
  - Handles cooldowns, Vitality auto-gain, level-up checks
- **Heavy Carry XP**: Distance-based XP for Resilience when carrying >90% weight
- **Signals**: base_stat_xp_gained, base_stat_leveled_up
- **Constants**: 
  - `BASE_STAT_XP_PER_LEVEL = 100`
  - `MAX_BASE_STAT_LEVEL = 64`
  - `VITALITY_XP_RATIO = 8` (1 VIT XP per 8 other stat XP)
  - `HEAVY_CARRY_THRESHOLD = 0.90` (90% weight for XP)
  - `HEAVY_CARRY_XP_PER_METER = 0.1` (distance-based XP)

#### InventorySystem (`scripts/systems/inventory_system.gd`)
- **Purpose**: Slot-based inventory and equipment management
- **Inventory**: 12 slots (default), expandable to 48
- **Equipment Slots**: head, body, gloves, boots, weapon, book, ring1, ring2, legs, amulet
- **Methods**: add_item(), remove_item(), equip(), unequip(), get_total_stat_bonus(), get_total_damage_bonus()
- **Signals**: inventory_changed, item_added, item_removed, equipment_changed

#### SpellSystem (`scripts/systems/spell_system.gd`)
- **Purpose**: Elemental spell progression and damage calculation
- **Elements**: fire, water, earth, air
- **Leveling**: Each element levels independently
- **XP Formula**: `XP_PER_LEVEL = level * 100`
- **Damage Formula**: `base_damage + (INT * 2) + ((level - 1) * 5) + equipment_bonuses`
- **Spell Unlocking**: Pattern-based unlocking (8-12 spells per element, 32-48 total)
  - Fire: 42 levels, 8 spells
  - Water: 39 levels, 9 spells
  - Air: 54 levels, 10 spells
  - Earth: 42 levels, 8 spells
- **Methods**: get_level(), get_xp(), gain_xp(), get_spell_damage(), can_cast(), is_spell_unlocked()
- **Signals**: element_leveled_up, xp_gained

#### EventBus (`scripts/systems/event_bus.gd`)
- **Purpose**: Central signal hub for decoupled communication
- **UI Signals**: inventory_opened, inventory_closed, crafting_opened, crafting_closed, merchant_opened, merchant_closed, pause_menu_opened, pause_menu_closed
- **Game Events**: item_picked_up, item_used, chest_opened, enemy_killed, spell_cast, level_up

#### ProjectilePool (`scripts/systems/projectile_pool.gd`)
- **Purpose**: Object pooling for fire projectiles (performance optimization)
- **Pool Size**: 20 projectiles
- **Methods**: get_projectile(), return_projectile()

#### EnemyRespawnManager (`scripts/systems/enemy_respawn_manager.gd`)
- **Purpose**: Manages enemy respawning for testing
- **Respawn Delay**: 3.0 seconds
- **Tracks**: PackedScene, position, scale, parent, z_index for each enemy
- **Signals**: Connects to enemy_died signal

### Utility Classes (`scripts/utils/`)

#### DirectionUtils (`scripts/utils/direction_utils.gd`)
- **Purpose**: Centralized directional logic
- **Methods**: 
  - `vector_to_dir8(vec: Vector2) -> String` - Convert vector to 8-direction string
  - `vector_to_dir4(vec: Vector2) -> String` - Convert vector to 4-direction string
  - `dir_to_vector(dir: String) -> Vector2` - Convert direction string to vector
  - `dir8_to_dir4(dir8: String) -> String` - Convert 8-dir to 4-dir
  - `is_valid_direction(dir: String) -> bool` - Validate direction string
  - `is_facing_north(dir: String) -> bool` - Check if facing north

#### StatFormulas (`scripts/utils/stat_formulas.gd`)
- **Purpose**: Complex stat calculation formulas
- **Methods**:
  - `calculate_damage_reduction(resilience: int, damage: int) -> int`
  - `calculate_max_carry_weight(base_weight: float, resilience: int) -> float`
  - `calculate_stamina_consumption_multiplier(agility: int) -> float`
  - `calculate_movement_speed_multiplier(agility: int) -> float`
  - `calculate_carry_weight_slow_multiplier(current_weight: float, max_weight: float) -> float`

#### DamageCalculator (`scripts/utils/damage_calculator.gd`)
- **Purpose**: Centralized damage calculation
- **Methods**:
  - `calculate_spell_damage(spell: SpellData, element_level: int, int_stat: int, flat_bonus: int, percentage_bonus: float) -> int`
  - `calculate_damage_with_bonuses(base_damage: int, flat_bonus: int, percentage_bonus: float) -> int`

#### GameLogger (`scripts/utils/logger.gd`)
- **Purpose**: Centralized logging utility (renamed from Logger to avoid Godot 4.5 conflict)
- **Class**: `GameLogger` with nested `GameLoggerInstance`
- **Methods**: `log(message: String)`, `log_error(message: String)`
- **Static Method**: `create(prefix: String) -> GameLoggerInstance`

#### CooldownManager (`scripts/utils/cooldown_manager.gd`)
- **Purpose**: General-purpose cooldown management
- **Methods**: `can_perform_action(action: String, cooldown: float) -> bool`, `record_action(action: String)`, `get_time_remaining(action: String) -> float`, `reset()`

#### XPCooldown (`scripts/utils/xp_cooldown.gd`)
- **Purpose**: Specialized XP gain cooldown (0.1 seconds per stat)
- **Uses**: CooldownManager internally
- **Methods**: `can_gain_xp(stat_name: String) -> bool`, `record_xp_gain(stat_name: String)`, `reset()`

---

## Resource Classes

### ItemData (`scripts/data/item_data.gd`)
- **Base Class**: All items inherit from this
- **Properties**: id, display_name, description, icon, stackable, max_stack, item_type, weight
- **Item Types**: "consumable", "equipment", "material", "key"

### EquipmentData (`scripts/data/equipment_data.gd`)
- **Extends**: ItemData
- **Properties**: slot, resilience_bonus, agility_bonus, int_bonus, vit_bonus, flat_damage_bonus, damage_percentage_bonus
- **Auto-Set**: item_type = "equipment", stackable = false

### SpellData (`scripts/resources/spell_data.gd`)
- **Properties**: id, display_name, description, icon, element, base_damage, mana_cost, cooldown, hue_shift, projectile_speed
- **Elements**: "fire", "water", "earth", "air"

---

## UI Systems

### HUD (`scenes/ui/hud.tscn`)
- **Health Bar**: Static PNG overlay + red fill bar (uses `resource_bar.gd`)
- **Mana Bar**: Blue fill bar (uses `resource_bar.gd`)
- **Stamina Bar**: Green fill bar (uses `resource_bar.gd`)
- **Z-Index**: CanvasLayer layer = 10

### Resource Bar (`scripts/ui/resource_bar.gd`)
- **Purpose**: Reusable resource bar component (health/mana/stamina)
- **Features**: 
  - Two-tone gradient fill (light top, dark bottom)
  - Configurable offsets, scaling, dimensions
  - Optional border (show_border export)
  - Optional background (only health bar has it)
- **Exports**: bar_color, signal_name, fill_offset_x, fill_offset_y, fill_scale, fill_width_adjustment, fill_height_adjustment, show_border

### Spell Hotbar (`scenes/ui/spell_bar.tscn`)
- **Slots**: 10 slots (keys 1-9, 0)
- **Visual Selection**: Gold border highlighting
- **Element-Specific Icons**: Loaded per element
- **Z-Index**: CanvasLayer layer = 19

### Player Panel (`scenes/ui/player_panel.tscn`)
- **Tabs**: Stats, Inventory, Equipment
- **Stats Tab**: Shows base stats with XP bars and level display
- **Inventory Tab**: 12-slot grid
- **Equipment Tab**: Equipment slots with icons
- **Z-Index**: CanvasLayer layer = 20

### Base Stat Row (`scripts/ui/base_stat_row.gd`)
- **Purpose**: UI component for displaying a single base stat
- **Features**: Stat name, level, XP bar, XP label
- **Methods**: `setup()`, `update_stat()`, `update_stat_with_xp()`

---

## Player System

### Player Coordinator (`scripts/player.gd`)
- **Purpose**: Main player controller (coordinator pattern)
- **Workers**: Uses worker pattern for modularity
  - `InputReader`: Reads player input
  - `Mover`: Handles movement and physics
  - `Animator`: Manages animations
  - `SpellSpawner`: Spawns spell projectiles
  - `HealthTracker`: Tracks health
  - `Hurtbox`: Receives damage
- **State Management**: idle, walking, running, casting, hurt, dead
- **Running System**: 
  - Modifier key (Command/Control) + direction
  - Can activate while already moving
  - Auto-disables on stamina depletion
- **Spell System**: 
  - 10 equipped spells (Array[SpellData])
  - Selected spell index
  - Number key selection (1-9, 0)

---

## Enemy System

### Base Enemy (`scripts/enemies/base_enemy.gd`)
- **Purpose**: Base enemy AI with state machine
- **States**: idle, chase, attack, hurt, death
- **Workers**: 
  - `Mover`: Movement and physics
  - `Animator`: Animation management
  - `HealthTracker`: Health tracking
  - `Hurtbox`: Receives damage
  - `Hitbox`: Deals damage
  - `TargetTracker`: Tracks player
- **Signals**: enemy_died (for respawn system)

### Orc Enemy (`scripts/enemies/orc_1.gd`)
- **Extends**: BaseEnemy
- **Stats**: 80 HP, 15 damage, 45 attack range, 200 detection range
- **Animation**: 4-directional (idle, walk, attack, hurt, death)

---

## Combat System

### Damage Flow
1. **Hitbox** detects collision with **Hurtbox**
2. **Hurtbox** receives hit, applies invincibility frames
3. **PlayerStats.take_damage()** calculates damage reduction from Resilience
4. **BaseStatLeveling.gain_base_stat_xp()** grants Resilience XP
5. **HealthTracker** updates health display
6. **Screen shake** and visual feedback

### Spell Damage Calculation
```
final_damage = base_damage 
             + (INT * 2) 
             + ((element_level - 1) * 5)
             + equipment_flat_bonus
             + (base_damage * equipment_percentage_bonus)
```

### Physical Damage Reduction
```
reduced_damage = damage - (resilience * 0.15)
```

---

## Milestone Status

### ✅ Milestone 1: Foundation (COMPLETE)
- Data architecture (ItemData, EquipmentData, SpellData fully implemented)
- PlayerStats & EventBus autoloads
- HUD system (health, mana, stamina bars)

### ⚠️ Milestone 2: Inventory & Equipment (PARTIAL)
- InventorySystem autoload exists
- UI scenes exist (inventory_ui, inventory_slot, equip_slot)
- ItemData/EquipmentData fully implemented
- **Status**: Needs user-defined items list (test items to be replaced)

### ✅ Milestone 3: Elemental Spells (COMPLETE)
- SpellSystem with element leveling
- 4 element-specific projectiles and impacts
- 10-slot spell hotbar
- Element-specific icons
- XP gain on spell hit
- Spell unlocking patterns (8-12 spells per element)

### 📋 Milestone 4: Crafting & Chests (NOT STARTED)
- CraftingSystem autoload
- Crafting UI
- Chest objects with loot

### 📋 Milestone 5: Currency & Merchant (NOT STARTED)
- Currency system integration
- Merchant NPC
- Merchant UI
- Pause menu

---

## File Structure

```
scripts/
├── data/                    # Resource class definitions
│   ├── item_data.gd
│   ├── equipment_data.gd
│   └── spell_data.gd (moved from resources/)
├── systems/                 # Autoload singletons
│   ├── player_stats.gd
│   ├── base_stat_leveling.gd
│   ├── inventory_system.gd
│   ├── spell_system.gd
│   ├── event_bus.gd
│   ├── projectile_pool.gd
│   └── enemy_respawn_manager.gd
├── utils/                   # Utility classes
│   ├── direction_utils.gd
│   ├── stat_formulas.gd
│   ├── damage_calculator.gd
│   ├── logger.gd (GameLogger)
│   ├── cooldown_manager.gd
│   └── xp_cooldown.gd
├── ui/                      # UI component scripts
│   ├── resource_bar.gd
│   ├── spell_bar.gd
│   ├── spell_slot.gd
│   ├── base_stat_row.gd
│   ├── stats_tab.gd
│   └── inventory_ui.gd
├── enemies/                 # Enemy scripts
│   ├── base_enemy.gd
│   └── orc_1.gd
├── projectiles/            # Projectile scripts
│   ├── spell_projectile.gd
│   └── impact.gd
└── workers/                 # Worker pattern components
    ├── input_reader.gd
    ├── mover.gd
    ├── animator.gd
    ├── spell_spawner.gd
    ├── health_tracker.gd
    ├── hurtbox.gd
    └── hitbox.gd

scenes/
├── characters/
│   └── player.tscn
├── enemies/
│   └── orc_1.tscn
├── projectiles/
│   ├── fireball.tscn
│   ├── waterball.tscn
│   ├── earthball.tscn
│   └── airball.tscn
├── effects/
│   ├── fire_impact.tscn
│   ├── water_impact.tscn
│   ├── earth_impact.tscn
│   └── water_impact.tscn
├── ui/
│   ├── hud.tscn
│   ├── health_bar.tscn
│   ├── spell_bar.tscn
│   └── player_panel.tscn
└── systems/
    └── projectile_pool.tscn

resources/
├── items/                   # ItemData resources
├── equipment/               # EquipmentData resources
├── spells/                  # SpellData resources
│   ├── fireball.tres
│   ├── waterball.tres
│   ├── earthball.tres
│   └── airball.tres
├── potions/                 # PotionData resources
└── recipes/                 # RecipeData resources
```

---

## Important Design Decisions

### 1. Stat System Naming
- **Resilience** (formerly STR): Represents toughness, carry capacity, damage reduction
- **Agility** (formerly DEX): Represents speed, stamina efficiency, movement
- **Intelligence**: Represents magic sustain, mana capacity
- **Vitality**: Represents health capacity and regeneration

### 2. Modular Architecture
- **Worker Pattern**: Player coordinator delegates to workers
- **Utility Classes**: Extracted complex logic into reusable utilities
- **Separate Systems**: BaseStatLeveling separate from PlayerStats for modularity
- **Signal-Based Communication**: Decoupled systems via EventBus

### 3. XP and Leveling
- **Base Stats**: Max level 64, XP = level * 100
- **Elements**: Max level varies by element (42-54), XP = level * 100
- **Cooldowns**: 0.1 second cooldown per stat to prevent spamming
- **Vitality**: Auto-gains from other stats (1 VIT per 8 other stat XP)

### 4. Damage System
- **Spell Damage**: Centralized in DamageCalculator
- **Physical Damage**: Reduced by Resilience (15% per point)
- **Equipment Bonuses**: Flat and percentage bonuses

### 5. UI System
- **Resource Bars**: Reusable component for health/mana/stamina
- **Z-Index Layers**: HUD=10, SpellBar=19, Inventory=20
- **Health Bar**: Static PNG overlay + fill bar (unique design)

---

## Testing & Validation

### System Validator (`scripts/test/system_validator.gd`)
- **Purpose**: Automated test script for core systems
- **Tests**: 
  - Autoload existence
  - PlayerStats initialization
  - InventorySystem
  - SpellSystem
  - BaseStatLeveling
  - StatFormulas
  - DamageCalculator
  - Cooldown systems
- **Status**: 37 tests, all passing

### Logging
- **GameLogger**: Centralized logging with prefixes
- **Active Logging**: All major systems have active logging
- **Prefixes**: [PlayerStats], [BaseStatLeveling], [SpellSystem], etc.

---

## Known Issues / Future Work

### Immediate
- Replace test items with user-defined items list
- Complete Milestone 4 (Crafting & Chests)

### Short-term
- Spell unlocking system (patterns defined, needs implementation)
- Crafting system
- Chest objects
- Merchant system

### Long-term
- MMORPG conversion (architecture planning document exists)
- Spell combinations
- Elemental resistances/weaknesses
- Advanced equipment modifiers

---

## Key Files to Review

### Critical Systems
- `scripts/systems/player_stats.gd` - Core player attributes
- `scripts/systems/base_stat_leveling.gd` - Base stat XP and leveling
- `scripts/systems/spell_system.gd` - Elemental spell progression
- `scripts/systems/inventory_system.gd` - Inventory and equipment
- `scripts/player.gd` - Player coordinator

### Utility Classes
- `scripts/utils/stat_formulas.gd` - Stat calculations
- `scripts/utils/damage_calculator.gd` - Damage calculations
- `scripts/utils/direction_utils.gd` - Directional logic
- `scripts/utils/logger.gd` - Logging system

### UI Components
- `scripts/ui/resource_bar.gd` - Reusable resource bar
- `scripts/ui/spell_bar.gd` - Spell hotbar
- `scripts/ui/base_stat_row.gd` - Base stat display

---

## Notes for New Agent

1. **Do NOT commit/push** unless explicitly asked by user
2. **Follow SPEC.md** for standardization (though some deviations exist - Resilience/Agility rename)
3. **Use existing patterns**: Worker pattern, signal-based communication, utility classes
4. **Test thoroughly** before suggesting completion
5. **Check logs** for debugging (comprehensive logging is in place)
6. **Respect z-index layers**: HUD=10, SpellBar=19, Inventory=20
7. **Stat names**: Use Resilience/Agility (not STR/DEX)
8. **Modularity**: Keep systems separate and modular
9. **XP Cooldowns**: Always respect 0.1 second cooldown per stat
10. **Resource Bars**: Health bar has Background node, mana/stamina don't (use get_node_or_null())

---

## Commit History Context

- **Latest**: Health bar refactor, resource bar Background node fix
- **Recent**: Stat system refactor (Resilience/Agility), base stat leveling system
- **Recent**: Utility classes extraction, running system improvements
- **Commit 3C**: Spell Selection & Hotbar (complete)
- **Commit 3B**: Multi-Element Projectiles (element-specific assets)
- **Commit 3A**: Spell System Foundation
- Previous commits: Inventory, Equipment, UI systems

---

**End of Context File**
