# Milestone 2: Inventory & Equipment System - Research Summary

**Date**: 2024-12-24  
**Purpose**: Comprehensive research findings and best practices for implementing inventory and equipment systems in Godot 4.5.1

---

## 1. Inventory System Architecture

### 1.1 Data Structure Patterns

**Best Practice: Slot-Based Array with Dictionary Slots**
- Each slot is a Dictionary: `{ "item": ItemData or null, "count": int }`
- Array of slots: `Array[Dictionary]` - simple, fast, easy to serialize
- Alternative (not used): Separate arrays for items/counts - harder to maintain consistency
- **Why**: Dictionary slots allow null items (empty slots), easy to check `if slot["item"] == null`

**Capacity Management**
- Start with `DEFAULT_CAPACITY = 12` (3x4 grid, standard RPG size)
- Max capacity: `MAX_CAPACITY = 48` (expandable via upgrades)
- Expand by adding slots: `expand_capacity(additional_slots: int)`
- **Why**: Small starting capacity creates meaningful choices, expansion rewards progression

### 1.2 Item Stacking Logic

**Stackable Items**
- `ItemData.stackable: bool` - determines if item can stack
- `ItemData.max_stack: int` - maximum items per stack (default 99)
- Equipment items: `stackable = false`, `max_stack = 1` (enforced in `EquipmentData._init()`)

**Stacking Algorithm (Best Practice)**
1. Find existing stack of same item: `find_item_slot(item)`
2. If found and stackable:
   - Calculate space available: `max_stack - current_count`
   - Add to stack: `min(space_available, count_to_add)`
   - Return leftover: `count_to_add - added`
3. If no stack found or not stackable:
   - Find first empty slot
   - Place item(s) in new slot
   - Return leftover if capacity exceeded

**Why This Pattern**: Prevents duplicate stacks, maximizes space efficiency, handles edge cases (full stacks, mixed stackable/non-stackable)

### 1.3 Autoload Singleton Pattern

**Why Autoload for Inventory**
- Global access: `InventorySystem.add_item(item)`
- Persistent across scenes
- Single source of truth
- Signals work globally: `InventorySystem.inventory_changed.connect(...)`

**Integration with Existing Systems**
- `PlayerStats` already uses autoload pattern (proven architecture)
- `EventBus` for decoupled communication (inventory events)
- Follows existing codebase patterns

### 1.4 Signal-Based Updates

**Signals (Best Practice)**
- `inventory_changed` - general update (UI refresh)
- `item_added(item, count, slot_index)` - specific addition
- `item_removed(item, count, slot_index)` - specific removal
- `equipment_changed(slot_name)` - equipment slot update

**Why Signals**: Decouples UI from data layer, allows multiple listeners, follows Godot best practices

---

## 2. Equipment System Design

### 2.1 Equipment Slot Structure

**8 Slots (Industry Standard)**
- `head`, `body`, `gloves`, `boots` - armor slots
- `weapon`, `shield` - hand slots
- `ring1`, `ring2` - accessory slots (allows 2 rings, common RPG pattern)

**Dictionary Structure**
```gdscript
var equipment: Dictionary = {
    "head": null,      # EquipmentData or null
    "body": null,
    # ... etc
}
```

**Why Dictionary**: Easy lookup by slot name, clear slot names, simple null checks

### 2.2 Equipment Validation

**Type Checking**
- `EquipmentData.slot: String` - must match target slot name
- Validation in `equip()`: `if item.slot != slot_name: return false`
- Prevents wrong equipment in wrong slots (e.g., weapon in head slot)

**Unequip Logic**
- Returns previous equipment (if any) to inventory
- If inventory full, unequip fails (prevents item loss)
- **Best Practice**: Check inventory space before unequip

### 2.3 Stat Bonus Calculation

**Additive Stat Bonuses (Standard RPG Pattern)**
- Base stats from `PlayerStats` (base_str, base_dex, etc.)
- Equipment bonuses: `get_total_stat_bonus("str")` sums all equipped items
- Final stat: `base_stat + equipment_bonus`

**Why Additive**: Simple, predictable, easy to balance, industry standard

**Implementation Pattern**
```gdscript
func get_total_stat_bonus(stat_name: String) -> int:
    var total: int = 0
    for slot_name in equipment:
        var item = equipment[slot_name]
        if item != null:
            total += item.get(stat_name + "_bonus", 0)
    return total
```

