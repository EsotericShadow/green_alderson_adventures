extends Node
## Global movement system (autoload singleton).
## Handles movement-related calculations like stamina consumption and speed multipliers.

# Logging
var _logger = GameLogger.create("[MovementSystem] ")


func _ready() -> void:
	_logger.log_info("MovementSystem initialized")


## Returns stamina consumption multiplier based on agility (lower = less stamina used).
## 
## Args:
##   agility: Total agility stat value
## 
## Returns: Consumption multiplier (0.3 to 1.0)
func get_stamina_consumption_multiplier(agility: int) -> float:
	return StatFormulas.calculate_stamina_consumption_multiplier(agility)


## Returns movement speed multiplier based on agility.
## 
## Args:
##   agility: Total agility stat value
## 
## Returns: Speed multiplier (1.0 to 2.0)
func get_movement_speed_multiplier(agility: int) -> float:
	return StatFormulas.calculate_movement_speed_multiplier(agility)


## Returns maximum carry weight in kg based on resilience.
## 
## Returns: Maximum carry weight in kg
func get_max_carry_weight() -> float:
	"""Returns maximum carry weight in kg based on resilience."""
	if PlayerStats == null:
		_logger.log_error("PlayerStats not available for get_max_carry_weight")
		return 0.0
	
	var resilience: int = PlayerStats.get_total_resilience()
	return StatFormulas.calculate_max_carry_weight(resilience)


## Returns movement speed multiplier when carrying heavy load (85%+ weight).
## 
## Returns: Speed multiplier (0.5 to 1.0)
func get_carry_weight_slow_multiplier() -> float:
	"""Returns movement speed multiplier when carrying heavy load (85%+ weight)."""
	var current_weight: float = 0.0
	var max_weight: float = get_max_carry_weight()
	
	if InventorySystem != null:
		current_weight = InventorySystem.get_current_carry_weight()
	else:
		_logger.log_error("InventorySystem not available for get_carry_weight_slow_multiplier")
		return 1.0
	
	return StatFormulas.calculate_carry_weight_slow_multiplier(current_weight, max_weight)

