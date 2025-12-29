# ShroomLands Asset Pack Setup Guide

## Asset Organization

The Cute_Fantasy_ShroomLands asset pack has been added to:
```
assets/Cute_Fantasy_ShroomLands/
├── Tiles/          # Tile textures for TileMap
├── Houses/              # Building sprites
├── Props/             # Decorative elements (mushrooms, rocks)
├── Shroomlings/       # Character sprites
└── Snails/            # Creature sprites
```

## Tile Information

Based on file analysis:
- **Grass Tiles**: 176 x 192 pixels (11 tiles × 12 tiles at 16x16 each)
- **Cliff Tiles**: 144 x 192 pixels (9 tiles × 12 tiles at 16x16 each)
- **Cliff Waterfall**: 288 x 80 pixels (18 tiles × 5 tiles at 16x16 each)
- **Tile Size**: 16x16 pixels (standard RPG tile size)

## Setup Steps

### 1. Create TileSet Resources

You'll need to create TileSet resources (.tres files) for each tile texture:

1. In Godot, go to **File > New Resource**
2. Select **TileSet** as the resource type
3. Add an **Atlas Source** for each tile texture
4. Configure the tile size (likely 16x16 based on standard tile sizes)
5. Save as `.tres` files in `assets/Cute_Fantasy_ShroomLands/tilesets/`

### 2. Create a New World Scene

Create a new world scene specifically for the ShroomLands:
- `scenes/worlds/shroomlands.tscn`

### 3. Use Assets

- **Tiles**: Use in TileMap nodes for terrain
- **Houses**: Static sprites for buildings
- **Props**: Decorative elements (can be StaticBody2D or Area2D)
- **Shroomlings**: NPCs or enemies
- **Snails**: Creatures or NPCs

## Setup Complete

I've created a basic ShroomLands world scene at:
- `scenes/worlds/shroomlands.tscn`

This scene includes:
- A TileMap node configured for 16x16 tiles
- A TileSet using the green grass tiles as a starting point
- Ready for you to paint tiles in the Godot editor

## Next Steps

1. **Open the scene in Godot**: `scenes/worlds/shroomlands.tscn`
2. **Configure the TileSet**:
   - Select the TileMap node
   - In the TileSet panel, you'll need to configure the atlas source
   - The grass tiles are 176x192 (11×12 tiles at 16x16 each)
   - Set the atlas source texture and configure tile regions
3. **Add more tile sources**: Add atlas sources for other tile types (cliffs, waterfalls, etc.)
4. **Paint your world**: Use the TileMap painting tools to create your ShroomLands
5. **Add props and characters**: Use the Houses, Props, Shroomlings, and Snails as Sprite2D nodes

## Using the Assets

### Tiles (TileMap)
- Use in TileMap nodes for terrain
- Each tile texture contains multiple tiles in a grid
- Standard tile size: 16×16 pixels

### Houses, Props, Characters (Sprites)
- Use as Sprite2D nodes for static elements
- Houses can be StaticBody2D for collision
- Shroomlings and Snails can be CharacterBody2D for NPCs/enemies

