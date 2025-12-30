# Context File: Green Alderson Adventures - Complete System Overview

**Date**: Current Session  
**Last Updated**: After Codebase Cleanup and Refactoring (December 2024)  
**Status**: Milestone 3 Complete, Milestone 2 Complete, Moving to Milestone 4

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

### PlayerStats Refactoring (MAJOR ARCHITECTURAL CHANGE)
- **Facade Pattern**: PlayerStats is now a thin facade that delegates to focused systems
- **New Systems Created**:
  - **XPLevelingSystem**: Base stat XP tracking and leveling (replaces BaseStatLeveling)
  - **CurrencySystem**: Gold management
  - **ResourceRegenSystem**: Health/mana/stamina regeneration
  - **CombatSystem**: Combat calculations (damage reduction)
  - **MovementSystem**: Movement calculations (stamina consumption, speed multipliers, carry weight)
- **Carry Weight System**: Moved out of PlayerStats
  - `get_current_carry_weight()` → InventorySystem
  - `get_max_carry_weight()` → MovementSystem
  - `can_carry_item()` → InventorySystem
  - `get_carry_weight_slow_multiplier()` → MovementSystem
- **Signal Forwarding**: PlayerStats forwards signals from new systems for backward compatibility
- **Benefits**: Better separation of concerns, easier testing, more maintainable code

### Base Stat Leveling System
- **XPLevelingSystem**: Handles all base stat XP tracking and leveling
- **XP Gain Methods**:
  - **Resilience**: Active (taking/dealing damage), Passive (carrying heavy items >90% weight, distance-based)
  - **Agility**: Using stamina (consumption-based)
  - **Intelligence**: Casting spells (lands or not)
  - **Vitality**: Auto-gain from other stats (1 VIT XP per 8 XP in Resilience/Agility/Intelligence)
- **Cooldown System**: 0.1 second cooldown per stat to prevent spamming
- **Max Level**: 110 for all base stats (RuneScape-style exponential curve)
- **XP Formula**: RuneScape-style exponential curve (not linear)
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

### Inventory & Currency Integration (January 2025)
- **Gold as an Item**: CurrencySystem now mirrors the `gold_coins` ItemData stack stored inside InventorySystem, so pickups, merchants, and UI all reference the same inventory state
- **Deferred Pickups**: Gold/item pickups spawn via `_schedule_pickup_spawn()` to avoid physics flush errors and update their visuals if inventory is full
- **Responsive Inventory UI**: Sidebar inventory always shows 28 slots, equipment slots no longer rebuild on every change, and the equipment tab displays RuneScape-style Base / Equipment / Total stat bonuses for each core stat
- **Fullscreen & Stretch**: `project.godot` defaults to a resizable 1600×900 window using `canvas_items` stretch with `expand` aspect so HUD/UI scale cleanly in fullscreen or windowed mode

### Codebase Cleanup and Refactoring (December 2024)
- **Backup Files Removed**: Deleted 4 backup files (player_stats.gd.backup, .bak, .uid files)
- **Orphaned UID Files Removed**: Deleted 3 orphaned UID files (base_stat_leveling, health_bar, quick_belt_tab)
- **Constants Migration**: 
  - Moved collision layer and group constants from unused `constants.gd` to `game_constants.gd`
  - Updated all files to use `GameConstants` instead of magic numbers/strings
  - Added: `COLLISION_LAYER_TERRAIN`, `COLLISION_LAYER_PROJECTILE`, `COLLISION_LAYER_HITBOX`, `COLLISION_LAYER_HURTBOX`
  - Added: `GROUP_PLAYER`, `GROUP_ENEMY`, `GROUP_FIREBALL`
