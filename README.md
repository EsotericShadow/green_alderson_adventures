# Green Alderson Adventures

A Godot 4.5 top-down action RPG with multi-element spell system, elemental leveling, and melee enemy AI.

**Current Status**: Milestone 3 Complete - Elemental Spells system fully implemented. Codebase cleanup and refactoring completed. Moving to Milestone 4 (Crafting & Chests).

---

## Controls

| Action | Keys |
|--------|------|
| Move | W/A/S/D or Arrow Keys |
| Run | Ctrl + Direction |
| Jump | Space (while running) |
| Select/Cast Spell | 1-9, 0 (number keys) |
| Open Inventory | I *(Implemented in Milestone 2)* |
| Open Crafting | C *(Coming in Milestone 4)* |
| Interact | E *(Coming in Milestone 4)* |
| Pause | Escape *(Coming in Milestone 5)* |

**Spell Hotbar**: Keys 1-4 are pre-equipped with Fire, Water, Earth, and Air spells. Press a number key once to select the spell, press again to cast it.

---

## Features

### Core Systems ✅

- **8-Directional Movement** - Full directional movement with walk/run speeds
- **Stamina System** - Running consumes stamina, regenerates when not running
- **Multi-Element Spell System** - Four elements: Fire, Water, Earth, Air
- **Elemental Leveling** - Each element levels independently with XP gained from spell hits
- **10-Slot Spell Hotbar** - Visual spell selection and casting (keys 1-9, 0)
- **Dynamic Spell Damage** - Damage scales with Intelligence stat and element level
- **Mana System** - Spells consume mana, regenerates over time

### Combat ✅

- **Element-Specific Projectiles** - Each element has unique colored projectiles and impact effects
- **Orc Enemy AI** - Melee enemy with detection, chase, attack, hurt, and death states
- **Combat System** - Hitbox/Hurtbox collision with invincibility frames
- **Screen Shake** - Camera shake on player hit
- **Visual Feedback** - Enemy flashes red when damaged

### UI ✅

- **HUD** - Health, Mana, and Stamina bars (top-left)
- **Spell Hotbar** - 10-slot spell selection bar (bottom-center)
- **Enemy Health Bars** - Health bars above enemy heads
- **Inventory & Equipment Panel** - Sidebar inventory shows 28 slots, gold coins consume real inventory space, and the equipment tab displays RuneScape-style Base / Equipment / Total stat bonuses

### Technical ✅

- **Object Pooling** - Optimized projectile system that reuses objects
- **Animation System** - Smooth transitions between all action states
- **Z-Index Layering** - Proper depth sorting for north vs south-facing projectiles
- **Coordinator/Worker Pattern** - Clean architecture preventing code drift
- **Responsive Window Scaling** - Game launches fullscreen, can be resized freely, and all canvas items stretch proportionally via `canvas_items` + `expand` aspect
- **Inventory-Backed Currency** - `CurrencySystem` manages gold as a real `gold_coins` stack inside InventorySystem, so pickups and merchants interact with the same data the player sees

---

## Project Structure

