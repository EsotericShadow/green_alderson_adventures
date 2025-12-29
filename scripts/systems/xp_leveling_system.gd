extends Node
## Global XP and leveling system (autoload singleton).
## Manages base stat XP tracking and leveling.
## Handles base stat levels (base_resilience, base_agility, base_int, base_vit).

# Logging
var _logger = GameLogger.create("[XPLevelingSystem] ")

# Signals (LOCKED NAMES per SPEC.md)
signal stat_changed(stat_name: String, new_value: int)
signal base_stat_xp_gained(stat_name: String, amount: int, total: int)
signal base_stat_leveled_up(stat_name: String, new_level: int)
signal character_level_changed(new_level: int)

# Base Stats (RENAMED: STR→Resilience, DEX→Agility)
# These values represent both the stat value AND the level
var base_resilience: int = 1  # Formerly base_str
var base_agility: int = 1  # Formerly base_dex
var base_int: int = 1
var base_vit: int = 1

# Base stat XP tracking (public for GameState sync)
var base_stat_xp: Dictionary = {
	StatConstants.STAT_RESILIENCE: 0,
	StatConstants.STAT_AGILITY: 0,
	StatConstants.STAT_INT: 0,
	StatConstants.STAT_VIT: 0
}

# Vitality XP accumulator (tracks partial XP from other stats)
var _vitality_xp_accumulator: float = 0.0


func _ready() -> void:
	_logger.log_info("XPLevelingSystem initialized")
	
	# Connect to SpellSystem element level changes to update character level
	if SpellSystem != null:
		SpellSystem.element_leveled_up.connect(_on_element_leveled_up)
	
	# Connect to MovementTracker for heavy carry XP
	if MovementTracker != null:
		MovementTracker.heavy_carry_moved.connect(_on_heavy_carry_moved)
		_logger.log_info("Connected to MovementTracker for heavy carry XP")
	else:
		_logger.log_error("MovementTracker not available - heavy carry XP will not work")
	
	# Initialize character level
	_update_character_level()


func _on_element_leveled_up(_element: String, _new_level: int) -> void:
	"""Called when an element levels up to recalculate character level."""
	_update_character_level()


## Signal handler for heavy carry movement XP
func _on_heavy_carry_moved(xp_amount: float, weight_percentage: float) -> void:
	"""Handles heavy carry movement XP from MovementTracker.
	
	Args:
		xp_amount: Amount of XP to grant (already calculated by MovementTracker)
		weight_percentage: Current weight percentage (for logging/debugging)
	"""
	var xp_int: int = int(xp_amount)
	if xp_int > 0:
		_logger.log_info("Heavy carry XP granted: " + str(xp_int) + " (weight: " + str(snappedf(weight_percentage * 100, 0.1)) + "%)")
		gain_base_stat_xp(StatConstants.STAT_RESILIENCE, xp_int, StatConstants.STAT_RESILIENCE)


