# Green Alderson Adventures

A Godot 4.5 top-down action RPG with multi-element spell system, elemental leveling, and melee enemy AI.

**Current Status**: Milestone 3 Complete - Elemental Spells system fully implemented. Moving to Milestone 4 (Crafting & Chests).

---

## Controls

| Action | Keys |
|--------|------|
| Move | W/A/S/D or Arrow Keys |
| Run | Ctrl + Direction |
| Jump | Space (while running) |
| Select/Cast Spell | 1-9, 0 (number keys) |
| Open Inventory | I *(Coming in Milestone 2)* |
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

### Technical ✅

- **Object Pooling** - Optimized projectile system that reuses objects
- **Animation System** - Smooth transitions between all action states
- **Z-Index Layering** - Proper depth sorting for north vs south-facing projectiles
- **Coordinator/Worker Pattern** - Clean architecture preventing code drift

---

## Project Structure

```
├── scripts/
│   ├── player.gd              # Player coordinator (movement, spells, combat)
│   ├── constants.gd           # Game constants
│   ├── enemies/
│   │   ├── base_enemy.gd      # Base enemy AI with state machine
│   │   └── orc_1.gd           # Orc enemy stats
│   ├── projectiles/
│   │   ├── spell_projectile.gd  # Generic projectile script (element-agnostic)
│   │   └── impact.gd          # Impact effect on collision
│   ├── resources/             # Resource class definitions
│   │   ├── spell_data.gd      # SpellData resource class
│   │   ├── item_data.gd       # ItemData stub (for inventory system)
│   │   ├── equipment_data.gd  # EquipmentData stub
│   │   └── merchant_data.gd   # MerchantData stub
│   ├── systems/               # Autoload singletons
│   │   ├── player_stats.gd    # Player attributes, health, mana, stamina, stats
│   │   ├── event_bus.gd       # Central signal hub
│   │   ├── inventory_system.gd # Inventory & equipment management
│   │   ├── spell_system.gd    # Element leveling and spell progression
│   │   └── projectile_pool.gd # Object pooling for performance
│   ├── ui/                    # UI component scripts
│   │   ├── health_bar.gd      # Health bar component
│   │   ├── resource_bar.gd    # Generic resource bar (mana/stamina)
│   │   ├── spell_bar.gd       # Spell hotbar controller
│   │   ├── spell_slot.gd      # Individual spell slot
│   │   └── enemy_health_bar.gd # Enemy health bar
│   └── workers/               # Reusable single-purpose components
│       ├── animator.gd        # Animation playback
│       ├── health_tracker.gd  # Health management
│       ├── hitbox.gd          # Deals damage
│       ├── hurtbox.gd         # Receives damage
│       ├── input_reader.gd    # Player input handling
│       ├── mover.gd           # Movement & knockback
│       ├── spell_spawner.gd   # Spell instantiation
│       └── target_tracker.gd  # Enemy target tracking

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
| Layer | Purpose |
|-------|---------|
| 1 | Terrain/Walls |
| 2 | Projectiles |
| 4 | Hitboxes (deal damage) |
| 8 | Hurtboxes (receive damage) |

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
| Base Stamina | 50 (DEX * 10) |
| Base Stats | STR: 5, DEX: 5, INT: 5, VIT: 5 |

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

### ⚠️ Milestone 2: Inventory & Equipment (Partial)
- InventorySystem autoload exists
- UI scenes exist
- **Status**: Needs full ItemData/EquipmentData implementation

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
- **CONTEXT.md** - Spell hotbar system implementation details
- **MILESTONE_STATUS.md** - Detailed milestone progress tracking
- **COMMIT_NOTES.md** - Recent commit summaries

---

## License

All rights reserved.