**Integration with PlayerStats**
- `PlayerStats.get_total_str()` calls `InventorySystem.get_total_stat_bonus("str")`
- Same for dex, int, vit
- **Why**: Equipment affects derived stats (max_health, max_mana, max_stamina) automatically

---

## 3. UI/UX Best Practices

### 3.1 Inventory Grid Layout

**GridContainer (Godot Best Practice)**
- `columns = 4` - standard 4-column grid
- Auto-arranges slots, handles resizing
- Better than manual positioning

**Slot Size**
- `custom_minimum_size = (64, 64)` - standard item icon size
- Large enough for icons, small enough for dense grid
- Industry standard: 48-64px per slot

### 3.2 Slot Visual Design

**PanelContainer (Best Practice)**
- Provides background/border for slots
- Easy to style with themes
- Can show hover/selected states

**Slot Contents**
- `TextureRect` (icon) - `expand_mode = keep_aspect_centered`
- `Label` (count) - bottom-right anchor, only visible if `count > 1`
- Empty slots: show empty panel (no icon, no count)

**Why This Structure**: Clear visual hierarchy, easy to update, standard RPG pattern

### 3.3 Inventory Panel Layout

**Full-Screen Overlay Pattern**
- `Control` with `anchors: full_rect` - covers entire screen
- `ColorRect` dimmer (50% black) - darkens background
- Centered `PanelContainer` - inventory panel

**Why Overlay**: Pauses gameplay visually, focuses attention, standard RPG pattern

**Toggle Pattern**
- `visible = false` by default
- Toggle on `open_inventory` input action
- Emit `EventBus.inventory_opened` / `inventory_closed` signals

### 3.4 Equipment Panel Layout

**Side-by-Side Layout**
- `HBoxContainer` splits inventory and equipment
- Inventory: 4-column grid (left side)
- Equipment: 2-column grid (right side)

**Equipment Slot Labels**
- Show slot name (e.g., "Head", "Weapon")
- Show equipped item icon (if any)
- Click to unequip (future: drag to equip)

**Why Side-by-Side**: Easy comparison, standard RPG layout, efficient use of space

---

## 4. Performance Considerations

### 4.1 Slot Array Performance

**Array vs Dictionary for Slots**
- `Array[Dictionary]` - O(1) access by index, O(n) search
- Fast enough for 12-48 slots
- No need for hash map (Dictionary) for slot lookup

**Slot Operations**
- `find_item_slot()`: O(n) linear search - acceptable for small inventories
- `add_item()`: O(n) worst case - still fast for 48 slots
- **Optimization**: Only search if needed (stackable items)

### 4.2 UI Refresh Strategy

**Full Refresh vs Incremental**
- Full refresh: `_refresh_slots()` - recreates all slot UI nodes
- Incremental: Update only changed slots (more complex)
- **For MVP**: Full refresh is fine (12-48 slots, infrequent updates)

**Signal Optimization**
- `inventory_changed` - single signal for all changes
- UI connects once, refreshes on any change
- **Why**: Simple, decoupled, performant enough

### 4.3 Memory Management

**ItemData References**
- Slots store references to `ItemData` resources (not copies)
- Resources are loaded once, referenced many times
- **Why**: Memory efficient, single source of truth

**Scene Instancing**
- `InventorySlot` scenes instantiated on demand
- Can pool slots if needed (overkill for MVP)
- **For MVP**: Instantiate/destroy is fine

---

## 5. Integration with Existing Systems

### 5.1 PlayerStats Integration

**Stat Calculation Flow**
1. `PlayerStats.get_total_str()` called
2. Gets base stat: `base_str`
3. Gets equipment bonus: `InventorySystem.get_total_stat_bonus("str")`
4. Returns: `base_str + bonus`
5. Derived stats (max_health, etc.) recalculate automatically

**Why This Works**: Equipment bonuses affect derived stats immediately, no manual updates needed

### 5.2 EventBus Integration

**Inventory Events**
- `EventBus.item_picked_up(item, count)` - when item collected
- `EventBus.item_used(item)` - when consumable used
- Inventory UI listens to `EventBus.inventory_opened` (if needed)

**Why EventBus**: Decouples systems, allows multiple listeners, follows existing pattern

### 5.3 ItemData Resource System

