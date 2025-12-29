# Player Interface Panel Design Document

**Date**: Current Session  
**Status**: Design Phase  
**Reference**: RuneScape-style quick access bar and stats panel

---

## Overview

A modular player interface panel on the right side of the screen providing:
1. **Quick Belt** - 5 consumable item slots (mapped to inventory slots 0-4)
2. **Stats/XP Panel** - Element levels and XP progress bars
3. **Settings Tab** - Game settings (placeholder for future)

---

## Design Principles (Based on Research)

### From UI/UX Best Practices:
1. **Modular Interface with Tabs** - Separate concerns into distinct tabs
2. **Consistent Layout & Spacing** - Uniform spacing aids navigation
3. **Clear Visual Hierarchy** - Important info stands out
4. **Color Coding** - Different colors for different elements/types
5. **Responsive Feedback** - Visual cues for interactions
6. **Customization Ready** - Structure allows future customization

---

## Panel Specifications

### Dimensions
- **Width**: 180px
- **Height**: 220px (adjustable if needed)
- **Position**: Right side of screen
- **Anchor**: Top-right corner with margin
- **Z-Index**: CanvasLayer layer = 15 (between HUD=10 and SpellBar=19)

### Structure

```
PlayerPanel (CanvasLayer, layer=15)
└── Control (anchored to top-right, size 180x220)
    ├── Background (ColorRect/PanelContainer - semi-transparent dark)
    └── VBoxContainer
        ├── TabBar (HBoxContainer - 3 tabs)
        │   ├── Tab Button: Quick Belt
        │   ├── Tab Button: Stats
        │   └── Tab Button: Settings
        └── TabContent (Control - content area)
            ├── QuickBeltTab (visible when selected)
            │   └── VBoxContainer
            │       ├── Label: "Quick Belt"
            │       └── HBoxContainer (5 quick slots)
            │           ├── QuickSlot1
            │           ├── QuickSlot2
            │           ├── QuickSlot3
            │           ├── QuickSlot4
            │           └── QuickSlot5
            ├── StatsTab (visible when selected)
            │   └── VBoxContainer
            │       ├── Label: "Element Levels"
            │       ├── ElementStat (Fire)
            │       │   ├── Label: "Fire Lv. X"
            │       │   └── ProgressBar (XP bar)
            │       ├── ElementStat (Water)
            │       ├── ElementStat (Earth)
            │       └── ElementStat (Air)
            └── SettingsTab (visible when selected)
                └── VBoxContainer
                    └── Label: "Settings (Coming Soon)"
```

---

## Tab 1: Quick Belt

### Purpose
Quick access to consumable items (potions, food, etc.) without opening inventory.

### Design
- **5 slots** arranged horizontally
- Each slot displays:
  - Item icon (32x32 or 40x40)
  - Item count (if stackable, bottom-right corner)
  - Empty slot visual (subtle border when empty)
- **Key Bindings**: F1-F5 (or 1-5 numpad) to use items
- **Sync**: Automatically syncs with InventorySystem slots 0-4

### Visual Design
- Slot size: 32x32px or 40x40px
- Spacing: 4px between slots
- Border: 2px when empty, colored border when filled
- Count label: Small font, bottom-right overlay
- Tooltip: Show item name and description on hover

### Interaction
- Click slot to use item (if consumable)
- Right-click for context menu (future: drop, examine)
- Visual feedback: Brief highlight when item is used
- Empty slots show placeholder icon/text

---

## Tab 2: Stats/XP Panel

### Purpose
Display element levels and XP progression for all 4 elements.

### Design
- **4 Element Rows** (Fire, Water, Earth, Air)
- Each row displays:
  - Element icon/color indicator (small square or icon)
  - Element name + Level (e.g., "Fire Lv. 5")
  - XP Progress Bar
    - Current XP / XP needed for next level
    - Percentage fill
    - Color-coded by element

### Visual Design
- Row height: ~40px each (4 rows = 160px + spacing)
- Element indicator: 16x16px colored square
- Level text: Medium font
- XP bar: ProgressBar style
  - Fire: Red/Orange gradient
  - Water: Blue/Cyan gradient
  - Earth: Brown/Green gradient
  - Air: Light Blue/White gradient
- XP text: "XXX / YYY" below or inside bar

### Data Source
- **SpellSystem**:
  - `get_level(element)` - current level
  - `get_xp(element)` - current XP
  - `get_xp_for_next_level(element)` - XP needed

---

## Tab 3: Settings

### Purpose
Game settings and options (placeholder for Milestone 5).

### Design
- Simple placeholder for now
- Label: "Settings (Coming Soon)"
- Structure ready for future:
  - Graphics settings
  - Audio settings
  - Controls/keybindings
  - UI scale

---

## Technical Implementation

### File Structure

```
scenes/ui/
└── player_panel.tscn          # Main panel scene

scripts/ui/
├── player_panel.gd            # Main panel controller
├── quick_belt_tab.gd          # Quick belt tab logic
├── quick_belt_slot.gd         # Individual quick slot component
├── stats_tab.gd               # Stats/XP tab logic
└── element_stat_row.gd        # Individual element stat row
```

### Integration Points

1. **InventorySystem**:
   - Listen to `inventory_changed` signal
   - Sync slots 0-4 to quick belt slots 1-5
   - Handle item usage (remove from inventory)

2. **SpellSystem**:
   - Listen to `xp_gained` and `element_leveled_up` signals
   - Update XP bars when XP changes
   - Update level text when level changes

3. **PlayerStats** (future):
   - Could display base stats here too
   - Health/Mana/Stamina bars (or keep in HUD)

### Signals to Connect

```gdscript
# In player_panel.gd _ready()
InventorySystem.inventory_changed.connect(_on_inventory_changed)
SpellSystem.xp_gained.connect(_on_xp_gained)
SpellSystem.element_leveled_up.connect(_on_element_leveled_up)
```

### Input Actions

Add to `project.godot`:
- `quick_item_1` → F1
- `quick_item_2` → F2
- `quick_item_3` → F3
- `quick_item_4` → F4
- `quick_item_5` → F5

---

## Color Scheme

### Element Colors (matching spell system)
- **Fire**: Red (#FF4444 / RGB: 255, 68, 68)
- **Water**: Cyan (#44AAFF / RGB: 68, 170, 255)
- **Earth**: Green (#44AA44 / RGB: 68, 170, 68)
- **Air**: Light Blue (#88CCFF / RGB: 136, 204, 255)

### UI Colors
- **Background**: Dark semi-transparent (#1A1A1AAA)
- **Border**: Medium gray (#666666)
- **Selected Tab**: Gold/Yellow accent (#FFD700)
- **Slot Empty**: Dark gray border (#333333)
- **Slot Filled**: White/light border (#CCCCCC)

---

## Future Enhancements

1. **Quick Belt**:
   - Drag & drop from inventory
   - Key binding customization
   - Cooldown indicators for consumables
   - Item tooltips on hover

2. **Stats Panel**:
   - Base stats display (STR, DEX, INT, VIT)
   - Total stats with equipment bonuses
   - Mini character model preview

3. **Settings**:
   - Full settings implementation (Milestone 5)
   - Graphics quality
   - Audio volume
   - Keybindings

4. **Panel Customization**:
   - Resizable panel
   - Draggable position
   - Collapsible/minimizable
   - Tab reordering

---

## Notes

- Panel should be always visible (no toggle, but can be minimized/collapsed)
- Ensure it doesn't overlap with spell hotbar (which is bottom-center)
- Test with different screen resolutions
- Keep consistent with existing UI style (HUD, spell bar)

---

**End of Design Document**

