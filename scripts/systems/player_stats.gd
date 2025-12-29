extends Node
## Global player stats system (autoload singleton).
## Manages base stats (Resilience/Agility/INT/VIT), derived values (health/mana/stamina), gold, and XP/leveling.
##
## System Ownership and Data Flow:
## - PlayerStats stores stat levels (base_resilience, base_agility, base_int, base_vit) AND XP
## - PlayerStats is the single source of truth for both levels and XP
## - XP is gained → level calculation → set_base_stat_level() → signals → UI (display)
##
## Data Flow: XP Storage → Level Calculation → set_base_stat_level() → Signals → UI (display)

# Logging
var _logger = GameLogger.create("[PlayerStats] ")

# Signals (LOCKED NAMES per SPEC.md)
signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal stamina_changed(current: int, maximum: int)
signal gold_changed(amount: int)
signal stat_changed(stat_name: String, new_value: int)
signal character_level_changed(new_level: int)
signal player_died
signal base_stat_xp_gained(stat_name: String, amount: int, total: int)
signal base_stat_leveled_up(stat_name: String, new_level: int)

# Base Stats (RENAMED: STR→Resilience, DEX→Agility)
# These values represent both the stat value AND the level
var base_resilience: int = 1  # Formerly base_str
var base_agility: int = 1  # Formerly base_dex
var base_int: int = 1
var base_vit: int = 1

# Base stat XP tracking
var base_stat_xp: Dictionary = {
	StatConstants.STAT_RESILIENCE: 0,
	StatConstants.STAT_AGILITY: 0,
	StatConstants.STAT_INT: 0,
	StatConstants.STAT_VIT: 0
}

# Vitality XP accumulator (tracks partial XP from other stats)
var _vitality_xp_accumulator: float = 0.0



# Current Values (LOCKED NAMES per SPEC.md)
var health: int = 100
var mana: int = 75
var stamina: int = 50
var gold: int = 0

# Constants (now loaded from GameBalance config)
# These are kept as fallback defaults but should use GameBalance getters
const HEALTH_PER_VIT: int = 20  # Use GameBalance.get_health_per_vit() instead
const MANA_PER_INT: int = 15  # Use GameBalance.get_mana_per_int() instead
const STAMINA_PER_AGILITY: int = 10  # Use GameBalance.get_stamina_per_agility() instead




func _ready() -> void:
	_logger.log_info("PlayerStats initialized")
	# Initialize health/mana/stamina to max values
	health = get_max_health()
	mana = get_max_mana()
	stamina = get_max_stamina()
	_logger.log_info("Initialized: Health=" + str(health) + ", Mana=" + str(mana) + ", Stamina=" + str(stamina))
	
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


# Fractional accumulation for smooth regeneration
var _mana_regen_accumulator: float = 0.0
var _stamina_regen_accumulator: float = 0.0
var _health_regen_accumulator: float = 0.0

func _process(delta: float) -> void:
	# Get base regen rates from GameBalance config
	var base_mana_regen: float = GameBalance.get_base_mana_regen()
	var base_stamina_regen: float = GameBalance.get_base_stamina_regen()
	var base_health_regen: float = GameBalance.get_base_health_regen()
	
	# Regenerate mana (scaled by INT)
	var mana_regen_rate: float = base_mana_regen * (1.0 + get_total_int() * 0.1)  # +10% per INT point
	if mana < get_max_mana():
		_mana_regen_accumulator += mana_regen_rate * delta
		if _mana_regen_accumulator >= 1.0:
			var regen_amount: int = int(_mana_regen_accumulator)
			_mana_regen_accumulator -= float(regen_amount)
			restore_mana(regen_amount)
	
	# Regenerate stamina (scaled by Agility)
	var agility: int = get_total_agility()
	var stamina_regen_rate: float = base_stamina_regen * (1.0 + agility * 0.15)  # +15% per agility point
	if stamina < get_max_stamina():
		_stamina_regen_accumulator += stamina_regen_rate * delta
		if _stamina_regen_accumulator >= 1.0:
			var regen_amount: int = int(_stamina_regen_accumulator)
			_stamina_regen_accumulator -= float(regen_amount)
			restore_stamina(regen_amount)

	# Regenerate health (scaled by VIT)
	var vit: int = get_total_vit()
	var health_regen_rate: float = base_health_regen * (1.0 + vit * 0.1)  # +10% per VIT point
	if health < get_max_health() and health > 0:  # Don't regen if dead
		_health_regen_accumulator += health_regen_rate * delta
		if _health_regen_accumulator >= 1.0:
			var regen_amount: int = int(_health_regen_accumulator)
			_health_regen_accumulator -= float(regen_amount)
			heal(regen_amount)


