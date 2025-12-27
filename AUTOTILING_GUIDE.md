# Godot 4 Autotiling Guide for ShroomLands

## Understanding Autotiling

Autotiling in Godot 4 uses **Terrain Sets** with bitmask patterns. Here's how it works:

### Terrain Autotiling System

1. **Terrain Sets**: Group tiles that can connect to each other
2. **Bitmask Patterns**: 3x3 grid checking neighbors (16 possible combinations)
3. **Peering Bits**: Checks adjacent tiles (top, right, bottom, left corners and edges)

### Standard 16-Tile Autotile Pattern

The classic autotile pattern uses 16 tiles arranged in a 4x4 grid:

```
 0   1   2   3
 4   5   6   7
 8   9  10  11
12  13  14  15
```

Where:
- **0**: Isolated tile (no neighbors)
- **1-7**: Edge tiles (1-2 sides connected)
- **8-11**: Corner tiles (3 sides connected)
- **12-14**: Inner corner tiles
- **15**: Fully surrounded tile

### Setting Up Autotiling in Godot 4

1. **Create/Edit TileSet**:
   - Select TileMap → Open TileSet editor
   - Add Atlas Source with your tile texture
   - Set tile size (16x16 for ShroomLands)

2. **Create Terrain Set**:
   - Click "+" next to "Terrain Sets"
   - This creates a terrain set that tiles can belong to

3. **Assign Terrain to Tiles**:
   - Select tiles in the atlas
   - Assign them to terrain set
   - Assign terrain index (0, 1, 2, etc. for different terrain types)

4. **Configure Terrain Peering**:
   - Select terrain set → Edit Terrain
   - Set peering bits (which sides connect)
   - Configure match tiles to neighbor terrains

5. **Use Terrain Painting**:
   - In TileMap, select "Paint" tool
   - Choose terrain from dropdown
   - Paint and tiles auto-connect based on neighbors

## ShroomLands Tile Analysis

Based on the tile images:
- **Grass tiles**: 176×192 = 11 tiles wide × 12 tiles tall (likely includes autotile pattern)
- **Cliff tiles**: 144×192 = 9 tiles wide × 12 tiles tall
- Standard tile size: **16×16 pixels**

### Tile Layout Analysis Needed

The tiles likely follow one of these patterns:
1. **Standard 16-tile autotile** (4×4 grid)
2. **Extended pattern** with variations
3. **Different terrain types** (blue, green, purple grass variants)

## Implementation Steps

1. Open overworld.tscn
2. Select TileMap node
3. Open TileSet editor
4. Add new Atlas Source for ShroomLands tiles
5. Create Terrain Set
6. Configure autotiling rules
7. Paint terrain in the world