## Gains XP for a base stat and checks for level-up. Also triggers Vitality auto-gain.
## 
## Args:
##   stat_name: The stat to gain XP for (use StatConstants.STAT_*)
##   amount: Amount of XP to gain (must be > 0)
##   source_stat: The stat that triggered this XP gain (for cooldown tracking, defaults to stat_name)
func gain_base_stat_xp(stat_name: String, amount: int, source_stat: String = "") -> void:
	if not base_stat_xp.has(stat_name):
		_logger.log_error("gain_base_stat_xp() called with unknown stat: " + stat_name)
		return
	
	if amount <= 0:
		return  # Silently skip invalid amounts
	
	# Determine source stat for cooldown checking (VIT uses source stat's cooldown)
	var cooldown_stat: String = source_stat if source_stat != "" else stat_name
	
	# Check cooldown before granting XP
	if not XPCooldown.can_gain_xp(cooldown_stat):
		_logger.log_info("XP gain blocked by cooldown for " + cooldown_stat)
		return  # Silently skip if on cooldown
	
	# Record XP gain (uses source stat's cooldown for VIT)
	XPCooldown.record_xp_gain(cooldown_stat)
	
	var old_xp: int = base_stat_xp[stat_name]
	base_stat_xp[stat_name] += amount
	var total_xp: int = base_stat_xp[stat_name]
	
	_logger.log_info("✨ " + stat_name.capitalize() + " gained " + str(amount) + " XP (" + str(old_xp) + " → " + str(total_xp) + ")")
	
	# Emit signal for UI updates
	base_stat_xp_gained.emit(stat_name, amount, total_xp)
	
	# Check for level-up
	_check_base_stat_level_up(stat_name)
	
	# Vitality auto-gain: 1 VIT XP per N XP in other stats (respects source stat's cooldown)
	if stat_name != StatConstants.STAT_VIT:
		var vit_xp_ratio: int = GameBalance.get_vitality_xp_ratio()
		_vitality_xp_accumulator += float(amount) / float(vit_xp_ratio)
		if _vitality_xp_accumulator >= 1.0:
			var vit_xp: int = int(_vitality_xp_accumulator)
			_vitality_xp_accumulator -= float(vit_xp)
			# Pass source stat so VIT respects the source stat's cooldown
			gain_base_stat_xp(StatConstants.STAT_VIT, vit_xp, stat_name)


## Returns current XP for a base stat.
## 
## Args:
##   stat_name: The stat name (use StatConstants.STAT_*)
## 
## Returns:
##   Current total XP for the stat, or 0 if stat doesn't exist
func get_base_stat_xp(stat_name: String) -> int:
	if not base_stat_xp.has(stat_name):
		_logger.log_error("get_base_stat_xp() called with unknown stat: " + stat_name)
		return 0
	return base_stat_xp[stat_name]


## Returns the minimum total XP needed for the current level (using RuneScape XP formula).
## 
## Args:
##   stat_name: The stat name (use StatConstants.STAT_*)
## 
## Returns:
##   Total XP required for current level, or 0 if stat doesn't exist
func get_base_stat_xp_for_current_level(stat_name: String) -> int:
	if not base_stat_xp.has(stat_name):
		_logger.log_error("get_base_stat_xp_for_current_level() called with unknown stat: " + stat_name)
		return 0
	var current_level: int = get_base_stat_level(stat_name)
	return XPFormula.get_xp_for_current_level(current_level) if XPFormula != null else 0


## Returns the total XP needed to reach the next level for a base stat (using RuneScape XP formula).
## 
## Args:
##   stat_name: The stat name (use StatConstants.STAT_*)
## 
## Returns:
##   Total XP required for next level, or 100 if stat doesn't exist (fallback)
func get_base_stat_xp_for_next_level(stat_name: String) -> int:
	if not base_stat_xp.has(stat_name):
		_logger.log_error("get_base_stat_xp_for_next_level() called with unknown stat: " + stat_name)
		return 100  # Fallback default
	var current_level: int = get_base_stat_level(stat_name)
	return XPFormula.get_xp_for_next_level(current_level) if XPFormula != null else 100


## Returns display data for a base stat (single source of truth for UI)
## Uses stored level from XPLevelingSystem, not calculated from XP
## Returns Dictionary with: level, total_xp, xp_in_level, xp_needed, xp_for_current, xp_for_next
func get_stat_display_data(stat_name: String) -> Dictionary:
	"""Returns all display data needed for UI in a single call.
	
	This method encapsulates all XP/level calculation logic, removing it from the UI layer.
	Uses stored level as the source of truth (not recalculated from XP).
	
	Args:
		stat_name: The stat name (use StatConstants.STAT_*)
		
	Returns:
		Dictionary containing:
			- level: int - Current level
			- total_xp: int - Total XP accumulated
			- xp_in_level: int - XP gained within current level (for progress bar)
			- xp_needed: int - XP needed to complete current level
			- xp_for_current: int - Total XP required for current level
			- xp_for_next: int - Total XP required for next level
	"""
	if not base_stat_xp.has(stat_name):
		_logger.log_error("get_stat_display_data() called with unknown stat: " + stat_name)
		return {
			"level": 1,
			"total_xp": 0,
			"xp_in_level": 0,
			"xp_needed": 1,
			"xp_for_current": 0,
			"xp_for_next": 100
		}
	
	var total_xp: int = base_stat_xp[stat_name]
	var level: int = get_base_stat_level(stat_name)  # Stored level (source of truth)
	var xp_for_current: int = XPFormula.get_xp_for_level(level) if XPFormula != null else 0
	var xp_for_next: int = XPFormula.get_xp_for_level(level + 1) if XPFormula != null else 100
	var xp_in_level: int = max(0, total_xp - xp_for_current)  # Clamp to 0 to prevent negatives
	var xp_needed: int = max(1, xp_for_next - xp_for_current)  # Ensure at least 1 to prevent division by zero
	
	return {
		"level": level,
		"total_xp": total_xp,
		"xp_in_level": xp_in_level,
		"xp_needed": xp_needed,
		"xp_for_current": xp_for_current,
		"xp_for_next": xp_for_next
	}


