# Autotiling Implementation Guide

## What I've Done

I've added the ShroomLands grass tiles to the overworld TileSet. The tiles are now available as a new Atlas Source in the TileSet.

## Next Steps - Configuring Autotiling in Godot Editor

**CRITICAL**: Terrain autotiling MUST be configured in the Godot editor. The .tscn file format doesn't fully represent terrain sets, so manual configuration is required.

### Step-by-Step Autotiling Setup:

1. **Open the Overworld Scene**:
   - Open `scenes/worlds/overworld.tscn` in Godot
   - Select the `TileMapLayer` node

2. **Open TileSet Editor**:
   - In the bottom panel, click on the "TileSet" tab
   - You should see your existing tiles and the new ShroomLands tiles

3. **Create a Terrain Set**:
   - At the top of the TileSet editor, you'll see "Terrain Sets"
   - Click the "+" button to add a new terrain set
   - Name it "ShroomLands_Grass" (or similar)

4. **Configure Terrain Set**:
   - Select the new terrain set
   - Set "Mode" to "Match Corners and Sides" (or "Match Corners" depending on your preference)
   - This mode checks all 8 neighbors (corners and sides) when placing tiles

5. **Assign Tiles to Terrain**:
   - Select tiles from the ShroomLands atlas source (the new tiles I added)
   - In the right panel, find "Terrain" section
   - Assign them to:
     - **Terrain Set**: "ShroomLands_Grass" (or the ID of the terrain set you created)
     - **Terrain**: 0 (the terrain index within that set)

6. **Configure Terrain Peering**:
   - Still in the TileSet editor, select the terrain set you created
   - Click "Edit Terrain"
   - Configure which neighbors to check:
     - Enable: Top, Right, Bottom, Left (all four sides)
     - Match empty corners: Enable if you want tiles to match empty spaces
     - Match empty sides: Enable if you want tiles to connect only to same terrain

7. **Set Up Tile Patterns** (16-tile autotile pattern):
   - The first 16 tiles in your atlas should follow the standard autotile pattern
   - Pattern layout (4x4 grid):
     ```
     0   1   2   3
     4   5   6   7
     8   9  10  11
    12  13  14  15
     ```
   - For each tile position (0-15), set the terrain peering bits that match that pattern
   - Godot will automatically select the correct tile based on neighbors

8. **Use Terrain Paint Mode**:
   - Select the TileMapLayer
   - In the toolbar, select "Paint" mode → "Terrain Paint"
   - Choose your terrain set from the dropdown
   - Now when you paint, tiles will automatically connect based on neighbors!

## Understanding the 16-Tile Pattern

The standard autotile pattern works like this:

- **Tile 0** (0,0): No neighbors → Isolated tile
- **Tiles 1-7**: Edges and corners with 1-3 sides connected
- **Tiles 8-11**: Tiles with 3 sides connected
- **Tiles 12-14**: Inner corner tiles
- **Tile 15**: All 4 sides connected → Fully surrounded tile

Godot checks neighbors using bitmasks:
- Bit 0: Top
- Bit 1: Right  
- Bit 2: Bottom
- Bit 3: Left

Each tile in the pattern corresponds to a specific bitmask value (0-15).

## Tile Layout in ShroomLands Assets

Based on the 176×192 pixel dimensions (11 tiles × 12 tiles):
- **Tile size**: 16×16 pixels
- **Grid**: 11 tiles wide × 12 tiles tall

The first 11 tiles of the first row (or first 4 rows if using 4×4 pattern) should be configured for autotiling.

## Additional Resources

- [Godot 4 TileSet Documentation](https://docs.godotengine.org/en/stable/classes/class_tileset.html)
- [Terrain Autotiling Tutorial](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html#terrain-autotiling)

The tiles are now in the TileSet and ready for autotiling configuration!

