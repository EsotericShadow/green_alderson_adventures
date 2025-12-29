extends RefCounted
class_name StatFormulas
## Utility class for stat-based calculations and formulas.
## Contains all stat-related formulas for damage reduction, multipliers, etc.

# Defense formula constants (diminishing returns)
const DEFENSE_BASE_FACTOR: float = 0.1  # Base defense per resilience point
const DEFENSE_DIMINISHING_FACTOR: float = 0.05  # Diminishing returns factor

# Agility formula constants
const STAMINA_CONSUMPTION_REDUCTION_PER_AGILITY: float = 0.02  # 2% reduction per agility point
const STAMINA_CONSUMPTION_MIN_MULTIPLIER: float = 0.3  # Minimum consumption (70% max reduction)
const MOVEMENT_SPEED_BONUS_PER_AGILITY: float = 0.03  # 3% speed increase per agility point
const MOVEMENT_SPEED_MAX_MULTIPLIER: float = 2.0  # Maximum 2x speed

# Carry weight constants
const BASE_CARRY_WEIGHT: float = 45.0  # Base carry weight in kg
const CARRY_WEIGHT_PER_RESILIENCE: float = 2.0  # +2kg per resilience point
const SLOW_DOWN_THRESHOLD: float = 0.85  # 85% weight for slow down effect


## Calculates damage reduction based on resilience with diminishing returns and plateaus.
## 
## Args:
##   incoming_damage: Base damage amount
##   resilience: Total resilience stat value
## 
## Returns: Reduced damage (minimum 1)
static func calculate_damage_reduction(incoming_damage: int, resilience: int) -> int:
	if resilience <= 0:
		return incoming_damage
	
	# Diminishing returns formula: damage / (1 + resilience * factor)
	# Higher resilience = less damage taken, but with diminishing returns
	var defense_factor: float = DEFENSE_BASE_FACTOR + (resilience * DEFENSE_DIMINISHING_FACTOR)
	var reduction_multiplier: float = 1.0 / (1.0 + resilience * defense_factor)
	
	# Apply plateaus at certain thresholds for boosts
	if resilience >= 20:
		reduction_multiplier *= 0.9  # 10% boost at 20 resilience
	if resilience >= 40:
		reduction_multiplier *= 0.9  # Additional 10% boost at 40 resilience
	if resilience >= 60:
		reduction_multiplier *= 0.95  # Additional 5% boost at 60 resilience
	
	var reduced_damage: int = int(incoming_damage * reduction_multiplier)
	return max(1, reduced_damage)  # Minimum 1 damage


## Calculates maximum carry weight based on resilience.
## 
## Args:
##   resilience: Total resilience stat value
## 
## Returns: Maximum carry weight in kg
static func calculate_max_carry_weight(resilience: int) -> float:
	return BASE_CARRY_WEIGHT + (resilience * CARRY_WEIGHT_PER_RESILIENCE)


## Calculates stamina consumption multiplier based on agility.
## Lower multiplier = less stamina used (more efficient).
## 
## Args:
##   agility: Total agility stat value
## 
## Returns: Consumption multiplier (0.3 to 1.0)
static func calculate_stamina_consumption_multiplier(agility: int) -> float:
	# Higher agility = lower consumption (more efficient)
	# Formula: 1.0 - (agility * 0.02) with minimum of 0.3
	return max(STAMINA_CONSUMPTION_MIN_MULTIPLIER, 1.0 - (agility * STAMINA_CONSUMPTION_REDUCTION_PER_AGILITY))


## Calculates movement speed multiplier based on agility.
## 
## Args:
##   agility: Total agility stat value
## 
## Returns: Speed multiplier (1.0 to 2.0)
static func calculate_movement_speed_multiplier(agility: int) -> float:
	# Higher agility = faster movement
	# Formula: 1.0 + (agility * 0.03) with maximum of 2.0
	return min(MOVEMENT_SPEED_MAX_MULTIPLIER, 1.0 + (agility * MOVEMENT_SPEED_BONUS_PER_AGILITY))


## Calculates movement speed multiplier when carrying heavy load.
## Applies slow-down effect when carrying 85%+ of max weight.
## 
## Args:
##   current_weight: Current carry weight in kg
##   max_weight: Maximum carry weight in kg
## 
## Returns: Speed multiplier (0.1 to 1.0)
static func calculate_carry_weight_slow_multiplier(current_weight: float, max_weight: float) -> float:
	if max_weight <= 0:
		return 1.0
	
	var weight_percentage: float = current_weight / max_weight
	if weight_percentage >= SLOW_DOWN_THRESHOLD:
		# Slow down effect: 0.5x speed at 85%, scaling to 0.1x at 100%
		var excess: float = (weight_percentage - SLOW_DOWN_THRESHOLD) / (1.0 - SLOW_DOWN_THRESHOLD)
		return max(0.1, 1.0 - (excess * 0.9))  # 0.5x to 0.1x
	
	return 1.0

