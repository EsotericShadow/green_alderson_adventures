# Green Alderson Adventures

A Godot 4.5 top-down action RPG with 8-directional player movement, fireball spell system, and melee enemy AI.

## Controls

| Action | Keys |
|--------|------|
| Move | W/A/S/D or Arrow Keys |
| Run | Ctrl + Direction |
| Jump | Space (while running) |
| Cast Fireball | Q |

## Features

- **8-Directional Movement** - Full directional movement with walk/run speeds
- **Fireball Casting** - Cast fireballs in any direction while moving (0.35s wind-up)
- **Orc Enemy AI** - Melee enemy with detection, chase, attack, hurt, and death states
- **Combat System** - Hitbox/Hurtbox collision with invincibility frames
- **Screen Shake** - Camera shake on player hit
- **Visual Feedback** - Enemy flashes red when damaged
- **Object Pooling** - Optimized projectile system that reuses objects
- **Animation System** - Smooth transitions between all action states
- **Z-Index Layering** - Proper depth sorting for north vs south-facing projectiles

## Project Structure

```
├── scripts/
│   ├── player.gd              # Player coordinator (movement, spells, combat)
│   ├── constants.gd           # Game constants
│   ├── enemies/
│   │   ├── base_enemy.gd      # Base enemy AI with state machine
│   │   └── orc_1.gd           # Orc enemy stats
│   ├── projectiles/
│   │   ├── fireball.gd        # Fireball projectile behavior
│   │   └── impact.gd          # Impact effect on collision
│   ├── systems/
│   │   └── projectile_pool.gd # Object pooling for performance
│   └── workers/               # Reusable single-purpose components
│       ├── animator.gd        # Animation playback
│       ├── health_tracker.gd  # Health management
│       ├── hitbox.gd          # Deals damage
│       ├── hurtbox.gd         # Receives damage
│       ├── input_reader.gd    # Player input handling
│       ├── mover.gd           # Movement & knockback
│       ├── spell_spawner.gd   # Spell instantiation
│       └── target_tracker.gd  # Enemy target tracking
│
├── scenes/
│   ├── main.tscn              # Main game scene (entry point)
│   ├── player.tscn            # Player character
│   ├── fireball.tscn          # Fireball projectile
│   ├── impact.tscn            # Impact effect
│   ├── projectile_pool.tscn   # Pooling system
│   ├── overworld.tscn         # Tilemap/world
│   └── enemies/
│       └── orc_1.tscn         # Orc enemy
│
├── animations/
│   ├── player/                # Player sprite sheets (8 directions)
│   ├── orc_1/                 # Orc sprite sheets (4 directions)
│   └── spells/                # Spell effect sprites
│
└── Texture/                   # Tileset textures
```

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
| 2 | Player body |
| 4 | Hitboxes (deal damage) |
| 8 | Hurtboxes (receive damage) |

### Z-Index
| z_index | Element |
|---------|---------|
| 0 | Tilemap |
| 1 | Player, North-facing fireballs |
| 2 | South/side-facing fireballs, Enemies |

## Combat Stats

### Player
| Stat | Value |
|------|-------|
| Walk Speed | 120 |
| Run Speed | 220 |
| Max Health | 100 |
| Fireball Damage | 25 |
| Fireball Cooldown | 0.6s |
| Cast Delay | 0.35s |

### Orc
| Stat | Value |
|------|-------|
| Health | 80 |
| Move Speed | 70 |
| Attack Damage | 15 |
| Attack Range | 45 |
| Detection Range | 200 |
| Attack Cooldown | 0.9s |
| Leash Distance | 300 |

## Requirements

- Godot Engine 4.5+

## License

All rights reserved.