- **Scene Path Fixes**: Updated 12 scene files to use new hierarchical script paths:
  - Bars: `scripts/ui/bars/` (resource_bar, spell_bar, enemy_health_bar, tool_belt)
  - Slots: `scripts/ui/slots/` (spell_slot, inventory_slot, equip_slot, quick_belt_slot)
  - Tabs: `scripts/ui/tabs/` (inventory_tab, equipment_tab, stats_tab)
  - Rows: `scripts/ui/rows/` (base_stat_row, element_stat_row)
  - Panels: `scripts/ui/panels/` (player_panel)
  - Inventory: `scripts/ui/inventory/` (inventory_ui)
- **InventorySystem Refactoring**: 
  - Removed duplicate code (~30 lines)
  - `get_total_stat_bonus()`, `get_total_damage_bonus()`, `get_total_damage_percentage()` now delegate to `EquipmentStatCalculator`
  - Follows DRY principle, single source of truth for equipment calculations
- **Unused File Removed**: Deleted `constants.gd` (FireballConfig - replaced by SpellData resource system)

---

## System Architecture

### Autoload Singletons

#### PlayerStats (`scripts/systems/player_stats.gd`)
- **Purpose**: Facade for player attributes and resource management (delegates to focused systems)
- **Architecture**: Thin facade pattern - delegates to XPLevelingSystem, CurrencySystem, ResourceRegenSystem, CombatSystem, MovementSystem
- **Base Stats**: Resilience, Agility, Intelligence, Vitality (managed by XPLevelingSystem)
- **Resources**: Health, Mana, Stamina (current values stored here, max calculated from stats)
- **Gold**: Managed by CurrencySystem; PlayerStats mirrors the authoritative `gold_coins` stack stored inside InventorySystem so UI listeners can continue to consume the `gold_changed` signal
- **Regeneration**: Handled by ResourceRegenSystem (delegated)
- **Signals**: health_changed, mana_changed, stamina_changed, gold_changed, stat_changed, player_died, base_stat_xp_gained, base_stat_leveled_up (forwards from XPLevelingSystem)
- **Key Methods**: 
  - `get_total_resilience()`, `get_total_agility()`, `get_total_int()`, `get_total_vit()` (combines base + equipment)
  - `get_max_health()`, `get_max_mana()`, `get_max_stamina()` (calculated from stats)
  - `get_max_carry_weight()`, `get_current_carry_weight()`, `can_carry_item()` (delegates to MovementSystem/InventorySystem)
  - `take_damage()`, `heal()`, `consume_mana()`, `consume_stamina()` (manages current values, delegates calculations)

#### XPLevelingSystem (`scripts/systems/xp_leveling_system.gd`)
- **Purpose**: Base stat XP tracking and leveling (RuneScape-style exponential curve)
- **XP Tracking**: Dictionary for resilience, agility, int, vit
- **XP Gain Methods**: 
  - `gain_base_stat_xp(stat_name, amount, source)` - Main XP gain method
  - Handles cooldowns, Vitality auto-gain, level-up checks
- **Heavy Carry XP**: Distance-based XP for Resilience when carrying >90% weight (via MovementTracker)
- **Signals**: base_stat_xp_gained, base_stat_leveled_up, stat_changed, character_level_changed
- **Max Level**: 110 for all base stats
- **XP Formula**: RuneScape-style exponential curve (not linear)
- **Vitality XP**: Auto-gains from other stats (1 VIT XP per 8 other stat XP)

#### CurrencySystem (`scripts/systems/currency_system.gd`)
- **Purpose**: Gold management backed by the actual `gold_coins` ItemData inside InventorySystem (no separate hidden counter)
- **Behavior**:
  - Loads `res://resources/items/gold_coins.tres` during `_ready()` and listens to `InventorySystem.inventory_changed`
  - `add_gold()`/`spend_gold()` add or remove from the real inventory stack; if inventory is full the leftover amount stays on the pickup
  - Maintains the legacy `gold` integer as a mirror so PlayerStats and HUD listeners continue to function unchanged
- **Signals**: gold_changed (emitted whenever the mirrored total changes)

