# Milestone Completion Plan

**Date**: 2025-12-28  
**Goal**: Complete Milestone 4 (Crafting & Chests) and Milestone 5 (Currency & Merchant) according to SPEC.md

---

## Current Status

### ✅ Completed Milestones
- **Milestone 1**: Foundation - Complete
- **Milestone 2**: Inventory & Equipment - Complete
- **Milestone 3**: Elemental Spells - Complete

### 📋 Remaining Milestones
- **Milestone 4**: Crafting & Chests - Not Started
- **Milestone 5**: Currency & Merchant - Not Started

---

## Milestone 4: Crafting & Chests

### Commit 4A: Crafting System Foundation

**Status**: ❌ Not Started

**Required Files**:
1. `scripts/systems/crafting/crafting_system.gd` - Main crafting system autoload
2. Update `project.godot` - Add CraftingSystem autoload

**Required Implementation**:
- Load all recipes from `res://resources/recipes/` on `_ready()`
- Implement recipe matching logic
- Check if player has required ingredients
- Consume ingredients and grant results
- Emit signals for crafting events

**Signals (LOCKED)**:
- `item_crafted(recipe: RecipeData, result: ItemData)`
- `craft_failed(recipe: RecipeData, reason: String)`

**Methods (LOCKED)**:
- `get_all_recipes() -> Array[RecipeData]`
- `get_craftable_recipes() -> Array[RecipeData]`
- `can_craft(recipe: RecipeData) -> bool`
- `craft(recipe: RecipeData) -> bool`
- `_consume_ingredients(recipe: RecipeData) -> void`
- `_grant_result(recipe: RecipeData) -> void`

**Dependencies**:
- ✅ InventorySystem (exists)
- ✅ RecipeData (exists)
- ✅ ItemData (exists)

---

### Commit 4B: Crafting UI

**Status**: ❌ Not Started

**Required Files**:
1. `scenes/ui/crafting_ui.tscn` - Crafting UI scene
2. `scripts/ui/crafting/crafting_ui.gd` - Crafting UI script

**Required Implementation**:
- Recipe list display
- Recipe detail view (ingredients + result)
- Craft button
- Toggle on `open_crafting` input action
- Connect to CraftingSystem signals

**Scene Structure** (per SPEC.md):
```
CraftingUI (Control) [visible = false]
├── ColorRect (dimmer)
└── PanelContainer
    └── HBoxContainer
        ├── VBoxContainer (recipe list)
        │   ├── Label ("Recipes")
        │   └── ItemList (recipe_list)
        └── VBoxContainer (recipe detail)
            ├── Label (recipe_name)
            ├── VBoxContainer (ingredients_list)
            ├── HSeparator
            ├── HBoxContainer (result display)
            └── Button (craft_button: "Craft")
```

**Input Action**: Add `open_crafting` (C key) to `project.godot`

---

### Commit 4C: Chests

**Status**: ❌ Not Started

**Required Files**:
1. `scripts/objects/chest.gd` - Chest script
2. `scenes/objects/chest.tscn` - Chest scene

**Required Implementation**:
- Area2D for interaction detection
- AnimatedSprite2D with "closed", "open", "opening" animations
- Loot system (Array[ItemData] + Array[int] counts)
- Transfer loot to InventorySystem on open
- Play opening animation
- Emit `opened` signal

**Scene Structure** (per SPEC.md):
```
Chest (Area2D)
├── AnimatedSprite2D [animations: "closed", "open", "opening"]
└── CollisionShape2D
```

**Input Action**: Add `interact` (E key) to `project.godot`

**Integration**:
- Connect to EventBus `chest_opened` signal
- Use InventorySystem to add items

---

## Milestone 5: Currency & Merchant

### Commit 5A: Currency System Integration

**Status**: ⚠️ Partially Complete

**Current State**:
- ✅ CurrencySystem autoload exists
- ✅ PlayerStats has gold methods (via CurrencySystem)
- ❌ Enemy gold drops not implemented
- ❌ HUD gold display not implemented

**Required Implementation**:

1. **Enemy Gold Drops** (`scripts/enemies/base_enemy.gd`):
   - Add `@export var gold_drop_min: int = 5`
   - Add `@export var gold_drop_max: int = 15`
   - In `_on_died()`: Drop random gold amount
   - Emit `EventBus.enemy_killed` signal

2. **HUD Gold Display** (`scenes/ui/hud.tscn`):
   - Add HBoxContainer with coin icon + label
   - Connect to `CurrencySystem.gold_changed` signal
   - Display current gold amount

---

### Commit 5B: Merchant NPC

**Status**: ❌ Not Started

**Required Files**:
1. `scripts/npcs/merchant.gd` - Merchant NPC script
2. `scenes/npcs/merchant.tscn` - Merchant NPC scene

**Required Implementation**:
- CharacterBody2D with sprite
- Area2D for interaction detection
- MerchantData resource reference
- Open shop on `interact` when player in range
- Emit `EventBus.merchant_opened(merchant_data)` signal

**Scene Structure**:
```
Merchant (CharacterBody2D)
├── AnimatedSprite2D
├── InteractionArea (Area2D)
│   └── CollisionShape2D
└── (script: merchant.gd)
```

**Dependencies**:
- ✅ MerchantData (exists)
- ✅ EventBus (exists)
- ✅ interact input action (needed for Commit 4C)

