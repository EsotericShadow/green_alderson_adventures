extends Node
## Global alchemy system (autoload singleton).
## Manages alchemy level, XP tracking, and potion potency scaling.
## Follows the same pattern as SpellSystem for consistency.

# Logging
var _logger = GameLogger.create("[ALCHEMY_SYSTEM] ")

# Constants
const SKILL_NAME: String = "alchemy"
const MAX_ALCHEMY_LEVEL: int = 110  # Use GameBalance.get_max_alchemy_level() if available

# Signals
signal alchemy_leveled_up(new_level: int)
signal xp_gained(amount: int, total: int)

# Alchemy Level and XP (LOCKED STRUCTURE)
var alchemy_level: int = 1
var alchemy_xp: int = 0


func _ready() -> void:
	_logger.log("AlchemySystem initialized")
	_logger.log("  Level: " + str(alchemy_level) + ", XP: " + str(alchemy_xp))
	_logger.log("  XP System: RuneScape-style exponential curve")
	
	# Validate system integrity
	_validate_system()


func _validate_system() -> void:
	"""Validates system integrity."""
	if alchemy_level < 1:
		_logger.log_error("Invalid alchemy_level: " + str(alchemy_level) + ", resetting to 1")
		alchemy_level = 1
	
	if alchemy_xp < 0:
		_logger.log_error("Invalid alchemy_xp: " + str(alchemy_xp) + ", resetting to 0")
		alchemy_xp = 0


# Methods (LOCKED SIGNATURES)

func get_level() -> int:
	"""Returns the current alchemy level."""
	return alchemy_level


func get_xp() -> int:
	"""Returns the current alchemy XP."""
	return alchemy_xp


func get_xp_for_current_level() -> int:
	"""Returns the total XP needed for the current level (using RuneScape XP formula)."""
	return XPFormula.get_xp_for_current_level(alchemy_level) if XPFormula != null else 0


func get_xp_for_next_level() -> int:
	"""Returns the total XP needed to reach the next level (using RuneScape XP formula)."""
	return XPFormula.get_xp_for_next_level(alchemy_level) if XPFormula != null else 100


func gain_xp(amount: int) -> void:
	"""Gains alchemy XP and checks for level-up."""
	if amount <= 0:
		_logger.log("gain_xp() called with amount <= 0, ignoring")
		return
	
	var old_xp: int = alchemy_xp
	alchemy_xp += amount
	var total_xp: int = alchemy_xp
	
	_logger.log("✨ Alchemy gained " + str(amount) + " XP (" + str(old_xp) + " → " + str(total_xp) + ") [Level " + str(alchemy_level) + "]")
	
	# Emit signal for UI updates
	xp_gained.emit(amount, total_xp)
	
	# Check for level-up
	_check_level_up()


func _check_level_up() -> void:
	"""Checks if alchemy should level up and handles it."""
	var current_level: int = alchemy_level
	var current_xp: int = alchemy_xp
	
	# Calculate what level this XP should correspond to (using RuneScape formula)
	var calculated_level: int = XPFormula.get_level_from_xp(current_xp) if XPFormula != null else current_level
	
	# Get max level from GameBalance config if available
	var max_level: int = MAX_ALCHEMY_LEVEL
	if GameBalance != null and GameBalance.has_method("get_max_alchemy_level"):
		max_level = GameBalance.get_max_alchemy_level()
	
	# Cap calculated level to max
	if calculated_level > max_level:
		calculated_level = max_level
	
	# Check if we should level up
	if calculated_level > current_level:
		# Level up to the calculated level (could be multiple levels)
		var old_level: int = current_level
		alchemy_level = calculated_level
		var new_level: int = alchemy_level
		
		var xp_for_new_level: int = XPFormula.get_xp_for_level(new_level) if XPFormula != null else 0
		_logger.log("🎉 Alchemy LEVELED UP! Level " + str(old_level) + " → " + str(new_level) + " (XP: " + str(current_xp) + ", needed: " + str(xp_for_new_level) + ")")
		
		# Emit signal for UI updates and game events
		alchemy_leveled_up.emit(new_level)
		
		# Also emit to EventBus if available (for consistency)
		if EventBus != null:
			EventBus.level_up.emit(SKILL_NAME, new_level)
			_logger.log("  ✓ Emitted EventBus.level_up signal")
		else:
			_logger.log("  ⚠ EventBus not available")
	else:
		# Log progress towards next level
		var xp_for_next: int = get_xp_for_next_level()
		var xp_remaining: int = xp_for_next - current_xp
		_logger.log("  📊 Progress: " + str(current_xp) + "/" + str(xp_for_next) + " XP (" + str(xp_remaining) + " remaining for level " + str(current_level + 1) + ")")


func calculate_scaled_potency(base_potency: int, potency_per_level: int, required_level: int) -> int:
	"""Calculates scaled potency based on alchemy level.
	
	Args:
		base_potency: Base potency value at required_level
		potency_per_level: Additional potency per level above required_level
		required_level: Minimum alchemy level needed
	
	Returns: Scaled potency value
	"""
	if alchemy_level < required_level:
		_logger.log_error("calculate_scaled_potency() called but alchemy level (" + str(alchemy_level) + ") < required level (" + str(required_level) + ")")
		return base_potency  # Return base if below required level
	
	var levels_above_required: int = alchemy_level - required_level
	var scaled_potency: int = base_potency + (potency_per_level * levels_above_required)
	
	return scaled_potency

