extends Node
## Global base stat XP and leveling system (autoload singleton).
## Manages XP tracking, level-ups, and progression for all base stats.
## Separate from PlayerStats for modularity and maintainability.
##
## System Ownership and Data Flow:
## - BaseStatLeveling owns XP storage and level calculation logic
## - BaseStatLeveling directly modifies PlayerStats stored levels (clear ownership, simpler than signals)
## - PlayerStats stored levels are the single source of truth for display
## - UI layer retrieves display data via get_stat_display_data() (no calculations in UI)
##
## Data Flow: XP Storage → Level Calculation → PlayerStats (stored) → UI (display)
## Signals are used for notifications to UI, not for data updates

# Logging
var _logger = GameLogger.create("[BaseStatLeveling] ")

# Signals
signal base_stat_xp_gained(stat_name: String, amount: int, total: int)
signal base_stat_leveled_up(stat_name: String, new_level: int)

# Base stat XP tracking
var base_stat_xp: Dictionary = {
	StatConstants.STAT_RESILIENCE: 0,
	StatConstants.STAT_AGILITY: 0,
	StatConstants.STAT_INT: 0,
	StatConstants.STAT_VIT: 0
}

# Vitality XP accumulator (tracks partial XP from other stats)
var _vitality_xp_accumulator: float = 0.0

# Heavy carry weight distance tracking (distance-based XP)
var _last_player_position: Vector2 = Vector2.ZERO
var _heavy_carry_distance_accumulator: float = 0.0

# Constants
# XP System: Using RuneScape-style exponential XP curve (see XPFormula)
const MAX_BASE_STAT_LEVEL: int = 110  # Maximum level for base stats
const VITALITY_XP_RATIO: int = 8  # 1 VIT XP per 8 XP in other stats (slower progression)
const HEAVY_CARRY_THRESHOLD: float = 0.90  # 90% weight for XP gain
const HEAVY_CARRY_XP_PER_METER: float = 0.1  # XP per meter moved (distance-based, lower than other methods)


func _ready() -> void:
	_logger.log("BaseStatLeveling initialized")
	_logger.log("  Base stat XP tracking: " + str(base_stat_xp.keys()))
	_logger.log("  Max level: " + str(MAX_BASE_STAT_LEVEL))
	_logger.log("  XP System: RuneScape-style exponential curve")


func _process(_delta: float) -> void:
	# Heavy carry weight distance-based XP tracking (Resilience)
	_update_heavy_carry_xp(_delta)


## Extracts heavy carry tracking logic for better organization and testability
## NOTE: This could be refactored to an event-driven system (Observer pattern) in the future
## if heavy carry tracking needs to be separated into its own system
func _update_heavy_carry_xp(_delta: float) -> void:
	"""Updates Resilience XP based on distance traveled while carrying heavy load.
	
	This method handles distance-based XP gain when the player is carrying >= 90% of max weight.
	The logic is kept here for now but could be extracted to a separate system if needed.
	"""
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or PlayerStats == null:
		return
	
	var current_position: Vector2 = player_node.global_position
	var current_weight: float = PlayerStats.get_current_carry_weight()
	var max_weight: float = PlayerStats.get_max_carry_weight()
	
	if max_weight <= 0:
		_heavy_carry_distance_accumulator = 0.0
		_last_player_position = current_position
		return
	
	var weight_percentage: float = current_weight / max_weight
	if weight_percentage >= HEAVY_CARRY_THRESHOLD:
		# Track distance moved while carrying heavy load
		if _last_player_position != Vector2.ZERO:
			var distance_moved: float = current_position.distance_to(_last_player_position)
			# Accumulate distance and convert to XP (distance-based, lower rate)
			_heavy_carry_distance_accumulator += distance_moved * HEAVY_CARRY_XP_PER_METER
			if _heavy_carry_distance_accumulator >= 1.0:
				var xp_amount: int = int(_heavy_carry_distance_accumulator)
				_heavy_carry_distance_accumulator -= float(xp_amount)
				if xp_amount > 0:
					_logger.log("Heavy carry XP: " + str(xp_amount) + " (distance: " + str(snappedf(distance_moved, 0.1)) + "m, weight: " + str(snappedf(weight_percentage * 100, 0.1)) + "%)")
					gain_base_stat_xp(StatConstants.STAT_RESILIENCE, xp_amount, StatConstants.STAT_RESILIENCE)
		# Always update position (even if first frame, for next frame's calculation)
		_last_player_position = current_position
	else:
		# Reset accumulator when not carrying heavy load, but keep tracking position
		_heavy_carry_distance_accumulator = 0.0
		_last_player_position = current_position


