# MVP RPG Systems Specification

**Version**: 1.0  
**Created**: 2024-12-24  
**Purpose**: Prevent implementation drift by locking down all naming conventions, file paths, properties, methods, and signals.

---

## Table of Contents

1. [Naming Conventions](#naming-conventions)
2. [Directory Structure](#directory-structure)
3. [Input Actions](#input-actions)
4. [Autoloads](#autoloads)
5. [Custom Resources](#custom-resources)
6. [Milestone 1: Foundation](#milestone-1-foundation)
7. [Milestone 2: Inventory & Equipment](#milestone-2-inventory--equipment)
8. [Milestone 3: Elemental Spells](#milestone-3-elemental-spells)
9. [Milestone 4: Crafting & Chests](#milestone-4-crafting--chests)
10. [Milestone 5: Currency & Merchant](#milestone-5-currency--merchant)

---

## Naming Conventions

### Files

| Type | Convention | Example |
|------|------------|---------|
| Scripts | `snake_case.gd` | `player_stats.gd` |
| Scenes | `snake_case.tscn` | `inventory_ui.tscn` |
| Resources | `snake_case.tres` | `health_potion.tres` |
| Resource Classes | `PascalCase` class_name | `class_name ItemData` |

### Variables & Properties

| Type | Convention | Example |
|------|------------|---------|
| Private variables | `_snake_case` | `_is_open` |
| Public variables | `snake_case` | `max_health` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_STACK_SIZE` |
| Signals | `snake_case` (past tense for events) | `health_changed`, `item_added` |
| Export variables | `snake_case` | `@export var move_speed: float` |

### Methods

| Type | Convention | Example |
|------|------------|---------|
| Public methods | `snake_case` | `add_item()` |
| Private methods | `_snake_case` | `_update_display()` |
| Signal callbacks | `_on_<source>_<signal>` | `_on_health_changed()` |

### Nodes

| Type | Convention | Example |
|------|------------|---------|
| Scene root | `PascalCase` | `InventoryUI` |
| Child nodes | `PascalCase` | `HealthBar`, `SlotGrid` |
| Instanced scenes | `PascalCase` | `Slot1`, `Slot2` |

---

## Directory Structure

```
res://
├── animations/           # EXISTING - do not modify
├── Texture/              # EXISTING - do not modify
├── scenes/
│   ├── enemies/          # EXISTING
│   ├── objects/          # NEW - chests, interactables
│   ├── npcs/             # NEW - merchant
│   └── ui/               # NEW - all UI scenes
├── scripts/
│   ├── data/             # NEW - Custom Resource classes
│   ├── enemies/          # EXISTING
│   ├── npcs/             # NEW - merchant script
│   ├── objects/          # NEW - chest script
│   ├── projectiles/      # EXISTING
│   ├── systems/          # EXISTING + autoloads
│   ├── ui/               # NEW - UI scripts
│   └── workers/          # EXISTING
└── resources/            # NEW - .tres instances
    ├── items/            # ingredient items
    ├── equipment/        # equipment items
    ├── spells/           # spell definitions
    ├── potions/          # potion items
    ├── recipes/          # crafting recipes
    └── merchants/        # merchant stock definitions
```

---

## Input Actions

All input actions to be added to `project.godot`:

| Action Name | Key | Purpose |
|-------------|-----|---------|
| `open_inventory` | I | Toggle inventory UI |
| `open_crafting` | C | Toggle crafting UI |
| `interact` | E | Interact with chests, NPCs |
| `pause` | Escape | Toggle pause menu |
| `spell_1` | 1 | Select fire spell |
| `spell_2` | 2 | Select water spell |
| `spell_3` | 3 | Select earth spell |
| `spell_4` | 4 | Select air spell |

**Note**: `spell_1` already exists (mapped to Q). Will be remapped to 1.

---

## Autoloads

Registered in `project.godot` under `[autoload]`:

| Name | Path | Purpose |
|------|------|---------|
| `PlayerStats` | `res://scripts/systems/player_stats.gd` | Player attributes, health, mana, stamina, gold |
| `EventBus` | `res://scripts/systems/event_bus.gd` | Central signal hub for decoupled communication |
| `InventorySystem` | `res://scripts/systems/inventory_system.gd` | Slot-based inventory and equipment |
| `SpellSystem` | `res://scripts/systems/spell_system.gd` | Element leveling and spell data |
| `CraftingSystem` | `res://scripts/systems/crafting_system.gd` | Recipe matching and crafting |

---

## Custom Resources

### ItemData (Base Class)

**File**: `res://scripts/data/item_data.gd`

```gdscript
class_name ItemData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var stackable: bool = true
@export var max_stack: int = 99
@export_enum("consumable", "equipment", "material", "key") var item_type: String = "material"
```

**Properties (LOCKED)**:
- `id`: Unique identifier, snake_case (e.g., `"health_potion"`)
- `display_name`: Human-readable name (e.g., `"Health Potion"`)
- `description`: Tooltip text
- `icon`: 32x32 or 64x64 Texture2D
- `stackable`: true for consumables/materials, false for equipment
- `max_stack`: Maximum stack size (default 99)
- `item_type`: One of: `"consumable"`, `"equipment"`, `"material"`, `"key"`

---

### EquipmentData (Extends ItemData)

**File**: `res://scripts/data/equipment_data.gd`

```gdscript
class_name EquipmentData
extends ItemData

@export_enum("head", "body", "gloves", "boots", "weapon", "shield", "ring") var slot: String = "weapon"
@export var str_bonus: int = 0
@export var dex_bonus: int = 0
@export var int_bonus: int = 0
@export var vit_bonus: int = 0
```

**Properties (LOCKED)**:
- `slot`: One of exactly: `"head"`, `"body"`, `"gloves"`, `"boots"`, `"weapon"`, `"shield"`, `"ring"`
- `str_bonus`: Added to STR when equipped
- `dex_bonus`: Added to DEX when equipped
- `int_bonus`: Added to INT when equipped
- `vit_bonus`: Added to VIT when equipped

**Note**: EquipmentData automatically has `item_type = "equipment"` and `stackable = false`.

---

### SpellData

**File**: `res://scripts/data/spell_data.gd`

```gdscript
class_name SpellData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export_enum("fire", "water", "earth", "air") var element: String = "fire"
@export var base_damage: int = 10
@export var mana_cost: int = 10
@export var cooldown: float = 0.5
@export var hue_shift: float = 0.0
@export var projectile_speed: float = 300.0
```

**Properties (LOCKED)**:
- `id`: Unique identifier (e.g., `"fireball"`)
- `display_name`: Human-readable name (e.g., `"Fireball"`)
- `element`: One of exactly: `"fire"`, `"water"`, `"earth"`, `"air"`
- `base_damage`: Base damage before modifiers
- `mana_cost`: Mana consumed per cast
- `cooldown`: Seconds between casts
- `hue_shift`: Color rotation (0.0 = red/fire, 0.3 = brown/earth, 0.55 = blue/water, 0.75 = cyan/air)
- `projectile_speed`: Pixels per second

**Element Hue Values (LOCKED)**:
| Element | hue_shift | Resulting Color |
|---------|-----------|-----------------|
| fire | 0.0 | Red/Orange |
| earth | 0.3 | Brown/Green |
| water | 0.55 | Blue |
| air | 0.75 | Cyan/White |

---

### PotionData (Extends ItemData)

**File**: `res://scripts/data/potion_data.gd`

```gdscript
class_name PotionData
extends ItemData

@export_enum("restore_health", "restore_mana", "restore_stamina", "buff_speed", "buff_strength", "buff_defense") var effect: String = "restore_health"
@export var potency: int = 50
@export var duration: float = 0.0
```

**Properties (LOCKED)**:
- `effect`: One of exactly: `"restore_health"`, `"restore_mana"`, `"restore_stamina"`, `"buff_speed"`, `"buff_strength"`, `"buff_defense"`
- `potency`: Amount restored OR buff percentage (e.g., 50 = restore 50 HP or +50% speed)
- `duration`: Buff duration in seconds. 0.0 = instant effect (restore potions).

**Note**: PotionData automatically has `item_type = "consumable"`.

---

### RecipeData

**File**: `res://scripts/data/recipe_data.gd`

```gdscript
class_name RecipeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var result: ItemData = null
@export var result_count: int = 1
@export var ingredients: Array[ItemData] = []
@export var ingredient_counts: Array[int] = []
```

**Properties (LOCKED)**:
- `id`: Unique identifier (e.g., `"recipe_health_potion"`)
- `display_name`: Human-readable name (e.g., `"Health Potion Recipe"`)
- `result`: The ItemData produced
- `result_count`: How many items produced (default 1)
- `ingredients`: Array of required ItemData resources
- `ingredient_counts`: Parallel array of quantities needed

**Constraint**: `ingredients.size()` must equal `ingredient_counts.size()`

---

### MerchantData

**File**: `res://scripts/data/merchant_data.gd`

```gdscript
class_name MerchantData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var greeting: String = "Welcome, traveler!"
@export var stock: Array[ItemData] = []
@export var prices: Array[int] = []
```

**Properties (LOCKED)**:
- `id`: Unique identifier (e.g., `"merchant_village"`)
- `display_name`: NPC name shown in UI (e.g., `"Village Shopkeeper"`)
- `greeting`: Dialogue shown when opening shop
- `stock`: Array of items for sale
- `prices`: Parallel array of buy prices (sell price = 50% of buy price)

**Constraint**: `stock.size()` must equal `prices.size()`

---

## Milestone 1: Foundation

### Commit 1A: Data Architecture

**Goal**: Create all Custom Resource class files.

**Files Created**:
| File | Class Name |
|------|------------|
| `res://scripts/data/item_data.gd` | `ItemData` |
| `res://scripts/data/equipment_data.gd` | `EquipmentData` |
| `res://scripts/data/spell_data.gd` | `SpellData` |
| `res://scripts/data/potion_data.gd` | `PotionData` |
| `res://scripts/data/recipe_data.gd` | `RecipeData` |
| `res://scripts/data/merchant_data.gd` | `MerchantData` |

**Test Resources Created** (for validation only):
| File | Type |
|------|------|
| `res://resources/items/test_item.tres` | ItemData |
| `res://resources/equipment/test_sword.tres` | EquipmentData |
| `res://resources/spells/test_spell.tres` | SpellData |
| `res://resources/potions/test_potion.tres` | PotionData |
| `res://resources/recipes/test_recipe.tres` | RecipeData |

**Validation**: Open each .tres in Godot editor, confirm properties are editable.

---

### Commit 1B: Global Systems Foundation

**Goal**: Create PlayerStats and EventBus autoloads.

#### PlayerStats

**File**: `res://scripts/systems/player_stats.gd`

```gdscript
extends Node

# Signals (LOCKED NAMES)
signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal stamina_changed(current: int, maximum: int)
signal gold_changed(amount: int)
signal stat_changed(stat_name: String, new_value: int)
signal player_died

# Base Stats (LOCKED NAMES, LOCKED DEFAULTS)
var base_str: int = 5
var base_dex: int = 5
var base_int: int = 5
var base_vit: int = 5

# Derived Stats (LOCKED FORMULAS)
# max_health = total_vit * 20
# max_mana = total_int * 15
# max_stamina = total_dex * 10

# Current Values (LOCKED NAMES)
var health: int = 100
var mana: int = 75
var stamina: int = 50
var gold: int = 0

# Methods (LOCKED SIGNATURES)
func get_total_str() -> int
func get_total_dex() -> int
func get_total_int() -> int
func get_total_vit() -> int
func get_max_health() -> int
func get_max_mana() -> int
func get_max_stamina() -> int
func set_health(value: int) -> void
func set_mana(value: int) -> void
func set_stamina(value: int) -> void
func heal(amount: int) -> void
func take_damage(amount: int) -> void
func consume_mana(amount: int) -> bool  # Returns false if insufficient
func has_mana(amount: int) -> bool
func restore_mana(amount: int) -> void
func consume_stamina(amount: int) -> bool
func has_stamina(amount: int) -> bool
func restore_stamina(amount: int) -> void
func add_gold(amount: int) -> void
func spend_gold(amount: int) -> bool  # Returns false if insufficient
func has_gold(amount: int) -> bool
```

#### EventBus

**File**: `res://scripts/systems/event_bus.gd`

```gdscript
extends Node

# UI Signals (LOCKED NAMES)
signal inventory_opened
signal inventory_closed
signal crafting_opened
signal crafting_closed
signal merchant_opened(merchant_data: MerchantData)
signal merchant_closed
signal pause_menu_opened
signal pause_menu_closed

# Game Events (LOCKED NAMES)
signal item_picked_up(item: ItemData, count: int)
signal item_used(item: ItemData)
signal chest_opened(chest_position: Vector2)
signal enemy_killed(enemy_name: String, position: Vector2)
signal spell_cast(spell: SpellData)
signal level_up(element: String, new_level: int)
```

**Autoload Registration** (add to project.godot):
```
[autoload]
PlayerStats="*res://scripts/systems/player_stats.gd"
EventBus="*res://scripts/systems/event_bus.gd"
```

---

### Commit 1C: HUD - Health Bar

**Goal**: Visible health bar connected to PlayerStats.

#### Scene Structure

**File**: `res://scenes/ui/hud.tscn`

```
HUD (CanvasLayer) [layer = 10]
└── MarginContainer (anchors: top-left, margins: 10px)
    └── VBoxContainer
        └── HealthBar (ProgressBar or TextureProgressBar)
```

#### Script

**File**: `res://scripts/ui/hud.gd`

```gdscript
extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar

func _ready() -> void:
    PlayerStats.health_changed.connect(_on_health_changed)
    _update_health_bar()

func _on_health_changed(current: int, maximum: int) -> void:
    _update_health_bar()

func _update_health_bar() -> void:
    health_bar.max_value = PlayerStats.get_max_health()
    health_bar.value = PlayerStats.health
```

**Integration**: Add HUD instance to `res://scenes/main.tscn`.

---

### Commit 1D: HUD - Mana & Stamina

**Goal**: Complete HUD with mana/stamina bars and mana consumption.

#### Updated Scene Structure

**File**: `res://scenes/ui/hud.tscn`

```
HUD (CanvasLayer) [layer = 10]
└── MarginContainer
    └── VBoxContainer [separation = 4]
        ├── HealthBar (ProgressBar) [modulate = red]
        ├── ManaBar (ProgressBar) [modulate = blue]
        └── StaminaBar (ProgressBar) [modulate = yellow/green]
```

#### Updated Script Connections

```gdscript
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/ManaBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar

func _ready() -> void:
    PlayerStats.health_changed.connect(_on_health_changed)
    PlayerStats.mana_changed.connect(_on_mana_changed)
    PlayerStats.stamina_changed.connect(_on_stamina_changed)
```

#### Mana Consumption Integration

**Edit**: `res://scripts/workers/spell_spawner.gd`

Before spawning spell:
```gdscript
# Check mana
var mana_cost: int = 10  # Will be replaced with SpellData.mana_cost in Commit 3B
if not PlayerStats.has_mana(mana_cost):
    return  # Cannot cast
PlayerStats.consume_mana(mana_cost)
# ... spawn spell
```

#### Mana Regeneration

In `PlayerStats._process(delta)`:
```gdscript
const MANA_REGEN_RATE: float = 2.0  # Mana per second
const STAMINA_REGEN_RATE: float = 5.0  # Stamina per second

func _process(delta: float) -> void:
    # Regenerate mana
    if mana < get_max_mana():
        restore_mana(int(MANA_REGEN_RATE * delta) + 1)  # +1 to ensure progress
    # Regenerate stamina
    if stamina < get_max_stamina():
        restore_stamina(int(STAMINA_REGEN_RATE * delta) + 1)
```

---

## Milestone 2: Inventory & Equipment

### Commit 2A: Inventory Data Layer

**File**: `res://scripts/systems/inventory_system.gd`

```gdscript
extends Node

# Constants (LOCKED)
const DEFAULT_CAPACITY: int = 12
const MAX_CAPACITY: int = 48

# Signals (LOCKED NAMES)
signal inventory_changed
signal item_added(item: ItemData, count: int, slot_index: int)
signal item_removed(item: ItemData, count: int, slot_index: int)
signal equipment_changed(slot_name: String)

# Inventory Slots (LOCKED STRUCTURE)
# Each slot is: { "item": ItemData or null, "count": int }
var slots: Array[Dictionary] = []
var capacity: int = DEFAULT_CAPACITY

# Equipment Slots (LOCKED NAMES)
var equipment: Dictionary = {
    "head": null,
    "body": null,
    "gloves": null,
    "boots": null,
    "weapon": null,
    "shield": null,
    "ring1": null,
    "ring2": null
}

# Methods (LOCKED SIGNATURES)
func _ready() -> void
func _init_slots() -> void
func add_item(item: ItemData, count: int = 1) -> int  # Returns leftover count
func remove_item(item: ItemData, count: int = 1) -> bool
func has_item(item: ItemData, count: int = 1) -> bool
func get_item_count(item: ItemData) -> int
func get_slot(index: int) -> Dictionary
func set_slot(index: int, item: ItemData, count: int) -> void
func clear_slot(index: int) -> void
func find_item_slot(item: ItemData) -> int  # Returns -1 if not found
func expand_capacity(additional_slots: int) -> void
func equip(item: EquipmentData) -> bool  # Returns false if wrong type
func unequip(slot_name: String) -> EquipmentData  # Returns unequipped item or null
func get_equipped(slot_name: String) -> EquipmentData
func get_total_stat_bonus(stat_name: String) -> int  # "str", "dex", "int", "vit"
```

**Autoload Registration**:
```
InventorySystem="*res://scripts/systems/inventory_system.gd"
```

---

### Commit 2B: Inventory UI - Basic Grid

#### Slot Scene

**File**: `res://scenes/ui/inventory_slot.tscn`

```
InventorySlot (PanelContainer) [custom_minimum_size = (64, 64)]
├── TextureRect (icon) [expand_mode = keep_aspect_centered]
└── Label (count) [anchors: bottom-right]
```

**File**: `res://scripts/ui/inventory_slot.gd`

```gdscript
extends PanelContainer

signal slot_clicked(slot_index: int)

var slot_index: int = -1

@onready var icon: TextureRect = $TextureRect
@onready var count_label: Label = $Label

func setup(index: int, item: ItemData, count: int) -> void
func _on_gui_input(event: InputEvent) -> void
```

#### Inventory Panel Scene

**File**: `res://scenes/ui/inventory_ui.tscn`

```
InventoryUI (Control) [anchors: full_rect, visible = false]
├── ColorRect (dimmer) [color = Color(0, 0, 0, 0.5)]
└── PanelContainer (centered)
    └── VBoxContainer
        ├── Label (title: "Inventory")
        ├── GridContainer (slots) [columns = 4]
        └── HBoxContainer
            └── Button (close: "Close")
```

**File**: `res://scripts/ui/inventory_ui.gd`

```gdscript
extends Control

@onready var slot_grid: GridContainer = $PanelContainer/VBoxContainer/GridContainer
@onready var close_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/Button

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")

func _ready() -> void
func _input(event: InputEvent) -> void  # Toggle on "open_inventory"
func open() -> void
func close() -> void
func _refresh_slots() -> void
func _on_slot_clicked(slot_index: int) -> void
```

---

### Commit 2C: Equipment System

#### Equipment Panel Addition

Update `res://scenes/ui/inventory_ui.tscn`:

```
InventoryUI (Control)
└── PanelContainer
    └── HBoxContainer
        ├── VBoxContainer (inventory side)
        │   ├── Label ("Inventory")
        │   └── GridContainer (slots)
        └── VBoxContainer (equipment side)
            ├── Label ("Equipment")
            └── GridContainer (equipment_slots) [columns = 2]
                ├── EquipSlot (head)
                ├── EquipSlot (body)
                ├── EquipSlot (gloves)
                ├── EquipSlot (boots)
                ├── EquipSlot (weapon)
                ├── EquipSlot (shield)
                ├── EquipSlot (ring1)
                └── EquipSlot (ring2)
```

#### Integration with PlayerStats

In `PlayerStats.get_total_str()`:
```gdscript
func get_total_str() -> int:
    return base_str + InventorySystem.get_total_stat_bonus("str")
```

(Same pattern for dex, int, vit)

---

## Milestone 3: Elemental Spells

### Commit 3A: Spell System Foundation

**File**: `res://scripts/systems/spell_system.gd`

```gdscript
extends Node

# Constants (LOCKED)
const ELEMENTS: Array[String] = ["fire", "water", "earth", "air"]
const XP_PER_LEVEL_MULTIPLIER: int = 100  # XP needed = level * 100

# Signals (LOCKED NAMES)
signal element_leveled_up(element: String, new_level: int)
signal xp_gained(element: String, amount: int, total: int)

# Element Levels (LOCKED STRUCTURE)
var element_levels: Dictionary = {
    "fire": 1,
    "water": 1,
    "earth": 1,
    "air": 1
}

var element_xp: Dictionary = {
    "fire": 0,
    "water": 0,
    "earth": 0,
    "air": 0
}

# Methods (LOCKED SIGNATURES)
func get_level(element: String) -> int
func get_xp(element: String) -> int
func get_xp_for_next_level(element: String) -> int
func gain_xp(element: String, amount: int) -> void
func _check_level_up(element: String) -> void
func get_spell_damage(spell: SpellData) -> int
func can_cast(spell: SpellData) -> bool
```

#### Damage Formula (LOCKED)

```gdscript
func get_spell_damage(spell: SpellData) -> int:
    var base: int = spell.base_damage
    var int_bonus: int = PlayerStats.get_total_int() * 2
    var level_bonus: int = (element_levels[spell.element] - 1) * 5
    return base + int_bonus + level_bonus
```

**Autoload Registration**:
```
SpellSystem="*res://scripts/systems/spell_system.gd"
```

---

### Commit 3B: Multi-Element Projectiles

#### Spell Resources (LOCKED VALUES)

| File | element | base_damage | mana_cost | cooldown | hue_shift |
|------|---------|-------------|-----------|----------|-----------|
| `res://resources/spells/fireball.tres` | fire | 15 | 10 | 0.6 | 0.0 |
| `res://resources/spells/waterball.tres` | water | 12 | 12 | 0.7 | 0.55 |
| `res://resources/spells/earthball.tres` | earth | 20 | 15 | 0.9 | 0.3 |
| `res://resources/spells/airball.tres` | air | 10 | 8 | 0.4 | 0.75 |

#### Fireball Modification

**Edit**: `res://scripts/projectiles/fireball.gd`

Add:
```gdscript
var spell_data: SpellData = null
var hue_shift: float = 0.0

func setup(data: SpellData) -> void:
    spell_data = data
    hue_shift = data.hue_shift
    _apply_hue()

func _apply_hue() -> void:
    if hue_shift != 0.0:
        # Shift the modulate color
        var color := Color.from_hsv(hue_shift, 0.8, 1.0)
        $AnimatedSprite2D.modulate = color
```

---

### Commit 3C: Spell Selection & Hotbar

#### Spell Bar Scene

**File**: `res://scenes/ui/spell_bar.tscn`

```
SpellBar (HBoxContainer) [anchors: bottom-center]
├── SpellSlot1 (spell slot scene)
├── SpellSlot2
├── SpellSlot3
└── SpellSlot4
```

#### Player Spell Selection

Add to player state:
```gdscript
var equipped_spells: Array[SpellData] = []  # Size 4
var selected_spell_index: int = 0

func _ready() -> void:
    # Load default spells
    equipped_spells = [
        preload("res://resources/spells/fireball.tres"),
        preload("res://resources/spells/waterball.tres"),
        preload("res://resources/spells/earthball.tres"),
        preload("res://resources/spells/airball.tres")
    ]

func get_selected_spell() -> SpellData:
    return equipped_spells[selected_spell_index]
```

---

## Milestone 4: Crafting & Chests

### Commit 4A: Crafting System Foundation

**File**: `res://scripts/systems/crafting_system.gd`

```gdscript
extends Node

# Signals (LOCKED NAMES)
signal item_crafted(recipe: RecipeData, result: ItemData)
signal craft_failed(recipe: RecipeData, reason: String)

# All recipes (loaded on ready)
var all_recipes: Array[RecipeData] = []

# Methods (LOCKED SIGNATURES)
func _ready() -> void  # Load all recipes from res://resources/recipes/
func get_all_recipes() -> Array[RecipeData]
func get_craftable_recipes() -> Array[RecipeData]  # Recipes player can craft now
func can_craft(recipe: RecipeData) -> bool
func craft(recipe: RecipeData) -> bool  # Returns false if cannot craft
func _consume_ingredients(recipe: RecipeData) -> void
func _grant_result(recipe: RecipeData) -> void
```

**Autoload Registration**:
```
CraftingSystem="*res://scripts/systems/crafting_system.gd"
```

---

### Commit 4B: Crafting UI

**File**: `res://scenes/ui/crafting_ui.tscn`

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

---

### Commit 4C: Chests

**File**: `res://scripts/objects/chest.gd`

```gdscript
extends Area2D

signal opened

@export var loot: Array[ItemData] = []
@export var loot_counts: Array[int] = []

var is_opened: bool = false
var player_in_range: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void
func _input(event: InputEvent) -> void  # Check for "interact" action
func _on_body_entered(body: Node2D) -> void
func _on_body_exited(body: Node2D) -> void
func open() -> void
func _transfer_loot() -> void
func _play_open_animation() -> void
```

**File**: `res://scenes/objects/chest.tscn`

```
Chest (Area2D)
├── AnimatedSprite2D [animations: "closed", "open", "opening"]
└── CollisionShape2D
```

---

## Milestone 5: Currency & Merchant

### Commit 5A: Currency System

Already defined in PlayerStats:
- `gold: int`
- `add_gold(amount: int)`
- `spend_gold(amount: int) -> bool`
- `has_gold(amount: int) -> bool`
- `gold_changed` signal

#### Enemy Gold Drops

**Edit**: `res://scripts/enemies/base_enemy.gd`

Add:
```gdscript
@export var gold_drop_min: int = 5
@export var gold_drop_max: int = 15

func _on_died() -> void:
    # ... existing death logic
    var gold_amount: int = randi_range(gold_drop_min, gold_drop_max)
    PlayerStats.add_gold(gold_amount)
    EventBus.enemy_killed.emit(name, global_position)
```

#### HUD Gold Display

Add to `res://scenes/ui/hud.tscn`:
```
HUD
└── MarginContainer
    └── VBoxContainer
        ├── HealthBar
        ├── ManaBar
        ├── StaminaBar
        └── HBoxContainer (gold display)
            ├── TextureRect (coin icon)
            └── Label (gold_label)
```

---

### Commit 5B: Merchant NPC

**File**: `res://scripts/npcs/merchant.gd`

```gdscript
extends CharacterBody2D

@export var merchant_data: MerchantData

var player_in_range: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void
func _input(event: InputEvent) -> void
func _on_interaction_area_body_entered(body: Node2D) -> void
func _on_interaction_area_body_exited(body: Node2D) -> void
func open_shop() -> void
```

---

### Commit 5C: Merchant UI

**File**: `res://scenes/ui/merchant_ui.tscn`

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

---

### Commit 5D: Pause Menu

**File**: `res://scenes/ui/pause_menu.tscn`

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

**File**: `res://scripts/ui/pause_menu.gd`

```gdscript
extends Control

func _ready() -> void
func _input(event: InputEvent) -> void  # Toggle on "pause" action
func open() -> void
func close() -> void
func _on_resume_pressed() -> void
func _on_settings_pressed() -> void  # Placeholder
func _on_quit_pressed() -> void
```

---

## Validation Checklist

After each commit, verify:

1. [ ] All new files exist at specified paths
2. [ ] All class_name declarations match spec
3. [ ] All signal names match spec exactly
4. [ ] All method signatures match spec exactly
5. [ ] All property names match spec exactly
6. [ ] Autoloads registered correctly in project.godot
7. [ ] Input actions added to project.godot
8. [ ] Game builds without errors
9. [ ] Manual test described in commit passes

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2024-12-24 | 1.0 | Initial specification |

---

*This document is the source of truth. Any deviation must be documented here first.*

