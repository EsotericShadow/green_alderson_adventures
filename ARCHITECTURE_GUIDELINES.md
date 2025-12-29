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

All resource loading should go through `ResourceManager` singleton (when implemented).

**Pattern:**
```gdscript
# ✅ GOOD: Use ResourceManager
var spell = ResourceManager.load_spell("fireball")
var item = ResourceManager.load_item("health_potion")

# ❌ BAD: Direct loading with hard-coded paths
var spell = load("res://resources/spells/fireball.tres")
```