# Derived Stats (UPDATED: Resilience/Agility)
func get_total_resilience() -> int:
	# Formerly get_total_str()
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_RESILIENCE)
	return base_resilience + bonus


func get_total_agility() -> int:
	# Formerly get_total_dex()
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_AGILITY)
	return base_agility + bonus


func get_total_int() -> int:
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_INT)
	return base_int + bonus


func get_total_vit() -> int:
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_VIT)
	return base_vit + bonus


func get_max_health() -> int:
	var health_per_vit: int = GameBalance.get_health_per_vit()
	return get_total_vit() * health_per_vit


func get_max_mana() -> int:
	var mana_per_int: int = GameBalance.get_mana_per_int()
	return get_total_int() * mana_per_int


func get_max_stamina() -> int:
	var stamina_per_agility: int = GameBalance.get_stamina_per_agility()
	return get_total_agility() * stamina_per_agility


# Defense calculation with diminishing returns
func calculate_damage_reduction(incoming_damage: int) -> int:
	"""Calculates damage reduction based on resilience with diminishing returns."""
	var resilience: int = get_total_resilience()
	return StatFormulas.calculate_damage_reduction(incoming_damage, resilience)


# Carry weight system
func get_max_carry_weight() -> float:
	"""Returns maximum carry weight in kg based on resilience."""
	var resilience: int = get_total_resilience()
	return StatFormulas.calculate_max_carry_weight(resilience)


func get_current_carry_weight() -> float:
	"""Calculates current total weight of all items in inventory."""
	if InventorySystem == null:
		return 0.0
	
	var total_weight: float = 0.0
	for i in range(InventorySystem.capacity):
		var slot: Dictionary = InventorySystem.get_slot(i)
		var item: ItemData = slot.get("item")
		var count: int = slot.get("count", 0)
		if item != null and count > 0:
			total_weight += item.weight * count
	
	# Also count equipped items
	for slot_name in InventorySystem.equipment:
		var item: EquipmentData = InventorySystem.equipment[slot_name]
		if item != null:
			total_weight += item.weight
	
	return total_weight


func can_carry_item(item: ItemData, count: int = 1) -> bool:
	"""Checks if player can carry additional items."""
	var current_weight: float = get_current_carry_weight()
	var additional_weight: float = item.weight * count
	return (current_weight + additional_weight) <= get_max_carry_weight()


# Agility-based stamina consumption
func get_stamina_consumption_multiplier() -> float:
	"""Returns stamina consumption multiplier based on agility (lower = less stamina used)."""
	var agility: int = get_total_agility()
	return StatFormulas.calculate_stamina_consumption_multiplier(agility)


# Agility-based movement speed multiplier
func get_movement_speed_multiplier() -> float:
	"""Returns movement speed multiplier based on agility."""
	var agility: int = get_total_agility()
	return StatFormulas.calculate_movement_speed_multiplier(agility)


# Health Methods (LOCKED SIGNATURES per SPEC.md)
func set_health(value: int) -> void:
	var old_health: int = health
	health = clampi(value, 0, get_max_health())
	if health != old_health:
		_logger.log("Health changed: " + str(old_health) + " → " + str(health) + "/" + str(get_max_health()))
		health_changed.emit(health, get_max_health())
		if health <= 0:
			_logger.log("Player died!")
			player_died.emit()


func heal(amount: int) -> void:
	set_health(health + amount)


func take_damage(amount: int) -> void:
	# Apply resilience-based damage reduction
	var reduced_damage: int = calculate_damage_reduction(amount)
	_logger.log("Taking damage: " + str(amount) + " → " + str(reduced_damage) + " (reduced by resilience)")
	set_health(health - reduced_damage)
	# Gain Resilience XP for taking damage
	if reduced_damage > 0:
		gain_base_stat_xp(StatConstants.STAT_RESILIENCE, max(1, int(reduced_damage / 2.0)), StatConstants.STAT_RESILIENCE)


