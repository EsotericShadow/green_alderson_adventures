# Scene Path Fixes - Broken Dependencies Resolved

**Date**: 2025-12-28  
**Issue**: Scene files had broken dependencies due to hierarchical refactoring  
**Status**: ✅ All scene paths updated

---

## Problem

After the hierarchical refactoring (commit `21b191f`), UI scripts were moved from:
- `scripts/ui/` (flat structure)

To:
- `scripts/ui/bars/` (resource bars, spell bar, tool belt)
- `scripts/ui/slots/` (all slot types)
- `scripts/ui/tabs/` (inventory, equipment, stats tabs)
- `scripts/ui/rows/` (stat rows)
- `scripts/ui/panels/` (player panel)
- `scripts/ui/inventory/` (inventory UI)

But scene files still referenced the old flat paths, causing broken dependencies.

---

## Files Fixed (12 scene files)

### Bars (5 files)
1. ✅ `scenes/ui/enemy_health_bar.tscn`
   - `scripts/ui/enemy_health_bar.gd` → `scripts/ui/bars/enemy_health_bar.gd`

2. ✅ `scenes/ui/health_bar.tscn`
   - `scripts/ui/resource_bar.gd` → `scripts/ui/bars/resource_bar.gd`

3. ✅ `scenes/ui/mana_bar.tscn`
   - `scripts/ui/resource_bar.gd` → `scripts/ui/bars/resource_bar.gd`

4. ✅ `scenes/ui/stamina_bar.tscn`
   - `scripts/ui/resource_bar.gd` → `scripts/ui/bars/resource_bar.gd`

5. ✅ `scenes/ui/spell_bar.tscn`
   - `scripts/ui/spell_bar.gd` → `scripts/ui/bars/spell_bar.gd`

6. ✅ `scenes/ui/tool_belt.tscn`
   - `scripts/ui/tool_belt.gd` → `scripts/ui/bars/tool_belt.gd`

### Slots (4 files)
7. ✅ `scenes/ui/spell_slot.tscn`
   - `scripts/ui/spell_slot.gd` → `scripts/ui/slots/spell_slot.gd`

8. ✅ `scenes/ui/inventory_slot.tscn`
   - `scripts/ui/inventory_slot.gd` → `scripts/ui/slots/inventory_slot.gd`

9. ✅ `scenes/ui/equip_slot.tscn`
   - `scripts/ui/equip_slot.gd` → `scripts/ui/slots/equip_slot.gd`

10. ✅ `scenes/ui/quick_belt_slot.tscn`
    - `scripts/ui/quick_belt_slot.gd` → `scripts/ui/slots/quick_belt_slot.gd`

### Other UI (2 files)
11. ✅ `scenes/ui/inventory_ui.tscn`
    - `scripts/ui/inventory_ui.gd` → `scripts/ui/inventory/inventory_ui.gd`

12. ✅ `scenes/ui/player_panel.tscn` (6 script references)
    - `scripts/ui/player_panel.gd` → `scripts/ui/panels/player_panel.gd`
    - `scripts/ui/inventory_tab.gd` → `scripts/ui/tabs/inventory_tab.gd`
    - `scripts/ui/equipment_tab.gd` → `scripts/ui/tabs/equipment_tab.gd`
    - `scripts/ui/stats_tab.gd` → `scripts/ui/tabs/stats_tab.gd`
    - `scripts/ui/base_stat_row.gd` → `scripts/ui/rows/base_stat_row.gd`
    - `scripts/ui/element_stat_row.gd` → `scripts/ui/rows/element_stat_row.gd`

---

## Path Mapping Summary

| Old Path | New Path |
|----------|----------|
| `scripts/ui/enemy_health_bar.gd` | `scripts/ui/bars/enemy_health_bar.gd` |
| `scripts/ui/resource_bar.gd` | `scripts/ui/bars/resource_bar.gd` |
| `scripts/ui/spell_bar.gd` | `scripts/ui/bars/spell_bar.gd` |
| `scripts/ui/tool_belt.gd` | `scripts/ui/bars/tool_belt.gd` |
| `scripts/ui/spell_slot.gd` | `scripts/ui/slots/spell_slot.gd` |
| `scripts/ui/inventory_slot.gd` | `scripts/ui/slots/inventory_slot.gd` |
| `scripts/ui/equip_slot.gd` | `scripts/ui/slots/equip_slot.gd` |
| `scripts/ui/quick_belt_slot.gd` | `scripts/ui/slots/quick_belt_slot.gd` |
| `scripts/ui/inventory_ui.gd` | `scripts/ui/inventory/inventory_ui.gd` |
| `scripts/ui/player_panel.gd` | `scripts/ui/panels/player_panel.gd` |
| `scripts/ui/inventory_tab.gd` | `scripts/ui/tabs/inventory_tab.gd` |
| `scripts/ui/equipment_tab.gd` | `scripts/ui/tabs/equipment_tab.gd` |
| `scripts/ui/stats_tab.gd` | `scripts/ui/tabs/stats_tab.gd` |
| `scripts/ui/base_stat_row.gd` | `scripts/ui/rows/base_stat_row.gd` |
| `scripts/ui/element_stat_row.gd` | `scripts/ui/rows/element_stat_row.gd` |

---

## Verification

All scene files now reference the correct hierarchical paths. The broken dependencies should be resolved.

**Next Step**: Open Godot and verify all scenes load without errors.

---

**End of Fix Summary**

