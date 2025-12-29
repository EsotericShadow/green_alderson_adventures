# Error Handling Guidelines

This document defines the standardized error handling patterns used throughout the codebase.

## Principles

1. **Never silently fail** - Always log errors, even if the system can recover
2. **Fail fast** - Detect and report errors immediately
3. **Graceful degradation** - Return safe defaults when possible, don't crash
4. **Clear error messages** - Include context (what failed, why, where)

## Error Types

### Recoverable Errors

**Pattern:** Log warning, return safe default, continue execution

**Examples:**
- Resource file missing (fallback to default config)
- Optional system unavailable (skip feature, continue)
- Invalid input parameter (return null/false, log warning)

```gdscript
func load_spell(spell_id: String) -> SpellData:
    var resource = load(path) as SpellData
    if resource == null:
        _logger.log_error("Failed to load spell: " + spell_id + " from " + path)
        return null  # Safe default: null indicates failure
    return resource
```

### Fatal Errors

**Pattern:** Log error, return null/false, emit signal if needed

**Examples:**
- Critical system dependency missing (autoload singleton)
- Data corruption detected
- Invalid state that prevents operation

```gdscript
func gain_xp(amount: int) -> void:
    if PlayerStats == null:
        _logger.log_error("PlayerStats is null, cannot gain XP")
        return  # Cannot continue without PlayerStats
    # ... proceed with XP gain
```

### Invalid Input

**Pattern:** Always log, never silently skip

**Examples:**
- Invalid stat name
- Negative values when positive expected
- Out-of-range indices

```gdscript
func set_base_stat_level(stat_name: String, level: int) -> void:
    if level < 0:
        _logger.log_error("Invalid level: " + str(level) + " (must be >= 0)")
        return
    # ... proceed with setting level
```

## Logging Standards

- **Error (`log_error`)**: System failures, missing dependencies, invalid states
- **Warning (`log`)**: Recoverable issues, deprecated usage, fallback behavior
- **Debug/Info (`log`)**: Normal operations (will use log levels in Phase 4)

## Return Value Patterns

### Nullable Resources

Return `null` when resource cannot be loaded:
```gdscript
func load_spell(spell_id: String) -> SpellData:
    # Returns SpellData or null
```

### Boolean Success/Failure

Return `bool` for operations that can fail:
```gdscript
func consume_mana(cost: int) -> bool:
    # Returns true if successful, false if failed
```

### Safe Defaults

Return safe default values when possible:
```gdscript
func get_max_health() -> int:
    # Always returns a valid integer (never negative)
```

## Signal Patterns

Emit signals for cross-system notifications when errors occur:
```gdscript
if critical_error:
    error_occurred.emit(error_type, error_message)
```

## Best Practices

1. **Check dependencies early**: Validate autoload singletons at start of methods
2. **Validate inputs**: Check parameters before processing
3. **Use type hints**: Leverage Godot's type system for compile-time checks
4. **Document error cases**: Comment what errors can occur and how they're handled
5. **Test error paths**: Ensure error handling works in edge cases

