extends Node
## Gameplay Event Bus - handles gameplay-related signals (items, chests, spells, level ups).

# Logging
var _logger = GameLogger.create("[GameplayEventBus] ")

# Gameplay Signals (LOCKED NAMES per SPEC.md)
@warning_ignore("unused_signal")
signal item_picked_up(item: ItemData, count: int)
@warning_ignore("unused_signal")
signal item_used(item: ItemData)
@warning_ignore("unused_signal")
signal chest_opened(chest_position: Vector2)
@warning_ignore("unused_signal")
signal spell_cast(spell: SpellData)
@warning_ignore("unused_signal")
signal level_up(element: String, new_level: int)


func _ready() -> void:
	_logger.log("GameplayEventBus initialized")