# Mana Methods (LOCKED SIGNATURES per SPEC.md)
func set_mana(value: int) -> void:
	var old_mana: int = mana
	mana = clampi(value, 0, get_max_mana())
	if mana != old_mana:
		_logger.log("Mana changed: " + str(old_mana) + " → " + str(mana) + "/" + str(get_max_mana()))
		mana_changed.emit(mana, get_max_mana())


func consume_mana(amount: int) -> bool:
	if not has_mana(amount):
		_logger.log("Failed to consume " + str(amount) + " mana (insufficient)")
		return false
	_logger.log("Consuming " + str(amount) + " mana")
	set_mana(mana - amount)
	# Gain Intelligence XP for casting spells (whether they hit or not)
	if amount > 0:
		gain_base_stat_xp(StatConstants.STAT_INT, max(1, int(amount / 2.5)), StatConstants.STAT_INT)
	return true


func has_mana(amount: int) -> bool:
	return mana >= amount


func restore_mana(amount: int) -> void:
	set_mana(mana + amount)


# Stamina Methods (LOCKED SIGNATURES per SPEC.md)
func set_stamina(value: int) -> void:
	var old_stamina: int = stamina
	stamina = clampi(value, 0, get_max_stamina())
	if stamina != old_stamina:
		_logger.log("Stamina changed: " + str(old_stamina) + " → " + str(stamina) + "/" + str(get_max_stamina()))
		stamina_changed.emit(stamina, get_max_stamina())


func consume_stamina(amount: int) -> bool:
	if amount <= 0:
		return true  # Nothing to consume
	
	# Apply agility-based consumption reduction
	var multiplier: float = get_stamina_consumption_multiplier()
	var adjusted_amount: float = float(amount) * multiplier
	# Round to nearest int to avoid truncating to 0, but ensure at least 1 if original amount > 0
	var final_amount: int = max(1, int(round(adjusted_amount)))
	
	if not has_stamina(final_amount):
		_logger.log("Failed to consume " + str(final_amount) + " stamina (insufficient)")
		return false
	_logger.log("Consuming " + str(final_amount) + " stamina (multiplier: " + str(multiplier) + ", original: " + str(amount) + ")")
	set_stamina(stamina - final_amount)
	# Gain Agility XP for using stamina
	if final_amount > 0:
		gain_base_stat_xp(StatConstants.STAT_AGILITY, max(1, int(final_amount / 3.5)), StatConstants.STAT_AGILITY)
	return true


func has_stamina(amount: int) -> bool:
	return stamina >= amount


func restore_stamina(amount: int) -> void:
	set_stamina(stamina + amount)


# Gold Methods (LOCKED SIGNATURES per SPEC.md)
func add_gold(amount: int) -> void:
	gold += amount
	_logger.log("Gold added: +" + str(amount) + " (total: " + str(gold) + ")")
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if not has_gold(amount):
		_logger.log("Failed to spend " + str(amount) + " gold (insufficient)")
		return false
	gold -= amount
	_logger.log("Gold spent: -" + str(amount) + " (total: " + str(gold) + ")")
	gold_changed.emit(gold)
	return true


func has_gold(amount: int) -> bool:
	return gold >= amount


# Base Stat XP and Leveling Methods

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
	var current_level: int = get_base_stat_level(stat_name)
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
	var current_level: int = get_base_stat_level(stat_name)
	return XPFormula.get_xp_for_next_level(current_level) if XPFormula != null else 100


## Returns display data for a base stat (single source of truth for UI)
## Uses stored level from PlayerStats, not calculated from XP
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


func _increment_base_stat(stat_name: String) -> void:
	"""Increments a base stat by 1 level (uses proper setter)."""
	var current_level: int = get_base_stat_level(stat_name)
	var new_level: int = current_level + 1
	set_base_stat_level(stat_name, new_level)


func _update_resource_caps(stat_name: String) -> void:
	"""Updates health/mana/stamina caps when relevant stat levels up."""
	match stat_name:
		StatConstants.STAT_VIT:
			var new_max: int = get_max_health()
			if health > new_max:
				set_health(new_max)
		StatConstants.STAT_INT:
			var new_max: int = get_max_mana()
			if mana > new_max:
				set_mana(new_max)
		StatConstants.STAT_AGILITY:
			var new_max: int = get_max_stamina()
			if stamina > new_max:
				set_stamina(new_max)


func get_base_stat_level(stat_name: String) -> int:
	"""Returns the stored level for a base stat (simple getter, source of truth for display)."""
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