**Custom Resources (Already Implemented)**
- `ItemData` - base class (stackable, icon, etc.)
- `EquipmentData` - extends ItemData (slot, stat bonuses)
- `.tres` files in `resources/items/` and `resources/equipment/`

**Why Resources**: Data-driven, easy to edit in Godot editor, no code changes for new items

---

## 6. Implementation Checklist

### Commit 2A: Inventory Data Layer
- [x] Create `InventorySystem` autoload
- [ ] Implement slot array initialization
- [ ] Implement `add_item()` with stacking logic
- [ ] Implement `remove_item()` with stack handling
- [ ] Implement `find_item_slot()` search
- [ ] Implement `expand_capacity()`
- [ ] Implement equipment dictionary
- [ ] Implement `equip()` / `unequip()` with validation
- [ ] Implement `get_total_stat_bonus()` calculation
- [ ] Integrate with `PlayerStats` stat methods
- [ ] Register autoload in `project.godot`

### Commit 2B: Inventory UI - Basic Grid
- [ ] Create `InventorySlot` scene (PanelContainer + TextureRect + Label)
- [ ] Create `inventory_slot.gd` script
- [ ] Create `InventoryUI` scene (Control + dimmer + panel)
- [ ] Create `inventory_ui.gd` script
- [ ] Implement slot grid generation
- [ ] Implement slot click handling
- [ ] Implement inventory toggle (input action)
- [ ] Connect to `InventorySystem` signals
- [ ] Add `open_inventory` input action to `project.godot`
- [ ] Add inventory UI instance to main scene

### Commit 2C: Equipment System
- [ ] Create `EquipSlot` scene (similar to InventorySlot)
- [ ] Create `equip_slot.gd` script
- [ ] Update `InventoryUI` to include equipment panel
- [ ] Implement equipment slot display
- [ ] Implement equipment slot click (unequip)
- [ ] Connect equipment slots to `InventorySystem`
- [ ] Test stat bonus integration with `PlayerStats`
- [ ] Verify equipment affects max_health/mana/stamina

---

## 7. Common Pitfalls to Avoid

### 7.1 Item Stacking
- **Pitfall**: Creating new stack when existing stack has space
- **Solution**: Always check `find_item_slot()` first for stackable items

### 7.2 Equipment Validation
- **Pitfall**: Allowing wrong equipment in wrong slots
- **Solution**: Validate `item.slot == slot_name` in `equip()`

### 7.3 Stat Calculation
- **Pitfall**: Forgetting to recalculate derived stats after equipment change
- **Solution**: Derived stats use `get_total_*()` methods, auto-update

### 7.4 UI Refresh
- **Pitfall**: UI not updating when inventory changes
- **Solution**: Connect to `InventorySystem.inventory_changed` signal

### 7.5 Empty Slot Handling
- **Pitfall**: Null reference errors when accessing empty slots
- **Solution**: Always check `if slot["item"] == null` before accessing

---

## 8. Testing Strategy

### 8.1 Unit Tests (Manual)
- Add item to empty inventory
- Add item to existing stack
- Add item when inventory full
- Remove item from stack
- Remove last item from stack
- Equip item in correct slot
- Equip item in wrong slot (should fail)
- Unequip item (returns to inventory)
- Stat bonus calculation (multiple items)
- Capacity expansion

### 8.2 Integration Tests
- Equipment affects player stats
- Equipment affects max_health/mana/stamina
- Inventory UI updates on changes
- Equipment UI updates on changes
- Input toggle works correctly

---

## 9. Future Enhancements (Post-MVP)

- Drag-and-drop item movement
- Item tooltips on hover
- Equipment comparison (hover to see stats)
- Inventory sorting
- Item filtering/search
- Quick-use slots (hotbar)
- Item durability (if needed)
- Set bonuses (equipment sets)

---

## 10. References & Best Practices

**Industry Standards**
- Diablo-style inventory (grid-based, stackable)
- Final Fantasy equipment (8 slots, stat bonuses)
- Minecraft inventory (expandable, simple stacking)

**Godot-Specific**
- Use `GridContainer` for grids (not manual positioning)
- Use `PanelContainer` for slot backgrounds
- Use signals for decoupled updates
- Use Custom Resources for data-driven items

**Codebase Patterns**
- Follow Coordinator/Worker pattern (InventorySystem = coordinator)
- Use autoloads for global systems
- Use EventBus for cross-system communication
- Follow naming conventions from SPEC.md

---

**End of Research Summary**