# Public API: Gain XP for a base stat
func gain_base_stat_xp(stat_name: String, amount: int, source_stat: String = "") -> void:
	"""Gains XP for a base stat and checks for level-up. Also triggers Vitality auto-gain.
	
	Args:
		stat_name: The stat to gain XP for (use StatConstants.STAT_*)
		amount: Amount of XP to gain (must be > 0)
		source_stat: The stat that triggered this XP gain (for cooldown tracking, defaults to stat_name)
	"""
	if not base_stat_xp.has(stat_name):
		_logger.log_error("gain_base_stat_xp() called with unknown stat: " + stat_name)
		return
	
	if amount <= 0:
		return  # Silently skip invalid amounts
	
	# Determine source stat for cooldown checking (VIT uses source stat's cooldown)
	var cooldown_stat: String = source_stat if source_stat != "" else stat_name
	
	# Check cooldown before granting XP
	if not XPCooldown.can_gain_xp(cooldown_stat):
		_logger.log("XP gain blocked by cooldown for " + cooldown_stat)
		return  # Silently skip if on cooldown
	
	# Record XP gain (uses source stat's cooldown for VIT)
	XPCooldown.record_xp_gain(cooldown_stat)
	
	var old_xp: int = base_stat_xp[stat_name]
	base_stat_xp[stat_name] += amount
	var total_xp: int = base_stat_xp[stat_name]
	
	_logger.log("✨ " + stat_name.capitalize() + " gained " + str(amount) + " XP (" + str(old_xp) + " → " + str(total_xp) + ")")
	
	# Emit signal for UI updates
	base_stat_xp_gained.emit(stat_name, amount, total_xp)
	
	# Check for level-up
	_check_base_stat_level_up(stat_name)
	
	# Vitality auto-gain: 1 VIT XP per 8 XP in other stats (respects source stat's cooldown)
	if stat_name != StatConstants.STAT_VIT:
		_vitality_xp_accumulator += float(amount) / float(VITALITY_XP_RATIO)
		if _vitality_xp_accumulator >= 1.0:
			var vit_xp: int = int(_vitality_xp_accumulator)
			_vitality_xp_accumulator -= float(vit_xp)
			# Pass source stat so VIT respects the source stat's cooldown
			gain_base_stat_xp(StatConstants.STAT_VIT, vit_xp, stat_name)


func _check_base_stat_level_up(stat_name: String) -> void:
	"""Checks if a base stat should level up and handles it."""
	if not base_stat_xp.has(stat_name):
		return
	
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot level up stat: " + stat_name)
		return
	
	var current_level: int = _get_base_stat_level(stat_name)
	
	# Check if already at max level
	if current_level >= MAX_BASE_STAT_LEVEL:
		_logger.log(stat_name.capitalize() + " at max level (" + str(MAX_BASE_STAT_LEVEL) + "), cannot level up")
		return  # Can't level up past max
	
	var current_xp: int = base_stat_xp[stat_name]
	
	# Calculate what level this XP should correspond to (using RuneScape formula)
	var calculated_level: int = XPFormula.get_level_from_xp(current_xp)
	
	# Cap calculated level to max
	if calculated_level > MAX_BASE_STAT_LEVEL:
		calculated_level = MAX_BASE_STAT_LEVEL
	
	# Check if we should level up
	if calculated_level > current_level:
		# Level up to the calculated level (could be multiple levels)
		var old_level: int = current_level
		
		# Set stat to calculated level (handling multiple level-ups)
		var level_diff: int = calculated_level - current_level
		for i in range(level_diff):
			_increment_base_stat(stat_name)
		
		var new_level: int = _get_base_stat_level(stat_name)
		var xp_for_new_level: int = XPFormula.get_xp_for_level(new_level)
		
		_logger.log("🎉 " + stat_name.capitalize() + " LEVELED UP! Level " + str(old_level) + " → " + str(new_level) + " (XP: " + str(current_xp) + ", needed: " + str(xp_for_new_level) + ")")
		
		# Emit signal for UI updates and game events
		base_stat_leveled_up.emit(stat_name, new_level)
		PlayerStats.stat_changed.emit(stat_name, new_level)
		
		# Update health/mana/stamina if relevant stat leveled up
		_update_resource_caps(stat_name)


func _get_base_stat_level(stat_name: String) -> int:
	"""Returns the current level for a base stat (reads from PlayerStats)."""
	if PlayerStats == null:
		return 1
	
	match stat_name:
		StatConstants.STAT_RESILIENCE, "str":  # Backward compatibility
			return PlayerStats.base_resilience
		StatConstants.STAT_AGILITY, "dex":  # Backward compatibility
			return PlayerStats.base_agility
		StatConstants.STAT_INT:
			return PlayerStats.base_int
		StatConstants.STAT_VIT:
			return PlayerStats.base_vit
	return 1


