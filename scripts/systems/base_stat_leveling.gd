extends Node
## Global base stat XP and leveling system (autoload singleton).
## Manages XP tracking, level-ups, and progression for all base stats.
## Separate from PlayerStats for modularity and maintainability.

# Logging
var _logger = GameLogger.create("[BaseStatLeveling] ")

# Signals
signal base_stat_xp_gained(stat_name: String, amount: int, total: int)
signal base_stat_leveled_up(stat_name: String, new_level: int)

# Base stat XP tracking
var base_stat_xp: Dictionary = {
	"resilience": 0,
	"agility": 0,
	"int": 0,
	"vit": 0
}

# Vitality XP accumulator (tracks partial XP from other stats)
var _vitality_xp_accumulator: float = 0.0

# Heavy carry weight distance tracking (distance-based XP)
var _last_player_position: Vector2 = Vector2.ZERO
var _heavy_carry_distance_accumulator: float = 0.0

# Constants
const BASE_STAT_XP_PER_LEVEL: int = 100  # XP needed = level * 100 (same as element levels)
const MAX_BASE_STAT_LEVEL: int = 64  # Maximum level for base stats
const VITALITY_XP_RATIO: int = 8  # 1 VIT XP per 8 XP in other stats (slower progression)
const HEAVY_CARRY_THRESHOLD: float = 0.90  # 90% weight for XP gain
const HEAVY_CARRY_XP_PER_METER: float = 0.1  # XP per meter moved (distance-based, lower than other methods)


func _ready() -> void:
	_logger.log("BaseStatLeveling initialized")
	_logger.log("  Base stat XP tracking: " + str(base_stat_xp.keys()))
	_logger.log("  Max level: " + str(MAX_BASE_STAT_LEVEL))
	_logger.log("  XP per level: " + str(BASE_STAT_XP_PER_LEVEL))


func _process(_delta: float) -> void:
	# Heavy carry weight distance-based XP (Resilience)
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and PlayerStats != null:
		var current_position: Vector2 = player_node.global_position
		var current_weight: float = PlayerStats.get_current_carry_weight()
		var max_weight: float = PlayerStats.get_max_carry_weight()
		
		if max_weight > 0:
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
							gain_base_stat_xp("resilience", xp_amount, "resilience")
				# Always update position (even if first frame, for next frame's calculation)
				_last_player_position = current_position
			else:
				# Reset accumulator when not carrying heavy load, but keep tracking position
				_heavy_carry_distance_accumulator = 0.0
				_last_player_position = current_position
		else:
			_heavy_carry_distance_accumulator = 0.0
			_last_player_position = current_position


# Public API: Gain XP for a base stat
func gain_base_stat_xp(stat_name: String, amount: int, source_stat: String = "") -> void:
	"""Gains XP for a base stat and checks for level-up. Also triggers Vitality auto-gain.
	
	Args:
		stat_name: The stat to gain XP for
		amount: Amount of XP to gain
		source_stat: The stat that triggered this XP gain (for cooldown tracking, defaults to stat_name)
	"""
	if not base_stat_xp.has(stat_name):
		_logger.log_error("gain_base_stat_xp() called with unknown stat: " + stat_name)
		return
	
	if amount <= 0:
		return
	
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
	if stat_name != "vit":
		_vitality_xp_accumulator += float(amount) / float(VITALITY_XP_RATIO)
		if _vitality_xp_accumulator >= 1.0:
			var vit_xp: int = int(_vitality_xp_accumulator)
			_vitality_xp_accumulator -= float(vit_xp)
			# Pass source stat so VIT respects the source stat's cooldown
			gain_base_stat_xp("vit", vit_xp, stat_name)


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
	
	var xp_needed: int = current_level * BASE_STAT_XP_PER_LEVEL
	var current_xp: int = base_stat_xp[stat_name]
	
	if current_xp >= xp_needed:
		# Level up by incrementing stat in PlayerStats
		_increment_base_stat(stat_name)
		var new_level: int = _get_base_stat_level(stat_name)
		
		# Cap at max level (shouldn't happen, but safety check)
		if new_level > MAX_BASE_STAT_LEVEL:
			_set_base_stat_to_max(stat_name)
			new_level = MAX_BASE_STAT_LEVEL
		
		_logger.log("🎉 " + stat_name.capitalize() + " LEVELED UP! Level " + str(current_level) + " → " + str(new_level) + " (XP: " + str(current_xp) + "/" + str(xp_needed) + ")")
		
		# Emit signal for UI updates and game events
		base_stat_leveled_up.emit(stat_name, new_level)
		PlayerStats.stat_changed.emit(stat_name, new_level)
		
		# Update health/mana/stamina if relevant stat leveled up
		_update_resource_caps(stat_name)
		
		# Recursively check for multiple level-ups
		_check_base_stat_level_up(stat_name)


func _get_base_stat_level(stat_name: String) -> int:
	"""Returns the current level for a base stat (reads from PlayerStats)."""
	if PlayerStats == null:
		return 1
	
	match stat_name:
		"resilience", "str":
			return PlayerStats.base_resilience
		"agility", "dex":
			return PlayerStats.base_agility
		"int":
			return PlayerStats.base_int
		"vit":
			return PlayerStats.base_vit
	return 1


func _increment_base_stat(stat_name: String) -> void:
	"""Increments a base stat by 1 level (updates PlayerStats)."""
	if PlayerStats == null:
		return
	
	match stat_name:
		"resilience", "str":
			PlayerStats.base_resilience += 1
		"agility", "dex":
			PlayerStats.base_agility += 1
		"int":
			PlayerStats.base_int += 1
		"vit":
			PlayerStats.base_vit += 1


func _set_base_stat_to_max(stat_name: String) -> void:
	"""Sets a base stat to max level (safety check)."""
	if PlayerStats == null:
		return
	
	match stat_name:
		"resilience", "str":
			PlayerStats.base_resilience = MAX_BASE_STAT_LEVEL
		"agility", "dex":
			PlayerStats.base_agility = MAX_BASE_STAT_LEVEL
		"int":
			PlayerStats.base_int = MAX_BASE_STAT_LEVEL
		"vit":
			PlayerStats.base_vit = MAX_BASE_STAT_LEVEL


func _update_resource_caps(stat_name: String) -> void:
	"""Updates health/mana/stamina caps when relevant stat levels up."""
	if PlayerStats == null:
		return
	
	match stat_name:
		"vit":
			var new_max: int = PlayerStats.get_max_health()
			if PlayerStats.health > new_max:
				PlayerStats.set_health(new_max)
		"int":
			var new_max: int = PlayerStats.get_max_mana()
			if PlayerStats.mana > new_max:
				PlayerStats.set_mana(new_max)
		"agility":
			var new_max: int = PlayerStats.get_max_stamina()
			if PlayerStats.stamina > new_max:
				PlayerStats.set_stamina(new_max)


# Public API: Get XP information
func get_base_stat_xp(stat_name: String) -> int:
	"""Returns current XP for a base stat."""
	if not base_stat_xp.has(stat_name):
		return 0
	return base_stat_xp[stat_name]


func get_base_stat_xp_for_next_level(stat_name: String) -> int:
	"""Returns XP needed to reach next level for a base stat."""
	var current_level: int = _get_base_stat_level(stat_name)
	return current_level * BASE_STAT_XP_PER_LEVEL
