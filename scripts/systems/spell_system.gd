extends Node
## Global spell system (autoload singleton).
## Manages element levels, XP tracking, spell damage calculation, and spell validation.

# Logging
const LOG_PREFIX := "[SPELL_SYSTEM] "

# Constants (LOCKED per SPEC.md)
const ELEMENTS: Array[String] = ["fire", "water", "earth", "air"]
const XP_PER_LEVEL_MULTIPLIER: int = 100  # XP needed = level * 100

# Signals (LOCKED NAMES per SPEC.md)
signal element_leveled_up(element: String, new_level: int)
signal xp_gained(element: String, amount: int, total: int)


func _log(msg: String) -> void:
	print(LOG_PREFIX + msg)


func _log_error(msg: String) -> void:
	push_error(LOG_PREFIX + "ERROR: " + msg)
	print(LOG_PREFIX + "❌ ERROR: " + msg)

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
	_log("  XP per level multiplier: " + str(XP_PER_LEVEL_MULTIPLIER))
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


func get_xp_for_next_level(element: String) -> int:
	"""Returns the total XP needed to reach the next level."""
	var current_level: int = get_level(element)
	return current_level * XP_PER_LEVEL_MULTIPLIER


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
	var xp_needed: int = get_xp_for_next_level(element)
	var current_xp: int = element_xp[element]
	
	# Check if we have enough XP to level up
	if current_xp >= xp_needed:
		# Level up
		element_levels[element] += 1
		var new_level: int = element_levels[element]
		
		_log("🎉 " + element.capitalize() + " LEVELED UP! Level " + str(current_level) + " → " + str(new_level) + " (XP: " + str(current_xp) + "/" + str(xp_needed) + ")")
		
		# Emit signal for UI updates and game events
		element_leveled_up.emit(element, new_level)
		
		# Also emit to EventBus if available (for consistency)
		if EventBus != null:
			EventBus.level_up.emit(element, new_level)
			_log("  ✓ Emitted EventBus.level_up signal")
		else:
			_log("  ⚠ EventBus not available")
		
		# Recursively check for multiple level-ups (if XP is high enough)
		_check_level_up(element)
	else:
		# Log progress towards next level
		var xp_remaining: int = xp_needed - current_xp
		_log("  📊 Progress: " + str(current_xp) + "/" + str(xp_needed) + " XP (" + str(xp_remaining) + " remaining for level " + str(current_level + 1) + ")")


func get_spell_damage(spell: SpellData) -> int:
	"""Calculates spell damage using the locked formula per SPEC.md."""
	if spell == null:
		_log_error("get_spell_damage() called with null spell")
		return 0
	
	if not element_levels.has(spell.element):
		_log_error("get_spell_damage() called with unknown element: " + spell.element)
		return spell.base_damage  # Return base damage only
	
	var base: int = spell.base_damage
	var int_bonus: int = PlayerStats.get_total_int() * 2
	var level_bonus: int = (element_levels[spell.element] - 1) * 5
	var total_damage: int = base + int_bonus + level_bonus
	
	_log("⚔️ Damage calc for " + spell.display_name + " (" + spell.element + "): base=" + str(base) + " + int_bonus=" + str(int_bonus) + " + level_bonus=" + str(level_bonus) + " = " + str(total_damage) + " [Level " + str(element_levels[spell.element]) + "]")
	
	return total_damage


func can_cast(spell: SpellData) -> bool:
	"""Validates if a spell can be cast (checks mana cost)."""
	if spell == null:
		_log("🚫 can_cast() called with null spell")
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
	
	# Future: Add cooldown checks, spell unlock checks, etc.
	return true


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
	
	# Check XP calculation
	for element in ELEMENTS:
		var level: int = element_levels[element]
		var expected_xp_needed: int = level * XP_PER_LEVEL_MULTIPLIER
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

