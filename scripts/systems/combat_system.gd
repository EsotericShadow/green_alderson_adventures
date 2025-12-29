extends Node
## Global combat system (autoload singleton).
## Handles combat-related calculations like damage reduction.

# Logging
var _logger = GameLogger.create("[CombatSystem] ")


func _ready() -> void:
	_logger.log_info("CombatSystem initialized")


## Calculates damage reduction based on resilience with diminishing returns.
## 
## Args:
##   incoming_damage: Base damage amount
##   resilience: Total resilience stat value
## 
## Returns: Reduced damage (minimum 1)
func calculate_damage_reduction(incoming_damage: int, resilience: int) -> int:
	return StatFormulas.calculate_damage_reduction(incoming_damage, resilience)