#### ResourceRegenSystem (`scripts/systems/resource_regen_system.gd`)
- **Purpose**: Health/mana/stamina regeneration over time
- **Regeneration Rates**: Scaled by relevant stats (VIT for health, INT for mana, Agility for stamina)
- **Process**: Runs in `_process()` to regenerate resources

#### CombatSystem (`scripts/systems/combat_system.gd`)
- **Purpose**: Combat-related calculations
- **Methods**: `calculate_damage_reduction(incoming_damage, resilience)` - Damage reduction with diminishing returns

#### MovementSystem (`scripts/systems/movement_system.gd`)
- **Purpose**: Movement-related calculations
- **Methods**: 
  - `get_stamina_consumption_multiplier(agility)` - Based on agility
  - `get_movement_speed_multiplier(agility)` - Based on agility
  - `get_max_carry_weight()` - Based on resilience
  - `get_carry_weight_slow_multiplier()` - Movement speed penalty when carrying heavy load

- **Purpose**: Slot-based inventory and equipment management
- **Inventory**: 28 slots (default sidebar grid), expandable to 48
- **Equipment Slots**: head, body, gloves, boots, weapon, book, ring1, ring2, legs, amulet
- **Methods**: 
  - `add_item()`, `remove_item()`, `equip()`, `unequip()`
  - `get_total_stat_bonus()`, `get_total_damage_bonus()`, `get_total_damage_percentage()`
  - `get_current_carry_weight()` - Calculates total weight of inventory + equipment
  - `can_carry_item()` - Checks if player can carry additional items
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
- **Note**: EventBus is split into domain-specific buses (UIEventBus, GameplayEventBus, CombatEventBus) but EventBus still exists for backward compatibility

#### MovementTracker (`scripts/systems/movement_tracker.gd`)
- **Purpose**: Tracks player movement and carry weight for XP gain
- **Heavy Carry XP**: Emits signals when player moves while carrying >=90% max weight
- **Signals**: heavy_carry_moved(distance, weight_percentage)
- **Integration**: Connected to XPLevelingSystem for Resilience XP gain

#### ProjectilePool (`scripts/systems/projectile_pool.gd`)
- **Purpose**: Object pooling for fire projectiles (performance optimization)
- **Pool Size**: 20 projectiles
- **Methods**: get_projectile(), return_projectile()

#### GameBalance (`scripts/systems/resources/game_balance.gd`)
- **Purpose**: Centralized game balance configuration system
- **Configuration**: Loads `GameBalanceConfig` resource from `res://resources/config/default_balance.tres`
- **Methods**: Provides getters for all game balance values (walk_speed, run_speed, health_per_vit, mana_per_int, etc.)
- **Benefits**: Data-driven design, easy balancing without code changes, centralized configuration
- **Fallback**: Uses default values if config file not found

#### ResourceManager (`scripts/systems/resources/resource_manager.gd`)
- **Purpose**: Centralized resource loading system with caching
- **Resource Types**: SpellData, ItemData, PotionData, EquipmentData, RecipeData, MerchantData
- **Caching**: Automatic caching of loaded resources (keyed by type and ID)
- **Methods**: 
  - `load_resource(resource_type, resource_id)` - Generic resource loader
  - `load_spell()`, `load_item()`, `load_potion()`, `load_equipment()`, `load_recipe()`, `load_merchant()` - Type-specific loaders
  - `load_scene(scene_path)` - Scene loading
  - `clear_cache()`, `clear_cache_for_type()` - Cache management
- **Benefits**: Centralized paths, automatic caching, consistent error handling

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

### PotionData (`scripts/data/potion_data.gd`)
- **Extends**: ItemData
- **Properties**: effect_type, effect_value, duration
- **Auto-Set**: item_type = "consumable", stackable = true

### RecipeData (`scripts/data/recipe_data.gd`)
- **Properties**: id, display_name, description, icon, ingredients (Dictionary), result_item, result_count
- **Purpose**: Crafting recipe definitions

