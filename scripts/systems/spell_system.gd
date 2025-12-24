extends Node
## Global spell system (autoload singleton).
## Manages element levels, XP tracking, spell damage calculation, and spell validation.

# Constants (LOCKED per SPEC.md)
const ELEMENTS: Array[String] = ["fire", "water", "earth", "air"]
const XP_PER_LEVEL_MULTIPLIER: int = 100  # XP needed = level * 100

# Signals (LOCKED NAMES per SPEC.md)
signal element_leveled_up(element: String, new_level: int)
signal xp_gained(element: String, amount: int, total: int)

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
	pass


# Methods (LOCKED SIGNATURES per SPEC.md)

func get_level(element: String) -> int:
	"""Returns the current level for the specified element."""
	if not element_levels.has(element):
		return 1  # Default to level 1 for unknown elements
	return element_levels[element]


func get_xp(element: String) -> int:
	"""Returns the current XP for the specified element."""
	if not element_xp.has(element):
		return 0  # Default to 0 XP for unknown elements
	return element_xp[element]


func get_xp_for_next_level(element: String) -> int:
	"""Returns the total XP needed to reach the next level."""
	var current_level: int = get_level(element)
	return current_level * XP_PER_LEVEL_MULTIPLIER


func gain_xp(element: String, amount: int) -> void:
	"""Gains XP for the specified element and checks for level-up."""
	if not element_levels.has(element) or not element_xp.has(element):
		return  # Invalid element
	
	if amount <= 0:
		return  # No XP to gain
	
	element_xp[element] += amount
	var total_xp: int = element_xp[element]
	
	# Emit signal for UI updates
	xp_gained.emit(element, amount, total_xp)
	
	# Check for level-up
	_check_level_up(element)


func _check_level_up(element: String) -> void:
	"""Checks if the element should level up and handles it."""
	if not element_levels.has(element) or not element_xp.has(element):
		return
	
	var current_level: int = element_levels[element]
	var xp_needed: int = get_xp_for_next_level(element)
	
	# Check if we have enough XP to level up
	if element_xp[element] >= xp_needed:
		# Level up
		element_levels[element] += 1
		var new_level: int = element_levels[element]
		
		# Emit signal for UI updates and game events
		element_leveled_up.emit(element, new_level)
		
		# Also emit to EventBus if available (for consistency)
		if EventBus != null:
			EventBus.level_up.emit(element, new_level)
		
		# Recursively check for multiple level-ups (if XP is high enough)
		_check_level_up(element)


func get_spell_damage(spell: SpellData) -> int:
	"""Calculates spell damage using the locked formula per SPEC.md."""
	if spell == null:
		return 0
	
	var base: int = spell.base_damage
	var int_bonus: int = PlayerStats.get_total_int() * 2
	var level_bonus: int = (element_levels[spell.element] - 1) * 5
	return base + int_bonus + level_bonus


func can_cast(spell: SpellData) -> bool:
	"""Validates if a spell can be cast (checks mana cost)."""
	if spell == null:
		return false
	
	# Check mana cost
	if PlayerStats != null:
		if not PlayerStats.has_mana(spell.mana_cost):
			return false
	
	# Future: Add cooldown checks, spell unlock checks, etc.
	return true