func _check_base_stat_level_up(stat_name: String) -> void:
	"""Checks if a base stat should level up and handles it."""
	if not base_stat_xp.has(stat_name):
		return
	
	var current_level: int = get_base_stat_level(stat_name)
	var max_level: int = GameBalance.get_max_base_stat_level()
	
	# Check if already at max level
	if current_level >= max_level:
		_logger.log_info(stat_name.capitalize() + " at max level (" + str(max_level) + "), cannot level up")
		return  # Can't level up past max
	
	var current_xp: int = base_stat_xp[stat_name]
	
	# Calculate what level this XP should correspond to (using RuneScape formula)
	var calculated_level: int = XPFormula.get_level_from_xp(current_xp)
	
	# Cap calculated level to max
	if calculated_level > max_level:
		calculated_level = max_level
	
	# Check if we should level up
	if calculated_level > current_level:
		# Level up to the calculated level (could be multiple levels)
		var old_level: int = current_level
		
		# Set stat to calculated level (handling multiple level-ups)
		var level_diff: int = calculated_level - current_level
		for i in range(level_diff):
			_increment_base_stat(stat_name)
		
		var new_level: int = get_base_stat_level(stat_name)
		var xp_for_new_level: int = XPFormula.get_xp_for_level(new_level)
		
		_logger.log_info("🎉 " + stat_name.capitalize() + " LEVELED UP! Level " + str(old_level) + " → " + str(new_level) + " (XP: " + str(current_xp) + ", needed: " + str(xp_for_new_level) + ")")
		
		# Emit signal for UI updates and game events
		base_stat_leveled_up.emit(stat_name, new_level)
		stat_changed.emit(stat_name, new_level)
		
		# Update health/mana/stamina if relevant stat leveled up
		_update_resource_caps(stat_name)
		
		# Update character level
		_update_character_level()


func _increment_base_stat(stat_name: String) -> void:
	"""Increments a base stat by 1 level (uses proper setter)."""
	var current_level: int = get_base_stat_level(stat_name)
	var new_level: int = current_level + 1
	set_base_stat_level(stat_name, new_level)


func _update_resource_caps(stat_name: String) -> void:
	"""Updates health/mana/stamina caps when relevant stat levels up."""
	if PlayerStats == null:
		return
	
	match stat_name:
		StatConstants.STAT_VIT:
			var new_max: int = PlayerStats.get_max_health()
			if PlayerStats.get_health() > new_max:
				PlayerStats.set_health(new_max)
		StatConstants.STAT_INT:
			var new_max: int = PlayerStats.get_max_mana()
			if PlayerStats.get_mana() > new_max:
				PlayerStats.set_mana(new_max)
		StatConstants.STAT_AGILITY:
			var new_max: int = PlayerStats.get_max_stamina()
			if PlayerStats.get_stamina() > new_max:
				PlayerStats.set_stamina(new_max)


## Returns the stored level for a base stat (simple getter, source of truth for display).
func get_base_stat_level(stat_name: String) -> int:
	match stat_name:
		StatConstants.STAT_RESILIENCE, "str":  # Backward compatibility
			return base_resilience
		StatConstants.STAT_AGILITY, "dex":  # Backward compatibility
			return base_agility
		StatConstants.STAT_INT:
			return base_int
		StatConstants.STAT_VIT:
			return base_vit
	return 1