### MerchantData (`scripts/resources/merchant_data.gd`)
- **Properties**: id, display_name, description, icon, shop_items (Array), buy_multiplier, sell_multiplier
- **Purpose**: Merchant NPC shop definitions

### GameBalanceConfig (`scripts/resources/game_balance_config.gd`)
- **Purpose**: Resource containing all game balance values
- **Properties**: Walk speed, run speed, health per VIT, mana per INT, stamina per Agility, XP formulas, etc.
- **Location**: `res://resources/config/default_balance.tres`
- **Access**: Via `GameBalance` autoload singleton

### EntityData (`scripts/entities/entity_data.gd`)
- **Purpose**: Serializable entity state data
- **Properties**: entity_id, entity_type, position, network_id
- **Methods**: `to_dict()`, `from_dict()` for serialization
- **Usage**: Base class for network synchronization and save/load systems

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
- **Tabs**: Stats, Inventory, Equipment (Inventory and Equipment tabs share the same sidebar root used in-game)
- **Stats Tab**: Shows base stats with XP bars and level display
- **Inventory Tab**: 28-slot grid plus drag-and-drop interactions; gold coins occupy real slots just like any other stack
- **Equipment Tab**: Displays gear slots with icons and a RuneScape-style “Bonuses” section listing Base / Equipment / Total values for Resilience, Agility, Intelligence, and Vitality
- **Z-Index**: CanvasLayer layer = 20

### Base Stat Row (`scripts/ui/base_stat_row.gd`)
- **Purpose**: UI component for displaying a single base stat
- **Features**: Stat name, level, XP bar, XP label
- **Methods**: `setup()`, `update_stat()`, `update_stat_with_xp()`

---

## Entity & Worker Patterns

### BaseEntity (`scripts/entities/base_entity.gd`)
- **Purpose**: Base class for all entities (player, enemy, NPC)
- **Extends**: CharacterBody2D
- **Features**:
  - Common worker references (mover, animator, health_tracker, hurtbox)
  - Entity data serialization (EntityData)
  - Network synchronization support (network_id, authority)
  - Logging system
- **Signals**: entity_died, entity_state_changed (emitted by subclasses)
- **Methods**: `get_entity_data()`, `load_entity_data()`, `to_dict()`, `from_dict()`
- **Subclasses**: Player, BaseEnemy

### BaseWorker (`scripts/workers/base/base_worker.gd`)
- **Purpose**: Base class for all worker nodes
- **Extends**: Node
- **Features**:
  - Consistent initialization pattern (`_on_initialize()`)
  - Owner node reference
  - Built-in logging system
  - Lifecycle management (initialized, cleanup_requested signals)
- **Methods**: 
  - `_on_initialize()` - Override for custom initialization
  - `update(delta)` - Override for per-frame updates
  - `cleanup()` - Override for cleanup logic
- **Subclasses**: Mover, Animator, HealthTracker, Hurtbox, Hitbox, SpellSpawner, SpellCaster, InputReader

### Worker Pattern Benefits
- **Modularity**: Single-purpose components
- **Reusability**: Workers can be shared across entities
- **Testability**: Workers can be tested independently
- **Consistency**: BaseWorker provides common interface

## Player System

