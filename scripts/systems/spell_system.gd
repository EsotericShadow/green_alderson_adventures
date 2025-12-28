extends Node
## Global spell system (autoload singleton).
## Manages element levels, XP tracking, spell damage calculation, and spell validation.

# Logging
var _logger = GameLogger.create("[SPELL_SYSTEM] ")

# Constants (LOCKED per SPEC.md)
const ELEMENTS: Array[String] = ["fire", "water", "earth", "air"]
const MAX_ELEMENT_LEVEL: int = 110  # Maximum level for spell elements
# XP system: Using RuneScape-style exponential XP curve (see XPFormula)

# Signals (LOCKED NAMES per SPEC.md)
signal element_leveled_up(element: String, new_level: int)
signal xp_gained(element: String, amount: int, total: int)


func _log(msg: String) -> void:
	_logger.log(msg)


func _log_error(msg: String) -> void:
	_logger.log_error(msg)

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
	# Initialize all elements to level 1 with 0 XP
	# (Already initialized in variable declarations, but ensure consistency)
	_log("SpellSystem initialized")
	_log("  Elements: " + str(ELEMENTS))
	_log("  XP System: RuneScape-style exponential curve")
	for element in ELEMENTS:
		_log("  " + element.capitalize() + ": Level " + str(element_levels[element]) + ", XP: " + str(element_xp[element]))
	
	# Validate system integrity
	_validate_system()


# Methods (LOCKED SIGNATURES per SPEC.md)

func get_level(element: String) -> int:
	"""Returns the current level for the specified element."""
	if not element_levels.has(element):
		_log_error("get_level() called with unknown element: " + element)
		return 1  # Default to level 1 for unknown elements
	return element_levels[element]


func get_xp(element: String) -> int:
	"""Returns the current XP for the specified element."""
	if not element_xp.has(element):
		_log_error("get_xp() called with unknown element: " + element)
		return 0  # Default to 0 XP for unknown elements
	return element_xp[element]


func get_xp_for_current_level(element: String) -> int:
	"""Returns the total XP needed for the current level (using RuneScape XP formula)."""
	var current_level: int = get_level(element)
	return XPFormula.get_xp_for_current_level(current_level)


func get_xp_for_next_level(element: String) -> int:
	"""Returns the total XP needed to reach the next level (using RuneScape XP formula)."""
	var current_level: int = get_level(element)
	return XPFormula.get_xp_for_next_level(current_level)


func gain_xp(element: String, amount: int) -> void:
	"""Gains XP for the specified element and checks for level-up."""
	if not element_levels.has(element) or not element_xp.has(element):
		_log_error("gain_xp() called with unknown element: " + element)
		return  # Invalid element
	
	if amount <= 0:
		_log("gain_xp() called with amount <= 0 for " + element + ", ignoring")
		return  # No XP to gain
	
	var old_xp: int = element_xp[element]
	element_xp[element] += amount
	var total_xp: int = element_xp[element]
	var current_level: int = element_levels[element]
	
	_log("✨ " + element.capitalize() + " gained " + str(amount) + " XP (" + str(old_xp) + " → " + str(total_xp) + ") [Level " + str(current_level) + "]")
	
	# Emit signal for UI updates
	xp_gained.emit(element, amount, total_xp)
	
	# Check for level-up
	_check_level_up(element)


func _check_level_up(element: String) -> void:
	"""Checks if the element should level up and handles it."""
	if not element_levels.has(element) or not element_xp.has(element):
		_log_error("_check_level_up() called with unknown element: " + element)
		return
	
	var current_level: int = element_levels[element]
	var current_xp: int = element_xp[element]
	
	# Calculate what level this XP should correspond to (using RuneScape formula)
	var calculated_level: int = XPFormula.get_level_from_xp(current_xp)
	
	# Cap calculated level to max
	if calculated_level > MAX_ELEMENT_LEVEL:
		calculated_level = MAX_ELEMENT_LEVEL
	
	# Check if we should level up
	if calculated_level > current_level:
		# Level up to the calculated level (could be multiple levels)
		var old_level: int = current_level
		element_levels[element] = calculated_level
		var new_level: int = element_levels[element]
		
		var xp_for_new_level: int = XPFormula.get_xp_for_level(new_level)
		_log("🎉 " + element.capitalize() + " LEVELED UP! Level " + str(old_level) + " → " + str(new_level) + " (XP: " + str(current_xp) + ", needed: " + str(xp_for_new_level) + ")")
		
		# Emit signal for UI updates and game events
		element_leveled_up.emit(element, new_level)
		
		# Also emit to EventBus if available (for consistency)
		if EventBus != null:
			EventBus.level_up.emit(element, new_level)
			_log("  ✓ Emitted EventBus.level_up signal")
		else:
			_log("  ⚠ EventBus not available")
	else:
		# Log progress towards next level
		var xp_for_next: int = XPFormula.get_xp_for_next_level(current_level)
		var xp_remaining: int = xp_for_next - current_xp
		_log("  📊 Progress: " + str(current_xp) + "/" + str(xp_for_next) + " XP (" + str(xp_remaining) + " remaining for level " + str(current_level + 1) + ")")


