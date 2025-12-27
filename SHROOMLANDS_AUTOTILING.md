# ShroomLands Autotiling Implementation Guide

## Understanding the Tile Structure

Based on analysis:
- **Tile Size**: 16×16 pixels (confirmed)
- **Grass Tiles**: 176×192 = 11 tiles × 12 tiles
  - This suggests a pattern: 11 tiles wide could be:
    - 3 sets of 3-tile patterns + 2 edge tiles = 11
    - Or a 16-tile autotile pattern split across multiple rows
- **Standard Pattern**: Most RPG tilesets use a 4×4 (16-tile) autotile pattern

## Godot 4 Terrain Autotiling System

### Key Concepts

1. **Terrain Set**: A group of tiles that connect to each other
2. **Terrain Mode**: How tiles connect (match corners, match sides, etc.)
3. **Peering Bits**: Which neighbors to check (top-left, top, top-right, left, right, bottom-left, bottom, bottom-right)
4. **Terrain Peering**: Rules for how different terrains interact

### Standard 16-Tile Autotile Pattern

```
Pattern in texture (4×4 grid):
┌────┬────┬────┬────┐
│  0 │  1 │  2 │  3 │  Row 0: Isolated/Edges
├────┼────┼────┼────┤
│  4 │  5 │  6 │  7 │  Row 1: Edges/Inner corners
├────┼────┼────┼────┤
│  8 │  9 │ 10 │ 11 │  Row 2: Outer corners
├────┼────┼────┼────┤
│ 12 │ 13 │ 14 │ 15 │  Row 3: Fully connected
└────┴────┴────┴────┘

Bitmask values:
0  = 0000 - No neighbors
1  = 0001 - Right only
2  = 0010 - Bottom only
3  = 0011 - Right + Bottom
4  = 0100 - Left only
5  = 0101 - Left + Right
6  = 0110 - Left + Bottom
7  = 0111 - Left + Right + Bottom
8  = 1000 - Top only
9  = 1001 - Top + Right
10 = 1010 - Top + Bottom
11 = 1011 - Top + Right + Bottom
12 = 1100 - Top + Left
13 = 1101 - Top + Left + Right
14 = 1110 - Top + Left + Bottom
15 = 1111 - All neighbors
```

## Implementation Steps for Overworld

1. **Add ShroomLands Tiles to TileSet**:
   - Open overworld.tscn
   - Select TileMapLayer → Edit TileSet
   - Add new Atlas Source for ShroomLands_Grass_Green_Tiles.png
   - Set tile size to 16×16
   - Configure atlas to detect tiles (11×12 grid)

2. **Create Terrain Set**:
   - In TileSet editor: Click "+" next to "Terrain Sets"
   - Name it "ShroomLands_Grass" or similar
   - Set terrain mode to "Match Corners and Sides"

3. **Assign Terrain to Tiles**:
   - Select the first 16 tiles (assuming standard pattern)
   - Assign to terrain set 0, terrain 0
   - This creates the autotile connection rules

4. **Configure Peering**:
   - Each terrain needs peering configuration
   - Set which sides connect (usually all 4: top, right, bottom, left)
   - Configure match empty corners/sides

5. **Use Terrain Paint Mode**:
   - In TileMap: Select "Terrain Paint" tool
   - Choose terrain from dropdown
   - Paint and tiles auto-connect

## Next Steps

I'll modify the overworld.tscn to add:
1. Atlas sources for ShroomLands tiles
2. Terrain sets with autotiling configured
3. Proper bitmask patterns for each tile type