---

### Commit 5C: Merchant UI

**Status**: ❌ Not Started

**Required Files**:
1. `scenes/ui/merchant_ui.tscn` - Merchant UI scene
2. `scripts/ui/merchant/merchant_ui.gd` - Merchant UI script

**Required Implementation**:
- Display merchant name and greeting
- Show merchant stock (items + prices)
- Show player inventory (for selling)
- Buy button (check gold, add to inventory)
- Sell button (remove from inventory, add gold)
- Close button
- Toggle on `EventBus.merchant_opened` signal

**Scene Structure** (per SPEC.md):
```
MerchantUI (Control) [visible = false]
├── ColorRect (dimmer)
└── PanelContainer
    └── VBoxContainer
        ├── Label (merchant_name)
        ├── Label (greeting)
        ├── HSeparator
        ├── HBoxContainer
        │   ├── VBoxContainer (merchant stock)
        │   │   ├── Label ("For Sale")
        │   │   └── ItemList (stock_list)
        │   └── VBoxContainer (player inventory)
        │       ├── Label ("Your Items")
        │       └── ItemList (inventory_list)
        ├── HSeparator
        ├── HBoxContainer (transaction)
        │   ├── Button (buy_button: "Buy")
        │   ├── Button (sell_button: "Sell")
        │   └── Label (gold_display)
        └── Button (close_button: "Close")
```

**Pricing Logic**:
- Buy price: From MerchantData.prices array
- Sell price: 50% of buy price (per SPEC.md)

---

### Commit 5D: Pause Menu

**Status**: ❌ Not Started

**Required Files**:
1. `scenes/ui/pause_menu.tscn` - Pause menu scene
2. `scripts/ui/pause_menu.gd` - Pause menu script

**Required Implementation**:
- Toggle on `pause` input action (Escape)
- Pause game (get_tree().paused = true)
- Resume button
- Settings button (placeholder)
- Quit button
- Always process input (process_mode = PROCESS_MODE_ALWAYS)

**Scene Structure** (per SPEC.md):
```
PauseMenu (Control) [visible = false, process_mode = PROCESS_MODE_ALWAYS]
├── ColorRect (dimmer)
└── PanelContainer (centered)
    └── VBoxContainer
        ├── Label ("Paused")
        ├── Button (resume_button: "Resume")
        ├── Button (settings_button: "Settings")
        └── Button (quit_button: "Quit")
```

**Input Action**: Add `pause` (Escape key) to `project.godot`

---

## Missing Input Actions

**Required Input Actions** (per SPEC.md):
1. ❌ `open_inventory` (I key) - Check if exists
2. ❌ `open_crafting` (C key) - Not found
3. ❌ `interact` (E key) - Not found
4. ❌ `pause` (Escape key) - Not found

**Action**: Add all missing input actions to `project.godot`

---

## Implementation Order

### Phase 1: Milestone 4 Foundation
1. **Commit 4A**: Create CraftingSystem
   - Implement recipe loading
   - Implement crafting logic
   - Register autoload
   - Test with sample recipe

2. **Add Input Actions**:
   - `open_crafting` (C)
   - `interact` (E)

### Phase 2: Milestone 4 UI & Objects
3. **Commit 4B**: Create Crafting UI
   - Create scene and script
   - Connect to CraftingSystem
   - Test crafting flow

4. **Commit 4C**: Create Chests
   - Create chest script and scene
   - Implement loot system
   - Test chest opening

### Phase 3: Milestone 5 Currency
5. **Commit 5A**: Currency Integration
   - Add enemy gold drops
   - Add HUD gold display
   - Test gold system

### Phase 4: Milestone 5 Merchant
6. **Commit 5B**: Merchant NPC
   - Create merchant script and scene
   - Implement interaction
   - Test merchant opening

7. **Commit 5C**: Merchant UI
   - Create merchant UI scene and script
   - Implement buy/sell logic
   - Test transactions

### Phase 5: Milestone 5 Final
8. **Commit 5D**: Pause Menu
   - Create pause menu scene and script
   - Add `pause` input action
   - Test pause/resume

---

## Testing Checklist

After each commit:
- [ ] All files exist at specified paths
- [ ] All class_name declarations match SPEC.md
- [ ] All signal names match SPEC.md exactly
- [ ] All method signatures match SPEC.md exactly
- [ ] All property names match SPEC.md exactly
- [ ] Autoloads registered correctly in project.godot
- [ ] Input actions added to project.godot
- [ ] Game builds without errors
- [ ] Manual test passes

---

## Estimated Time

- **Commit 4A**: 1-2 hours (CraftingSystem)
- **Commit 4B**: 1-2 hours (Crafting UI)
- **Commit 4C**: 1 hour (Chests)
- **Commit 5A**: 30 minutes (Currency integration)
- **Commit 5B**: 1 hour (Merchant NPC)
- **Commit 5C**: 2-3 hours (Merchant UI)
- **Commit 5D**: 30 minutes (Pause Menu)

**Total**: ~7-10 hours

---

## Next Steps

1. Start with **Commit 4A**: CraftingSystem Foundation
2. Create sample recipe resource for testing
3. Test crafting logic
4. Proceed to Commit 4B

---

**Ready to begin implementation!**

