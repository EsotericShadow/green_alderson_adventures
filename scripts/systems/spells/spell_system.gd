extends Node
## Global spell system (autoload singleton) - FACADE.
## Delegates to focused subsystems while maintaining backwards-compatible API.
## Manages element levels, XP tracking, spell damage calculation, and spell validation.
##
## Delegates to:
## - ElementXPSystem: Element XP and leveling
## - ElementBuffSystem: Element damage buffs

# Logging
var _logger = GameLogger.create("[SPELL_SYSTEM] ")

# Constants (LOCKED per SPEC.md)
const ELEMENTS: Array[String] = ["fire", "water", "earth", "air"]

# Signals (LOCKED NAMES per SPEC.md)
signal element_leveled_up(element: String, new_level: int)
signal xp_gained(element: String, amount: int, total: int)


func _log(msg: String) -> void:
	_logger.log(msg)


func _log_error(msg: String) -> void:
	_logger.log_error(msg)


func _ready() -> void:
	_log("SpellSystem initialized (facade)")
	_log("  Elements: " + str(ELEMENTS))
	_log("  XP System: RuneScape-style exponential curve")
	
	# Connect to ElementXPSystem signals and forward them
	if ElementXPSystem != null:
		ElementXPSystem.element_leveled_up.connect(_on_element_leveled_up)
		ElementXPSystem.xp_gained.connect(_on_xp_gained)
		
		for element in ELEMENTS:
			_log("  " + element.capitalize() + ": Level " + str(ElementXPSystem.get_level(element)) + ", XP: " + str(ElementXPSystem.get_xp(element)))
	else:
		_log_error("ElementXPSystem not available - element features will not work")
	
	# Validate system integrity
	_validate_system()


func _on_element_leveled_up(element: String, new_level: int) -> void:
	"""Forwards element_leveled_up signal from ElementXPSystem."""
	element_leveled_up.emit(element, new_level)


func _on_xp_gained(element: String, amount: int, total: int) -> void:
	"""Forwards xp_gained signal from ElementXPSystem."""
	xp_gained.emit(element, amount, total)


# Methods (LOCKED SIGNATURES per SPEC.md) - delegates to ElementXPSystem

func get_level(element: String) -> int:
	"""Returns the current level for the specified element - delegates to ElementXPSystem."""
	if ElementXPSystem != null:
		return ElementXPSystem.get_level(element)
	_log_error("ElementXPSystem not available")
	return 1


func get_xp(element: String) -> int:
	"""Returns the current XP for the specified element - delegates to ElementXPSystem."""
	if ElementXPSystem != null:
		return ElementXPSystem.get_xp(element)
	_log_error("ElementXPSystem not available")
	return 0


func get_xp_for_current_level(element: String) -> int:
	"""Returns the total XP needed for the current level - delegates to ElementXPSystem."""
	if ElementXPSystem != null:
		return ElementXPSystem.get_xp_for_current_level(element)
	return 0


func get_xp_for_next_level(element: String) -> int:
	"""Returns the total XP needed to reach the next level - delegates to ElementXPSystem."""
	if ElementXPSystem != null:
		return ElementXPSystem.get_xp_for_next_level(element)
	return 100


func gain_xp(element: String, amount: int) -> void:
	"""Gains XP for the specified element - delegates to ElementXPSystem."""
	if ElementXPSystem != null:
		ElementXPSystem.gain_xp(element, amount)
	else:
		_log_error("ElementXPSystem not available")


# Backwards compatibility: expose element_levels and element_xp dictionaries
var element_levels: Dictionary:
	get:
		if ElementXPSystem != null:
			return ElementXPSystem.element_levels
		return {}

var element_xp: Dictionary:
	get:
		if ElementXPSystem != null:
			return ElementXPSystem.element_xp
		return {}


func get_spell_damage(spell: SpellData) -> int:
	"""Calculates spell damage: base + level bonus + equipment modifiers + element buffs."""
	if spell == null:
		_log_error("get_spell_damage() called with null spell")
		return 0
	
	if ElementXPSystem == null:
		_log_error("ElementXPSystem not available")
		return spell.base_damage
	
	var element_level: int = ElementXPSystem.get_level(spell.element)
	
	# Equipment modifiers (flat + percentage)
	var flat_bonus: int = 0
	var percentage_bonus: float = 0.0
	if InventorySystem != null:
		flat_bonus = InventorySystem.get_total_damage_bonus()
		percentage_bonus = InventorySystem.get_total_damage_percentage()
	
	# Get element multiplier from ElementBuffSystem
	var element_multiplier: float = 1.0
	if ElementBuffSystem != null:
		element_multiplier = ElementBuffSystem.get_element_multiplier(spell.element)
	
	# Calculate damage using utility
	var total_damage: int = SpellDamageCalculator.calculate_spell_damage(
		spell,
		element_level,
		5,  # level_bonus_per_level
		flat_bonus,
		percentage_bonus,
		element_multiplier
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
	
	# Check ElementXPSystem
	if ElementXPSystem == null:
		_log_error("ElementXPSystem not available")
	else:
		_log("  ✓ ElementXPSystem available")
	
	# Check ElementBuffSystem
	if ElementBuffSystem == null:
		_log("  ⚠ ElementBuffSystem not available (buffs will not work)")
	else:
		_log("  ✓ ElementBuffSystem available")
	
	# Check PlayerStats integration
	if PlayerStats == null:
		_log("  ⚠ PlayerStats not available (damage calculation will fail)")
	else:
		_log("  ✓ PlayerStats available")
	
	# Check EventBus integration
	if EventBus == null:
		_log("  ⚠ EventBus not available (level_up signal won't be emitted)")
	else:
		_log("  ✓ EventBus available")
	
		_log("  ✓ System validation passed")


## Applies an element damage buff for a specified duration - delegates to ElementBuffSystem.
## 
## Args:
##   element: Element to buff ("fire", "water", "earth", "air")
##   multiplier: Damage multiplier (1.3 = +30% damage)
##   duration: Duration in seconds
func apply_element_buff(element: String, multiplier: float, duration: float) -> void:
	if ElementBuffSystem != null:
		ElementBuffSystem.apply_element_buff(element, multiplier, duration)
	else:
		_log_error("ElementBuffSystem not available")