### Player Coordinator (`scripts/player.gd`)
- **Purpose**: Main player controller (coordinator pattern)
- **Extends**: BaseEntity
- **Workers**: Uses worker pattern for modularity
  - `InputReader`: Reads player input
  - `Mover`: Handles movement and physics
  - `Animator`: Manages animations
  - `SpellSpawner`: Spawns spell projectiles
  - `SpellCaster`: Handles spell casting logic
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
3. **PlayerStats.take_damage()** delegates to **CombatSystem** for damage reduction calculation
4. **XPLevelingSystem.gain_base_stat_xp()** grants Resilience XP (via PlayerStats facade)
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
├── constants/               # Game constants
│   └── game_constants.gd
├── data/                    # Resource class definitions
│   ├── item_data.gd
│   ├── equipment_data.gd
│   ├── potion_data.gd
│   └── recipe_data.gd
├── entities/                # Entity base classes
│   ├── base_entity.gd
│   └── entity_data.gd
├── resources/               # Resource data classes
│   ├── spell_data.gd
│   ├── merchant_data.gd
│   └── game_balance_config.gd
├── state/                   # Game state management
│   ├── game_state.gd
│   └── player_state.gd
├── systems/                 # Autoload singletons (organized by domain)
│   ├── player/              # Player-related systems
│   │   └── player_stats.gd  # Facade - delegates to focused systems
│   ├── combat/              # Combat systems
│   │   └── combat_system.gd
│   ├── movement/            # Movement systems
│   │   ├── movement_system.gd
│   │   └── movement_tracker.gd
│   ├── inventory/           # Inventory systems
│   │   └── inventory_system.gd
│   ├── spells/              # Spell systems
│   │   └── spell_system.gd
│   ├── resources/           # Resource management
│   │   ├── resource_regen_system.gd
│   │   ├── currency_system.gd
│   │   ├── resource_manager.gd
│   │   └── game_balance.gd
│   ├── events/              # Event systems
│   │   ├── event_bus.gd
│   │   ├── ui_event_bus.gd
│   │   ├── gameplay_event_bus.gd
│   │   └── combat_event_bus.gd
│   ├── player/              # Player systems
│   │   └── xp_leveling_system.gd
│   ├── spells/              # Spell systems
│   │   └── projectile_pool.gd
│   └── combat/              # Combat systems
│       └── enemy_respawn_manager.gd
├── utils/                   # Utility classes (organized by domain)
│   ├── direction/            # Direction utilities
│   │   └── direction_utils.gd
│   ├── stats/               # Stat calculation utilities
│   │   ├── stat_formulas.gd
│   │   └── damage_calculator.gd
│   ├── logging/             # Logging utilities
│   │   └── logger.gd (GameLogger)
│   ├── cooldowns/           # Cooldown utilities
│   │   ├── cooldown_manager.gd
│   │   └── xp_cooldown.gd
│   └── signals/             # Signal utilities
│       └── signal_utils.gd
├── ui/                      # UI component scripts (organized by type)
│   ├── bars/                # Resource bars
│   │   └── resource_bar.gd
│   ├── slots/                # Slot components
│   │   ├── spell_slot.gd
│   │   └── inventory_slot.gd
│   ├── rows/                 # Row components
│   │   └── base_stat_row.gd
│   ├── tabs/                 # Tab components
│   │   ├── stats_tab.gd
│   │   └── inventory_tab.gd
│   ├── panels/               # Panel components
│   │   └── player_panel.gd
│   └── inventory/            # Inventory UI
│       └── inventory_ui.gd
├── enemies/                 # Enemy scripts
│   ├── base_enemy.gd
│   └── orc_1.gd
├── projectiles/            # Projectile scripts
│   ├── spell_projectile.gd
│   └── impact.gd
├── workers/                 # Worker pattern components (organized by domain)
│   ├── base/                 # Base worker classes
│   │   └── base_worker.gd
│   ├── input/                # Input workers
│   │   └── input_reader.gd
│   ├── movement/             # Movement workers
│   │   └── mover.gd
│   ├── animation/            # Animation workers
│   │   └── animator.gd
│   ├── combat/               # Combat workers
│   │   ├── health_tracker.gd
│   │   ├── hurtbox.gd
│   │   └── hitbox.gd
│   ├── spells/               # Spell workers
│   │   ├── spell_spawner.gd
│   │   └── spell_caster.gd
│   └── effects/              # Effect workers
├── test/                     # Test scripts
│   └── system_validator.gd
└── player.gd                # Main player coordinator

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
- **Worker Pattern**: Player coordinator delegates to workers (BaseWorker base class)
- **Entity Pattern**: BaseEntity provides common functionality for all entities
- **Facade Pattern**: PlayerStats acts as thin facade delegating to focused systems
- **Utility Classes**: Extracted complex logic into reusable utilities
- **Separate Systems**: XPLevelingSystem separate from PlayerStats for modularity
- **Signal-Based Communication**: Decoupled systems via EventBus
- **Hierarchical Organization**: Code organized by domain/functionality in subdirectories
  - Benefits: Easier navigation, clear ownership, better scalability

