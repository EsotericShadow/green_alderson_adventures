extends Node
## Combat Event Bus - handles combat-related signals (enemy deaths, damage, etc.).

# Logging
var _logger = GameLogger.create("[CombatEventBus] ")

# Combat Signals (LOCKED NAMES per SPEC.md)
@warning_ignore("unused_signal")
signal enemy_killed(enemy_name: String, position: Vector2)


func _ready() -> void:
	_logger.log("CombatEventBus initialized")

