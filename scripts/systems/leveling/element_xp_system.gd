extends Node
## Global element XP and leveling system (autoload singleton).
## Manages element levels and XP tracking.

# Logging
var _logger = GameLogger.create("[ElementXPSystem] ")

# Signals (LOCKED NAMES per SPEC.md)
signal element_leveled_up(element: String, new_level: int)
signal xp_gained(element: String, amount: int, total: int)

# Constants (LOCKED per SPEC.md)
const ELEMENTS: Array[String] = ["fire", "water", "earth", "air"]

# Element Levels (LOCKED STRUCTURE per SPEC.md)
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


func _ready() -> void:
	_logger.log_info("ElementXPSystem initialized")
	_logger.log_info("  Elements: " + str(ELEMENTS))
	_logger.log_info("  XP System: RuneScape-style exponential curve")
	for element in ELEMENTS:
		_logger.log_info("  " + element.capitalize() + ": Level " + str(element_levels[element]) + ", XP: " + str(element_xp[element]))


## Returns the current level for the specified element.
func get_level(element: String) -> int:
	if not element_levels.has(element):
		_logger.log_error("get_level() called with unknown element: " + element)
		return 1  # Default to level 1 for unknown elements
	return element_levels[element]


## Returns the current XP for the specified element.
func get_xp(element: String) -> int:
	if not element_xp.has(element):
		_logger.log_error("get_xp() called with unknown element: " + element)
		return 0  # Default to 0 XP for unknown elements
	return element_xp[element]


## Returns the total XP needed for the current level (using RuneScape XP formula).
func get_xp_for_current_level(element: String) -> int:
	var current_level: int = get_level(element)
	return XPFormula.get_xp_for_current_level(current_level)


## Returns the total XP needed to reach the next level (using RuneScape XP formula).
func get_xp_for_next_level(element: String) -> int:
	var current_level: int = get_level(element)
	return XPFormula.get_xp_for_next_level(current_level)


## Gains XP for the specified element and checks for level-up.
func gain_xp(element: String, amount: int) -> void:
	if not element_levels.has(element) or not element_xp.has(element):
		_logger.log_error("gain_xp() called with unknown element: " + element)
		return  # Invalid element
	
	if amount <= 0:
		_logger.log("gain_xp() called with amount <= 0 for " + element + ", ignoring")
		return  # No XP to gain
	
	var old_xp: int = element_xp[element]
	element_xp[element] += amount
	var total_xp: int = element_xp[element]
	var current_level: int = element_levels[element]
	
	_logger.log("✨ " + element.capitalize() + " gained " + str(amount) + " XP (" + str(old_xp) + " → " + str(total_xp) + ") [Level " + str(current_level) + "]")
	
	# Emit signal for UI updates
	xp_gained.emit(element, amount, total_xp)
	
	# Check for level-up
	_check_level_up(element)


func _check_level_up(element: String) -> void:
	"""Checks if the element should level up and handles it."""
	if not element_levels.has(element) or not element_xp.has(element):
		_logger.log_error("_check_level_up() called with unknown element: " + element)
		return
	
	var current_level: int = element_levels[element]
	var current_xp: int = element_xp[element]
	
	# Calculate what level this XP should correspond to (using RuneScape formula)
	var calculated_level: int = XPFormula.get_level_from_xp(current_xp)
	
	# Get max level from GameBalance config
	var max_level: int = GameBalance.get_max_element_level()
	
	# Cap calculated level to max
	if calculated_level > max_level:
		calculated_level = max_level
	
	# Check if we should level up
	if calculated_level > current_level:
		# Level up to the calculated level (could be multiple levels)
		var old_level: int = current_level
		element_levels[element] = calculated_level
		var new_level: int = element_levels[element]
		
		var xp_for_new_level: int = XPFormula.get_xp_for_level(new_level)
		_logger.log("🎉 " + element.capitalize() + " LEVELED UP! Level " + str(old_level) + " → " + str(new_level) + " (XP: " + str(current_xp) + ", needed: " + str(xp_for_new_level) + ")")
		
		# Emit signal for UI updates and game events
		element_leveled_up.emit(element, new_level)
		
		# Also emit to EventBus if available (for consistency)
		if EventBus != null:
			EventBus.level_up.emit(element, new_level)
			_logger.log("  ✓ Emitted EventBus.level_up signal")
		else:
			_logger.log("  ⚠ EventBus not available")
	else:
		# Log progress towards next level
		var xp_for_next: int = XPFormula.get_xp_for_next_level(current_level)
		var xp_remaining: int = xp_for_next - current_xp
		_logger.log("  📊 Progress: " + str(current_xp) + "/" + str(xp_for_next) + " XP (" + str(xp_remaining) + " remaining for level " + str(current_level + 1) + ")")