### 3. XP and Leveling
- **Base Stats**: Max level 110, RuneScape-style exponential XP curve (not linear)
- **Elements**: Max level varies by element (42-54), XP = level * 100
- **Cooldowns**: 0.1 second cooldown per stat to prevent spamming
- **Vitality**: Auto-gains from other stats (1 VIT per 8 other stat XP)
- **Character Level**: Calculated from all base stats + magic elements

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
  - XPLevelingSystem (base stat leveling)
  - StatFormulas
  - DamageCalculator
  - Cooldown systems
- **Status**: 36 tests, all passing

### Logging
- **GameLogger**: Centralized logging with prefixes and log levels (DEBUG, INFO, WARNING, ERROR)
- **Active Logging**: All major systems have active logging
- **Prefixes**: [PlayerStats], [XPLevelingSystem], [SpellSystem], etc.
- **Log Levels**: Filterable by level (set via `GameLogger.set_log_level()`)
- **Static Methods**: `log_debug()`, `log_info()`, `log_warning()`, `log_error()`
- **Instance Methods**: Create logger instance with `GameLogger.create(prefix)` for per-class logging

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
- `scripts/systems/player_stats.gd` - Facade for player attributes (delegates to focused systems)
- `scripts/systems/xp_leveling_system.gd` - Base stat XP and leveling
- `scripts/systems/currency_system.gd` - Gold management
- `scripts/systems/resource_regen_system.gd` - Resource regeneration
- `scripts/systems/combat_system.gd` - Combat calculations
- `scripts/systems/movement_system.gd` - Movement calculations
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
3. **Use existing patterns**: Worker pattern (BaseWorker), Entity pattern (BaseEntity), Facade pattern (PlayerStats), signal-based communication, utility classes
4. **Test thoroughly** before suggesting completion
5. **Check logs** for debugging (comprehensive logging is in place)
6. **Respect z-index layers**: HUD=10, SpellBar=19, Inventory=20
7. **Stat names**: Use Resilience/Agility (not STR/DEX) - see StatConstants
8. **Modularity**: Keep systems separate and modular
9. **XP Cooldowns**: Always respect 0.1 second cooldown per stat
10. **Resource Bars**: Health bar has Background node, mana/stamina don't (use get_node_or_null())
11. **Resource Loading**: Always use ResourceManager for loading resources (not direct load())
12. **Game Balance**: Use GameBalance autoload for all balance values (not hardcoded constants)
13. **Directory Structure**: Follow hierarchical organization (systems in subdirectories by domain)
14. **PlayerStats**: Is a facade - delegate to focused systems (XPLevelingSystem, CurrencySystem, etc.)

---

## Commit History Context

- **Latest**: Codebase cleanup, constants migration, scene path fixes, InventorySystem refactoring
- **Recent**: Health bar refactor, resource bar Background node fix
- **Recent**: Stat system refactor (Resilience/Agility), base stat leveling system
- **Recent**: Utility classes extraction, running system improvements
- **Commit 3C**: Spell Selection & Hotbar (complete)
- **Commit 3B**: Multi-Element Projectiles (element-specific assets)
- **Commit 3A**: Spell System Foundation
- Previous commits: Inventory, Equipment, UI systems, hierarchical reorganization

---

**End of Context File**
