# Architecture Guidelines

This document defines the data flow patterns and architectural principles used in the codebase.

## Data Flow Patterns

### State Changes

**Rule:** Always use setters + signals for state changes. **Never** directly mutate properties across system boundaries.

**Pattern:**
```gdscript
# ✅ GOOD: Use setter method
PlayerStats.set_base_stat_level(stat_name, new_level)
# The setter internally updates the property and emits signals

# ❌ BAD: Direct mutation
PlayerStats.base_resilience = 5  # Violates encapsulation!
```

**Why:**
- Encapsulation: External systems should not directly access internal state
- Validation: Setters can validate input before applying changes
- Signals: Setters emit signals for UI/system updates
- Consistency: All state changes follow the same pattern

### Queries (Read Operations)

**Rule:** Use method calls for read-only operations (queries).

**Pattern:**
```gdscript
# ✅ GOOD: Query method
var current_health = PlayerStats.get_max_health()
var has_mana = PlayerStats.has_mana(cost)

# ✅ ALSO GOOD: Direct property access for simple queries within same system
# (only when inside the same class/file)
```

**Why:**
- Simple: Direct access for queries is fine
- Fast: No overhead for read operations
- Clear: Methods can document what they return

### Cross-System Notifications

**Rule:** Use EventBus signals for decoupled cross-system notifications.

**Pattern:**
```gdscript
# ✅ GOOD: EventBus for cross-system events
EventBus.item_picked_up.emit(item, count)
EventBus.enemy_killed.emit(enemy_name, position)

# ✅ ALSO GOOD: Direct signals for closely related systems
# (when systems have direct dependencies anyway)
PlayerStats.stat_changed.emit(stat_name, new_value)
```

**Why:**
- Decoupling: Systems don't need direct references
- Flexibility: Multiple listeners can subscribe
- Event-driven: Clear event-based architecture

## Summary Table

| Operation Type | Pattern | Example |
|---------------|---------|---------|
| **State Change** | Setter method + signals | `PlayerStats.set_health(100)` |
| **Query** | Method call or direct property | `PlayerStats.get_max_health()` |
| **Cross-System Event** | EventBus signal | `EventBus.item_picked_up.emit(...)` |

## System Architecture Patterns

### Facade Pattern

**Purpose:** Provide a simplified, backwards-compatible interface while delegating to focused subsystems.

**Example:** `PlayerStats` acts as a facade that delegates to:
- `XPLevelingSystem`: Base stat XP and leveling
- `CurrencySystem`: Gold management
- `ResourceRegenSystem`: Health/mana/stamina regeneration
- `BuffSystem`: Stat buffs and speed buffs
- `CarryWeightSystem`: Weight calculations

**Pattern:**
```gdscript
# ✅ GOOD: Facade delegates to subsystems
func get_total_resilience() -> int:
    var bonus: int = InventorySystem.get_total_stat_bonus(StatConstants.STAT_RESILIENCE)
    var temp_modifier: int = BuffSystem.get_temporary_stat_modifier(StatConstants.STAT_RESILIENCE)
    return XPLevelingSystem.get_base_stat_level(StatConstants.STAT_RESILIENCE) + bonus + temp_modifier

# External code still uses PlayerStats API
var resilience = PlayerStats.get_total_resilience()  # Works as before!
```

**Why:**
- Backwards compatibility: Existing code continues to work
- Single Responsibility: Each subsystem handles one concern
- Maintainability: Changes to subsystems don't break facade API
- Testability: Subsystems can be tested independently

### System Decomposition

**Rule:** Large systems should be decomposed into focused subsystems.

**Examples:**

**PlayerStats → Multiple Systems:**
- `BuffSystem`: Manages temporary stat modifiers and speed buffs
- `CarryWeightSystem`: Calculates max/current carry weight
- `XPLevelingSystem`: Handles base stat XP and leveling (already existed)
- `CurrencySystem`: Manages gold (already existed)
- `ResourceRegenSystem`: Handles health/mana/stamina regeneration (already existed)

**InventorySystem → Multiple Systems:**
- `EquipmentSystem`: Manages equipment slots and stat bonuses
- `ItemUsageHandler`: Handles consumable item usage logic

**SpellSystem → Multiple Systems:**
- `ElementXPSystem`: Manages element XP and leveling
- `ElementBuffSystem`: Manages element damage multipliers
- `SpellDamageCalculator`: Utility for spell damage calculations

**Why:**
- Single Responsibility Principle: Each system has one reason to change
- Easier testing: Smaller systems are easier to test
- Better organization: Related functionality grouped together
- Reduced coupling: Systems depend on interfaces, not implementations

### Handler Pattern (UI Business Logic Separation)

**Purpose:** Separate business logic from UI presentation.

**Pattern:**
```gdscript
# ✅ GOOD: Handler contains business logic
class_name InventoryUIHandler

static func handle_slot_click(slot_index: int) -> Dictionary:
    # Business logic: check item type, equip if equipment, etc.
    if slot_data["item"] is EquipmentData:
        return EquipmentSystem.equip(equip_item)
    return {"success": false}

# UI only handles presentation
func _on_slot_clicked(slot_index: int) -> void:
    var result = InventoryUIHandler.handle_slot_click(slot_index)
    if result["success"]:
        _refresh_slots()  # Update UI
```

**Examples:**
- `InventoryUIHandler`: Handles equipment equipping from inventory
- `CraftingUIHandler`: Handles ingredient validation display
- `MerchantTransactionHandler`: Handles buy/sell transaction logic