func get_spell_damage(spell: SpellData) -> int:
	"""Calculates spell damage: base + level bonus + equipment modifiers."""
	if spell == null:
		_log_error("get_spell_damage() called with null spell")
		return 0
	
	if not element_levels.has(spell.element):
		_log_error("get_spell_damage() called with unknown element: " + spell.element)
		return spell.base_damage  # Return base damage only
	
	var element_level: int = element_levels[spell.element]
	
	# Equipment modifiers (flat + percentage)
	var flat_bonus: int = 0
	var percentage_bonus: float = 0.0
	if InventorySystem != null:
		flat_bonus = InventorySystem.get_total_damage_bonus()
		percentage_bonus = InventorySystem.get_total_damage_percentage()
	
	# Calculate damage using utility
	var total_damage: int = DamageCalculator.calculate_spell_damage(
		spell.base_damage,
		element_level,
		5,  # level_bonus_per_level
		flat_bonus,
		percentage_bonus
	)
	
	_log("⚔️ Damage calc for " + spell.display_name + " (" + spell.element + "): base=" + str(spell.base_damage) + " + level_bonus=" + str((element_level - 1) * 5) + " + flat_bonus=" + str(flat_bonus) + " * (1 + " + str(percentage_bonus) + ") = " + str(total_damage) + " [Level " + str(element_level) + "]")
	
	return total_damage


func can_cast(spell: SpellData) -> bool:
	"""Validates if a spell can be cast (checks mana cost and unlock level)."""
	if spell == null:
		_log("🚫 can_cast() called with null spell")
		return false
	
	# Check if spell is unlocked
	if not is_spell_unlocked(spell):
		_log("🚫 Cannot cast " + spell.display_name + ": spell not unlocked (requires level " + str(spell.unlock_level) + ", current: " + str(get_level(spell.element)) + ")")
		return false
	
	# Check mana cost
	if PlayerStats != null:
		var has_mana: bool = PlayerStats.has_mana(spell.mana_cost)
		if not has_mana:
			var current_mana: int = PlayerStats.mana
			var max_mana: int = PlayerStats.get_max_mana()
			_log("🚫 Cannot cast " + spell.display_name + ": insufficient mana (" + str(current_mana) + "/" + str(max_mana) + " < " + str(spell.mana_cost) + ")")
			return false
		else:
			_log("✓ Can cast " + spell.display_name + " (mana: " + str(PlayerStats.mana) + "/" + str(PlayerStats.get_max_mana()) + " >= " + str(spell.mana_cost) + ")")
	else:
		_log_error("PlayerStats not available for can_cast() check")
		return false
	
	# Future: Add cooldown checks, etc.
	return true


func is_spell_unlocked(spell: SpellData) -> bool:
	"""Checks if a spell is unlocked based on element level."""
	if spell == null:
		return false
	
	var current_level: int = get_level(spell.element)
	return current_level >= spell.unlock_level


func get_unlocked_spells(element: String) -> Array[SpellData]:
	"""Returns array of all unlocked spells for the specified element."""
	var unlocked: Array[SpellData] = []
	var current_level: int = get_level(element)
	
	# Load all spells for this element and filter by unlock level
	# Note: This assumes spells are loaded from resources/spells/ directory
	# For now, this is a placeholder - actual implementation would scan spell resources
	_log("get_unlocked_spells() called for " + element + " (level " + str(current_level) + ")")
	_log("  ⚠ Full implementation requires scanning spell resources directory")
	
	return unlocked


func _validate_system() -> void:
	"""Validates system integrity and logs any issues."""
	_log("🔍 Validating SpellSystem integrity...")
	
	# Check all elements are initialized
	var all_valid: bool = true
	for element in ELEMENTS:
		if not element_levels.has(element):
			_log_error("Missing element_levels entry for: " + element)
			all_valid = false
		if not element_xp.has(element):
			_log_error("Missing element_xp entry for: " + element)
			all_valid = false
		if element_levels[element] < 1:
			_log_error("Invalid level for " + element + ": " + str(element_levels[element]))
			all_valid = false
		if element_xp[element] < 0:
			_log_error("Invalid XP for " + element + ": " + str(element_xp[element]))
			all_valid = false
	
	# Check XP calculation (using RuneScape formula)
	for element in ELEMENTS:
		var level: int = element_levels[element]
		var expected_xp_needed: int = XPFormula.get_xp_for_next_level(level)
		var actual_xp_needed: int = get_xp_for_next_level(element)
		if expected_xp_needed != actual_xp_needed:
			_log_error("XP calculation mismatch for " + element + ": expected " + str(expected_xp_needed) + ", got " + str(actual_xp_needed))
			all_valid = false
	
	# Check PlayerStats integration
	if PlayerStats == null:
		_log("  ⚠ PlayerStats not available (damage calculation will fail)")
		all_valid = false
	else:
		_log("  ✓ PlayerStats available")
	
	# Check EventBus integration
	if EventBus == null:
		_log("  ⚠ EventBus not available (level_up signal won't be emitted)")
	else:
		_log("  ✓ EventBus available")
	
	if all_valid:
		_log("  ✓ System validation passed")
	else:
		_log_error("System validation FAILED - check errors above")