```
├── scripts/
│   ├── player.gd              # Player coordinator (movement, spells, combat)
│   ├── constants/             # Game constants
│   │   └── game_constants.gd
│   ├── data/                  # Resource class definitions
│   │   ├── item_data.gd
│   │   ├── equipment_data.gd
│   │   ├── potion_data.gd
│   │   └── recipe_data.gd
│   ├── entities/              # Entity base classes
│   │   ├── base_entity.gd
│   │   └── entity_data.gd
│   ├── resources/             # Resource data classes
│   │   ├── spell_data.gd
│   │   ├── merchant_data.gd
│   │   └── game_balance_config.gd
│   ├── systems/               # Autoload singletons (organized by domain)
│   │   ├── player/            # Player-related systems
│   │   │   └── player_stats.gd  # Facade - delegates to focused systems
│   │   ├── combat/             # Combat systems
│   │   │   ├── combat_system.gd
│   │   │   └── enemy_respawn_manager.gd
│   │   ├── movement/           # Movement systems
│   │   │   ├── movement_system.gd
│   │   │   └── movement_tracker.gd
│   │   ├── inventory/          # Inventory systems
│   │   │   └── inventory_system.gd
│   │   ├── spells/             # Spell systems
│   │   │   ├── spell_system.gd
│   │   │   └── projectile_pool.gd
│   │   ├── resources/          # Resource management
│   │   │   ├── resource_regen_system.gd
│   │   │   ├── currency_system.gd
│   │   │   ├── resource_manager.gd
│   │   │   └── game_balance.gd
│   │   ├── events/             # Event systems
│   │   │   ├── event_bus.gd
│   │   │   ├── ui_event_bus.gd
│   │   │   ├── gameplay_event_bus.gd
│   │   │   └── combat_event_bus.gd
│   │   └── player/             # Player systems
│   │       └── xp_leveling_system.gd
│   ├── utils/                  # Utility classes (organized by domain)
│   │   ├── direction/          # Direction utilities
│   │   │   └── direction_utils.gd
│   │   ├── stats/              # Stat calculation utilities
│   │   │   ├── stat_formulas.gd
│   │   │   └── damage_calculator.gd
│   │   ├── logging/            # Logging utilities
│   │   │   └── logger.gd (GameLogger)
│   │   ├── cooldowns/          # Cooldown utilities
│   │   │   ├── cooldown_manager.gd
│   │   │   └── xp_cooldown.gd
│   │   └── signals/            # Signal utilities
│   │       └── signal_utils.gd
│   ├── ui/                     # UI component scripts (organized by type)
│   │   ├── bars/               # Resource bars
│   │   │   ├── resource_bar.gd
│   │   │   ├── spell_bar.gd
│   │   │   └── enemy_health_bar.gd
│   │   ├── slots/               # Slot components
│   │   │   ├── spell_slot.gd
│   │   │   └── inventory_slot.gd
│   │   ├── rows/                # Row components
│   │   │   └── base_stat_row.gd
│   │   ├── tabs/                # Tab components
│   │   │   ├── stats_tab.gd
│   │   │   └── inventory_tab.gd
│   │   ├── panels/              # Panel components
│   │   │   └── player_panel.gd
│   │   └── inventory/           # Inventory UI
│   │       └── inventory_ui.gd
│   ├── enemies/                # Enemy scripts
│   │   ├── base_enemy.gd
│   │   └── orc_1.gd
│   ├── projectiles/            # Projectile scripts
│   │   ├── spell_projectile.gd
│   │   └── impact.gd
│   └── workers/                 # Worker pattern components (organized by domain)
│       ├── base/                # Base worker classes
│       │   ├── base_worker.gd
│       │   └── base_area_worker.gd
│       ├── input/               # Input workers
│       │   └── input_reader.gd
│       ├── movement/            # Movement workers
│       │   ├── mover.gd
│       │   └── running_state_manager.gd
│       ├── animation/            # Animation workers
│       │   └── animator.gd
│       ├── combat/               # Combat workers
│       │   ├── health_tracker.gd
│       │   ├── hurtbox.gd
│       │   ├── hitbox.gd
│       │   └── target_tracker.gd
│       ├── spells/               # Spell workers
│       │   ├── spell_spawner.gd
│       │   └── spell_caster.gd
│       └── effects/              # Effect workers
│           └── camera_effects_worker.gd

├── scenes/
│   ├── main.tscn              # Main game scene (entry point)
│   ├── characters/
│   │   └── player.tscn        # Player character
│   ├── enemies/
│   │   └── orc_1.tscn         # Orc enemy
│   ├── projectiles/           # Projectile scenes
│   │   ├── fireball.tscn      # Fire projectile
│   │   ├── waterball.tscn     # Water projectile
│   │   ├── earthball.tscn     # Earth projectile
│   │   └── airball.tscn       # Air projectile
│   ├── effects/               # Effect scenes
│   │   ├── fire_impact.tscn   # Fire impact effect
│   │   ├── water_impact.tscn  # Water impact effect
│   │   ├── earth_impact.tscn  # Earth impact effect
│   │   └── air_impact.tscn    # Air impact effect
│   ├── systems/
│   │   └── projectile_pool.tscn # Pooling system
│   ├── ui/                    # UI scenes
│   │   ├── hud.tscn           # Main HUD (health/mana/stamina)
│   │   ├── spell_bar.tscn     # Spell hotbar
│   │   ├── spell_slot.tscn    # Individual spell slot
│   │   └── enemy_health_bar.tscn # Enemy health bar
│   └── worlds/
│       └── overworld.tscn     # Tilemap/world

├── resources/                 # Resource instances (.tres files)
│   └── spells/
│       ├── fireball.tres      # Fire spell definition
│       ├── waterball.tres     # Water spell definition
│       ├── earthball.tres     # Earth spell definition
│       └── airball.tres       # Air spell definition

├── animations/                # Sprite sheets
│   ├── player/                # Player sprite sheets (8 directions)
│   ├── orc_1/                 # Orc sprite sheets (4 directions)
│   └── spells/                # Spell effect sprites

└── Texture/                   # Tileset textures
```

---

## Architecture

### Coordinator/Worker Pattern
The codebase uses a "Coordinator/Worker" architecture:
- **Coordinators** (`player.gd`, `base_enemy.gd`) make decisions and delegate to workers
- **Workers** (`mover.gd`, `animator.gd`, etc.) do one thing and do it well
- This prevents code drift when adding features