**Why:**
- Separation of concerns: UI focuses on presentation, handlers focus on logic
- Reusability: Handlers can be used by multiple UI implementations
- Testability: Business logic can be tested without UI
- Maintainability: Changes to UI don't affect business logic

### Utility Classes

**Purpose:** Provide stateless, reusable calculation functions.

**Pattern:**
```gdscript
# ✅ GOOD: Utility class with static methods
class_name SpellDamageCalculator

static func calculate_spell_damage(spell: SpellData) -> int:
    # Pure calculation logic
    var element_level = ElementXPSystem.get_level(spell.element)
    var base_damage = spell.base_damage
    # ... calculations
    return final_damage
```

**Examples:**
- `SpellDamageCalculator`: Calculates spell damage with all modifiers
- `InventorySpaceCalculator`: Validates inventory space for items
- `StatFormulas`: Contains stat calculation formulas (already existed)
- `DamageCalculator`: Contains damage calculation formulas (already existed)

**Why:**
- Reusability: Same calculations used across multiple systems
- Testability: Pure functions are easy to test
- Clarity: Calculation logic is centralized and documented
- Performance: Static methods have no instance overhead

## Worker Pattern

Workers are single-purpose components that do one thing well. Coordinators make decisions and delegate to workers.

**Worker Responsibilities:**
- Execute a single, well-defined task
- Expose simple interface to coordinator
- Do NOT make high-level decisions

**Coordinator Responsibilities:**
- Make decisions about what to do
- Orchestrate worker interactions
- Do NOT implement low-level details

**Example:**
```gdscript
# Coordinator (player.gd)
@onready var spell_selection_manager: SpellSelectionManager = $SpellSelectionManager
@onready var camera_effects_worker: CameraEffectsWorker = $CameraEffectsWorker

func _on_hurt(damage: int, knockback: Vector2, attacker: Node) -> void:
    # Coordinator decides: apply screen shake
    if camera_effects_worker != null:
        camera_effects_worker.screen_shake(8.0, 0.2)
    
    # Coordinator decides: apply knockback
    if mover != null:
        mover.apply_knockback(knockback * 0.5)

# Worker (CameraEffectsWorker)
func screen_shake(intensity: float, duration: float) -> void:
    # Worker handles implementation details
    _shake_tween = owner_node.create_tween()
    # ... shake implementation
```

**Common Workers:**
- `SpellSelectionManager`: Manages spell hotbar and selection
- `CameraEffectsWorker`: Handles screen shake and camera effects
- `Mover`: Handles movement physics
- `Animator`: Handles animation playback
- `SpellCaster`: Handles spell casting logic
- `SpellSpawner`: Spawns spell projectiles

## Error Handling Patterns

### Recoverable Errors
- Log warning
- Return safe default value
- Continue execution

### Fatal Errors
- Log error
- Return null/false
- Emit signal if needed

### Invalid Input
- Always log
- Never silently skip
- Return safe default or false

## Resource Loading

All resource loading should go through `ResourceManager` singleton.

**Pattern:**
```gdscript
# ✅ GOOD: Use ResourceManager
var spell = ResourceManager.load_spell("fireball")
var item = ResourceManager.load_item("health_potion")

# ❌ BAD: Direct loading with hard-coded paths
var spell = load("res://resources/spells/fireball.tres")
```

## System Reference

### Core Systems (Autoloads)

**Player Systems:**
- `PlayerStats`: Facade for player stats (delegates to subsystems)
- `XPLevelingSystem`: Base stat XP and leveling
- `CurrencySystem`: Gold management
- `ResourceRegenSystem`: Health/mana/stamina regeneration
- `BuffSystem`: Temporary stat modifiers and speed buffs
- `CarryWeightSystem`: Carry weight calculations

**Combat Systems:**
- `CombatSystem`: Combat calculations and damage
- `SpellSystem`: Spell management (delegates to ElementXPSystem, ElementBuffSystem)
- `ElementXPSystem`: Element XP and leveling
- `ElementBuffSystem`: Element damage multipliers

**Inventory Systems:**
- `InventorySystem`: Inventory slot management
- `EquipmentSystem`: Equipment slot management and stat bonuses
- `ItemUsageHandler`: Consumable item usage logic

**Other Systems:**
- `CraftingSystem`: Recipe crafting logic
- `AlchemySystem`: Potion crafting logic
- `MovementSystem`: Movement calculations
- `MovementTracker`: Movement tracking
- `EventBus`: Cross-system event notifications
- `GameBalance`: Game balance configuration values
- `ResourceManager`: Resource loading and caching

### UI Handlers

- `InventoryUIHandler`: Inventory UI business logic (equipment equipping)
- `CraftingUIHandler`: Crafting UI business logic (ingredient validation)
- `MerchantTransactionHandler`: Merchant UI business logic (buy/sell transactions)

### Utility Classes

- `SpellDamageCalculator`: Spell damage calculation utility
- `InventorySpaceCalculator`: Inventory space validation utility
- `StatFormulas`: Stat calculation formulas
- `DamageCalculator`: Damage calculation formulas
- `EquipmentStatCalculator`: Equipment stat bonus calculations

### Workers

- `SpellSelectionManager`: Spell hotbar and selection management
- `CameraEffectsWorker`: Screen shake and camera effects
- `Mover`: Movement physics
- `Animator`: Animation playback
- `SpellCaster`: Spell casting logic
- `SpellSpawner`: Spell projectile spawning
- `InputReader`: Input handling
- `HealthTracker`: Health tracking
- `Hurtbox`: Damage reception
- `RunningStateManager`: Running state management