## Sets a base stat to a specific level.
## 
## Args:
##   stat_name: The stat to modify (use StatConstants.STAT_*)
##   level: The new level value
func set_base_stat_level(stat_name: String, level: int) -> void:
	set_base_stat(stat_name, level)


## Sets a base stat value directly.
func set_base_stat(stat_name: String, value: int) -> void:
	var old_value: int = 0
	match stat_name:
		StatConstants.STAT_RESILIENCE, "str":  # Support both for backwards compatibility
			old_value = base_resilience
			base_resilience = value
			_logger.log("Resilience changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_RESILIENCE, value)
		StatConstants.STAT_AGILITY, "dex":  # Support both for backwards compatibility
			old_value = base_agility
			base_agility = value
			_logger.log("Agility changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_AGILITY, value)
		StatConstants.STAT_INT:
			old_value = base_int
			base_int = value
			_logger.log("Intelligence changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_INT, value)
		StatConstants.STAT_VIT:
			old_value = base_vit
			base_vit = value
			_logger.log("Vitality changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_VIT, value)
	
	# Update character level
	_update_character_level()


## Recalculates all base stat levels from their current XP values.
## 
## This is useful when loading game state or syncing from external sources.
## Each stat's level will be recalculated based on its current XP using the XP formula.
func recalculate_stat_levels_from_xp() -> void:
	_check_base_stat_level_up(StatConstants.STAT_RESILIENCE)
	_check_base_stat_level_up(StatConstants.STAT_AGILITY)
	_check_base_stat_level_up(StatConstants.STAT_INT)
	_check_base_stat_level_up(StatConstants.STAT_VIT)


## Returns the player's character level based on all stats (base stats + magic elements).
func get_character_level() -> int:
	if SpellSystem == null:
		return 1  # Default if SpellSystem not available
	
	var fire_level: int = SpellSystem.get_level("fire")
	var water_level: int = SpellSystem.get_level("water")
	var earth_level: int = SpellSystem.get_level("earth")
	var air_level: int = SpellSystem.get_level("air")
	
	# Use PlayerStats.get_total_* methods to get total stats (base + equipment)
	if PlayerStats == null:
		return 1
	
	return CharacterLevel.get_character_level(
		PlayerStats.get_total_resilience(),
		PlayerStats.get_total_agility(),
		PlayerStats.get_total_int(),
		PlayerStats.get_total_vit(),
		fire_level,
		water_level,
		earth_level,
		air_level
	)


## Returns full character level information including total skill levels.
func get_character_level_info() -> Dictionary:
	if SpellSystem == null:
		return {"character_level": 1, "total_skill_levels": 0, "levels_needed_for_next": 8}
	
	var fire_level: int = SpellSystem.get_level("fire")
	var water_level: int = SpellSystem.get_level("water")
	var earth_level: int = SpellSystem.get_level("earth")
	var air_level: int = SpellSystem.get_level("air")
	
	# Use PlayerStats.get_total_* methods to get total stats (base + equipment)
	if PlayerStats == null:
		return {"character_level": 1, "total_skill_levels": 0, "levels_needed_for_next": 8}
	
	return CharacterLevel.calculate_character_level(
		PlayerStats.get_total_resilience(),
		PlayerStats.get_total_agility(),
		PlayerStats.get_total_int(),
		PlayerStats.get_total_vit(),
		fire_level,
		water_level,
		earth_level,
		air_level
	)


func _update_character_level() -> void:
	"""Recalculates and emits character level changed signal."""
	var new_level: int = get_character_level()
	character_level_changed.emit(new_level)


## Called when player deals damage to gain Resilience XP.
func gain_resilience_xp_for_damage_dealt(damage: int) -> void:
	if damage > 0:
		gain_base_stat_xp(StatConstants.STAT_RESILIENCE, max(1, int(damage / 2.0)), StatConstants.STAT_RESILIENCE)