### Enemy AI States
| State | Description |
|-------|-------------|
| IDLE | Standing at spawn, waiting for player |
| CHASE | Moving toward player |
| ATTACK | Executing attack animation + hitbox |
| HURT | Stunned after taking damage |
| RETURN | Walking back to spawn (leash) |
| DEATH | Death animation then queue_free |

### Collision Layers
Defined in `GameConstants`:
| Layer | Constant | Purpose |
|-------|----------|---------|
| 1 | `COLLISION_LAYER_TERRAIN` | Terrain/Walls |
| 2 | `COLLISION_LAYER_PROJECTILE` | Projectiles |
| 4 | `COLLISION_LAYER_HITBOX` | Hitboxes (deal damage) |
| 8 | `COLLISION_LAYER_HURTBOX` | Hurtboxes (receive damage) |

### Z-Index System
| z_index | Element |
|---------|---------|
| 0 | Tilemap |
| 1 | Player, North-facing projectiles |
| 2 | South/side-facing projectiles, Enemies |
| 10 | HUD (health/mana/stamina bars) |
| 19 | Spell Bar |
| 20 | Inventory UI (when implemented) |

---

## Spell System

### Elements
The game features four elemental magic types:
- **Fire** (Red) - High damage, balanced mana cost
- **Water** (Cyan) - Balanced damage and cost
- **Earth** (Green) - Highest damage, highest mana cost
- **Air** (Light Blue) - Low damage, lowest mana cost

### Spell Leveling
- Each element levels independently
- Gain XP by hitting enemies with spells
- XP formula: `level * 100` XP required per level
- Level bonus: `(level - 1) * 5` additional damage

### Damage Calculation
```
Final Damage = Base Damage + (INT * 2) + ((Element Level - 1) * 5)
```

Where:
- **Base Damage**: From SpellData resource
- **INT Bonus**: Player Intelligence stat × 2
- **Level Bonus**: Element level × 5 (minus 5 for level 1)

### Default Spells (Slots 1-4)
1. **Fireball** - Fire element, 15 base damage, 10 mana
2. **Waterball** - Water element, 12 base damage, 12 mana
3. **Earthball** - Earth element, 20 base damage, 15 mana
4. **Airball** - Air element, 10 base damage, 8 mana

---

## Combat Stats

### Player
| Stat | Value |
|------|-------|
| Walk Speed | 120 |
| Run Speed | 220 |
| Base Health | 100 (VIT * 20) |
| Base Mana | 75 (INT * 15) |
| Base Stamina | 50 (Agility * 10) |
| Base Stats | Resilience: 1, Agility: 1, INT: 1, VIT: 1 |

### Orc Enemy
| Stat | Value |
|------|-------|
| Health | 80 |
| Move Speed | 70 |
| Attack Damage | 15 |
| Attack Range | 45 |
| Detection Range | 200 |
| Attack Cooldown | 1.5s |
| Leash Distance | 300 |

---

## Milestone Progress

### ✅ Milestone 1: Foundation (Complete)
- Data architecture (SpellData, stubs for ItemData/EquipmentData/MerchantData)
- PlayerStats & EventBus autoloads
- HUD system (health, mana, stamina bars)

### ✅ Milestone 2: Inventory & Equipment (Complete)
- InventorySystem autoload with slot-based inventory
- Equipment system with 10 equipment slots
- Inventory UI and Equipment UI implemented
- ItemData and EquipmentData resources fully implemented

### ✅ Milestone 3: Elemental Spells (Complete)
- SpellSystem with element leveling
- 4 element-specific projectiles and impacts
- 10-slot spell hotbar
- Element-specific icons
- XP gain on spell hit

### 📋 Milestone 4: Crafting & Chests (Next)
- CraftingSystem autoload
- Crafting UI
- Chest objects with loot

### 📋 Milestone 5: Currency & Merchant (Future)
- Currency system integration
- Merchant NPC
- Merchant UI
- Pause menu

See `MILESTONE_STATUS.md` for detailed progress tracking.

---

## Requirements

- **Godot Engine**: 4.5+
- **Platform**: Cross-platform (tested on macOS)

---

## Documentation

- **SPEC.md** - Complete system specification (naming conventions, milestones, file structure)
- **CONTEXT.md** - Complete system overview and architecture
- **ARCHITECTURE_GUIDELINES.md** - Data flow patterns and worker pattern guidelines
- **ERROR_HANDLING_GUIDELINES.md** - Error handling patterns and best practices
- **TESTING_CHECKLIST.md** - Manual testing procedures
- **SKILL_STATS_LIST.md** - Base stats and element levels reference

---

## License

All rights reserved.