func get_carry_weight_slow_multiplier() -> float:
	"""Returns movement speed multiplier when carrying heavy load (85%+ weight)."""
	var current_weight: float = get_current_carry_weight()
	var max_weight: float = get_max_carry_weight()
	return StatFormulas.calculate_carry_weight_slow_multiplier(current_weight, max_weight)


# Character Level Methods (combines all base stats + magic elements)
func get_character_level() -> int:
	"""Returns the player's character level based on all stats (base stats + magic elements)."""
	if SpellSystem == null:
		return 1  # Default if SpellSystem not available
	
	var fire_level: int = SpellSystem.get_level("fire")
	var water_level: int = SpellSystem.get_level("water")
	var earth_level: int = SpellSystem.get_level("earth")
	var air_level: int = SpellSystem.get_level("air")
	
	return CharacterLevel.get_character_level(
		get_total_resilience(),
		get_total_agility(),
		get_total_int(),
		get_total_vit(),
		fire_level,
		water_level,
		earth_level,
		air_level
	)


func get_character_level_info() -> Dictionary:
	"""Returns full character level information including total skill levels."""
	if SpellSystem == null:
		return {"character_level": 1, "total_skill_levels": 0, "levels_needed_for_next": 8}
	
	var fire_level: int = SpellSystem.get_level("fire")
	var water_level: int = SpellSystem.get_level("water")
	var earth_level: int = SpellSystem.get_level("earth")
	var air_level: int = SpellSystem.get_level("air")
	
	return CharacterLevel.calculate_character_level(
		get_total_resilience(),
		get_total_agility(),
		get_total_int(),
		get_total_vit(),
		fire_level,
		water_level,
		earth_level,
		air_level
	)


func _update_character_level() -> void:
	"""Recalculates and emits character level changed signal."""
	var new_level: int = get_character_level()
	character_level_changed.emit(new_level)


# Method to gain Resilience XP when dealing damage (called from combat system)
func gain_resilience_xp_for_damage_dealt(damage: int) -> void:
	"""Called when player deals damage to gain Resilience XP."""
	if damage > 0:
		gain_base_stat_xp(StatConstants.STAT_RESILIENCE, max(1, int(damage / 2.0)), StatConstants.STAT_RESILIENCE)


# Stat Modification Methods (UPDATED: Resilience/Agility)
func set_base_stat(stat_name: String, value: int) -> void:
	var old_value: int = 0
	match stat_name:
		StatConstants.STAT_RESILIENCE, "str":  # Support both for backwards compatibility
			old_value = base_resilience
			base_resilience = value
			_logger.log("Resilience changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_RESILIENCE, value)
			_update_character_level()
		StatConstants.STAT_AGILITY, "dex":  # Support both for backwards compatibility
			old_value = base_agility
			base_agility = value
			_logger.log("Agility changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_AGILITY, value)
			_update_character_level()
		StatConstants.STAT_INT:
			old_value = base_int
			base_int = value
			_logger.log("Intelligence changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_INT, value)
			_update_character_level()
		StatConstants.STAT_VIT:
			old_value = base_vit
			base_vit = value
			_logger.log("Vitality changed: " + str(old_value) + " → " + str(value))
			stat_changed.emit(StatConstants.STAT_VIT, value)
			# Update health if VIT changed
			var new_max: int = get_max_health()
			if health > new_max:
				set_health(new_max)
			_update_character_level()


func set_base_stat_level(stat_name: String, level: int) -> void:
	"""Sets a base stat to a specific level.
	
	This method provides proper encapsulation for leveling systems to update player stats.
	Validates input and emits appropriate signals.
	
	Args:
		stat_name: The stat to modify (use StatConstants.STAT_*)
		level: The new level value
	"""
	set_base_stat(stat_name, level)


func recalculate_stat_levels_from_xp() -> void:
	"""Recalculates all base stat levels from their current XP values.
	
	This is useful when loading game state or syncing from external sources.
	Each stat's level will be recalculated based on its current XP using the XP formula.
	"""
	_check_base_stat_level_up(StatConstants.STAT_RESILIENCE)
	_check_base_stat_level_up(StatConstants.STAT_AGILITY)
	_check_base_stat_level_up(StatConstants.STAT_INT)
	_check_base_stat_level_up(StatConstants.STAT_VIT)
