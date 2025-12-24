# Green Alderson Adventures

A Godot 4.5 top-down action game with 8-directional player movement and a fireball projectile system with object pooling for performance.

## Controls

| Action | Keys |
|--------|------|
| Move | W/A/S/D or Arrow Keys |
| Run | Ctrl + Direction |
| Jump | Space (while running) |
| Cast Fireball | Q |

## Project Structure

```
├── scripts/                   # GDScript files
│   ├── player.gd              # Player movement, animations, fireball casting
│   ├── fireball.gd            # Fireball projectile behavior
│   ├── impact.gd              # Impact effect on fireball collision
│   ├── projectile_pool.gd     # Object pooling system for performance
│   └── constants.gd           # Game constants
│
├── scenes/                    # Godot scene files (.tscn)
│   ├── main.tscn              # Main game scene (entry point)
│   ├── player.tscn            # Player character with animations
│   ├── fireball.tscn          # Fireball projectile
│   ├── impact.tscn            # Impact effect
│   ├── projectile_pool.tscn   # Pooling system node
│   └── overworld.tscn         # Tilemap/world
│
├── animations/                # Sprite assets (8 directions)
└── Texture/                   # Tileset textures
```

## Features

- **8-Directional Movement** - Full directional movement with walk and run speeds
- **Fireball Casting** - Cast fireballs in any direction while moving
- **Object Pooling** - Optimized projectile system that reuses objects
- **Animation System** - Smooth transitions between idle, walk, run, jump, and cast animations
- **Z-Index Layering** - Proper depth sorting for north vs south-facing projectiles

## Technical Details

### Scripts

| Script | Description |
|--------|-------------|
| `player.gd` | Handles input, movement, and fireball casting with 0.5s cast delay |
| `fireball.gd` | Projectile with collision detection, lifetime, and pool integration |
| `impact.gd` | Impact effect that auto-returns to pool after animation |
| `projectile_pool.gd` | Object pooling for fireballs (20) and impacts (10) |
| `constants.gd` | Centralized game constants |

### Collision Layers

| Layer | Purpose |
|-------|---------|
| 1 | Terrain/Walls |
| 2 | Projectiles |

### Z-Index

| z_index | Element |
|---------|---------|
| 0 | Tilemap |
| 1 | Player, North-facing fireballs |
| 2 | South/side-facing fireballs |

## Requirements

- Godot Engine 4.5+

## License

All rights reserved.