func _increment_base_stat(stat_name: String) -> void:
	"""Increments a base stat by 1 level (updates PlayerStats)."""
	if PlayerStats == null:
		return
	
	match stat_name:
		StatConstants.STAT_RESILIENCE, "str":  # Backward compatibility
			PlayerStats.base_resilience += 1
		StatConstants.STAT_AGILITY, "dex":  # Backward compatibility
			PlayerStats.base_agility += 1
		StatConstants.STAT_INT:
			PlayerStats.base_int += 1
		StatConstants.STAT_VIT:
			PlayerStats.base_vit += 1


func _set_base_stat_to_max(stat_name: String) -> void:
	"""Sets a base stat to max level (safety check)."""
	if PlayerStats == null:
		return
	
	match stat_name:
		StatConstants.STAT_RESILIENCE, "str":  # Backward compatibility
			PlayerStats.base_resilience = MAX_BASE_STAT_LEVEL
		StatConstants.STAT_AGILITY, "dex":  # Backward compatibility
			PlayerStats.base_agility = MAX_BASE_STAT_LEVEL
		StatConstants.STAT_INT:
			PlayerStats.base_int = MAX_BASE_STAT_LEVEL
		StatConstants.STAT_VIT:
			PlayerStats.base_vit = MAX_BASE_STAT_LEVEL


func _update_resource_caps(stat_name: String) -> void:
	"""Updates health/mana/stamina caps when relevant stat levels up."""
	if PlayerStats == null:
		return
	
	match stat_name:
		StatConstants.STAT_VIT:
			var new_max: int = PlayerStats.get_max_health()
			if PlayerStats.health > new_max:
				PlayerStats.set_health(new_max)
		StatConstants.STAT_INT:
			var new_max: int = PlayerStats.get_max_mana()
			if PlayerStats.mana > new_max:
				PlayerStats.set_mana(new_max)
		StatConstants.STAT_AGILITY:
			var new_max: int = PlayerStats.get_max_stamina()
			if PlayerStats.stamina > new_max:
				PlayerStats.set_stamina(new_max)


# Public API: Get XP information
func get_base_stat_xp(stat_name: String) -> int:
	"""Returns current XP for a base stat.
	
	Args:
		stat_name: The stat name (use StatConstants.STAT_*)
		
	Returns:
		Current total XP for the stat, or 0 if stat doesn't exist
	"""
	if not base_stat_xp.has(stat_name):
		_logger.log_error("get_base_stat_xp() called with unknown stat: " + stat_name)
		return 0
	return base_stat_xp[stat_name]


func get_base_stat_xp_for_current_level(stat_name: String) -> int:
	"""Returns the minimum total XP needed for the current level (using RuneScape XP formula).
	
	Args:
		stat_name: The stat name (use StatConstants.STAT_*)
		
	Returns:
		Total XP required for current level, or 0 if stat doesn't exist
	"""
	if not base_stat_xp.has(stat_name):
		_logger.log_error("get_base_stat_xp_for_current_level() called with unknown stat: " + stat_name)
		return 0
	var current_level: int = _get_base_stat_level(stat_name)
	return XPFormula.get_xp_for_current_level(current_level) if XPFormula != null else 0


func get_base_stat_xp_for_next_level(stat_name: String) -> int:
	"""Returns the total XP needed to reach the next level for a base stat (using RuneScape XP formula).
	
	Args:
		stat_name: The stat name (use StatConstants.STAT_*)
		
	Returns:
		Total XP required for next level, or 100 if stat doesn't exist (fallback)
	"""
	if not base_stat_xp.has(stat_name):
		_logger.log_error("get_base_stat_xp_for_next_level() called with unknown stat: " + stat_name)
		return 100  # Fallback default
	var current_level: int = _get_base_stat_level(stat_name)
	return XPFormula.get_xp_for_next_level(current_level) if XPFormula != null else 100


## Returns display data for a base stat (single source of truth for UI)
## Uses stored level from PlayerStats, not calculated from XP
## Returns Dictionary with: level, total_xp, xp_in_level, xp_needed, xp_for_current, xp_for_next
func get_stat_display_data(stat_name: String) -> Dictionary:
	"""Returns all display data needed for UI in a single call.
	
	This method encapsulates all XP/level calculation logic, removing it from the UI layer.
	Uses stored level from PlayerStats as the source of truth (not recalculated from XP).
	
	Args:
		stat_name: The stat name (use StatConstants.STAT_*)
		
	Returns:
		Dictionary containing:
			- level: int - Current level (from PlayerStats)
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
	var level: int = _get_base_stat_level(stat_name)  # Stored level (source of truth)
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
