extends Node
## Global player stats system (autoload singleton) - FACADE.
## Delegates to focused subsystems while maintaining backwards-compatible API.
## Manages base stats (Resilience/Agility/INT/VIT), derived values (health/mana/stamina), gold, and XP/leveling.
##
## Delegates to:
## - XPLevelingSystem: Base stat XP and leveling
## - CurrencySystem: Gold management
## - ResourceRegenSystem: Health/mana/stamina regeneration
## - BuffSystem: Stat buffs and speed buffs
## - CarryWeightSystem: Weight calculations

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
# These are synced from XPLevelingSystem but kept here for backwards compatibility
var base_resilience: int = 1  # Formerly base_str
var base_agility: int = 1  # Formerly base_dex
var base_int: int = 1
var base_vit: int = 1

# Current Values (LOCKED NAMES per SPEC.md)
var health: int = 100
var mana: int = 75
var stamina: int = 50
var gold: int = 0  # Synced from CurrencySystem


func _ready() -> void:
	_logger.log_info("PlayerStats initialized (facade)")
	
	# Sync base stats from XPLevelingSystem
	if XPLevelingSystem != null:
		base_resilience = XPLevelingSystem.base_resilience
		base_agility = XPLevelingSystem.base_agility
		base_int = XPLevelingSystem.base_int
		base_vit = XPLevelingSystem.base_vit
		
		# Connect to XPLevelingSystem signals and forward them
		XPLevelingSystem.stat_changed.connect(_on_stat_changed)
		XPLevelingSystem.base_stat_xp_gained.connect(_on_base_stat_xp_gained)
		XPLevelingSystem.base_stat_leveled_up.connect(_on_base_stat_leveled_up)
		XPLevelingSystem.character_level_changed.connect(_on_character_level_changed)
	
	# Sync gold from CurrencySystem
	if CurrencySystem != null:
		gold = CurrencySystem.gold
		CurrencySystem.gold_changed.connect(_on_gold_changed)
	
	# Initialize health/mana/stamina to max values
	health = get_max_health()
	mana = get_max_mana()
	stamina = get_max_stamina()
	_logger.log_info("Initialized: Health=" + str(health) + ", Mana=" + str(mana) + ", Stamina=" + str(stamina))
	
	# Connect to SpellSystem element level changes to update character level
	if SpellSystem != null:
		SpellSystem.element_leveled_up.connect(_on_element_leveled_up)
	
	# Connect to MovementTracker for heavy carry XP (delegates to XPLevelingSystem)
	if MovementTracker != null:
		MovementTracker.heavy_carry_moved.connect(_on_heavy_carry_moved)
		_logger.log_info("Connected to MovementTracker for heavy carry XP")
	else:
		_logger.log_error("MovementTracker not available - heavy carry XP will not work")
	
	# Initialize character level
	_update_character_level()


func _on_stat_changed(stat_name: String, new_value: int) -> void:
	"""Forwards stat_changed signal from XPLevelingSystem and syncs base stats."""
	# Sync base stat values
	match stat_name:
		StatConstants.STAT_RESILIENCE:
			base_resilience = new_value
		StatConstants.STAT_AGILITY:
			base_agility = new_value
		StatConstants.STAT_INT:
			base_int = new_value
		StatConstants.STAT_VIT:
			base_vit = new_value
	
	stat_changed.emit(stat_name, new_value)
	_update_character_level()


func _on_base_stat_xp_gained(stat_name: String, amount: int, total: int) -> void:
	"""Forwards base_stat_xp_gained signal from XPLevelingSystem."""
	base_stat_xp_gained.emit(stat_name, amount, total)


func _on_base_stat_leveled_up(stat_name: String, new_level: int) -> void:
	"""Forwards base_stat_leveled_up signal from XPLevelingSystem."""
	base_stat_leveled_up.emit(stat_name, new_level)


func _on_character_level_changed(new_level: int) -> void:
	"""Forwards character_level_changed signal from XPLevelingSystem."""
	character_level_changed.emit(new_level)


func _on_gold_changed(amount: int) -> void:
	"""Syncs gold from CurrencySystem and forwards signal."""
	gold = amount
	gold_changed.emit(amount)


func _on_element_leveled_up(_element: String, _new_level: int) -> void:
	"""Called when an element levels up to recalculate character level."""
	_update_character_level()


func _on_heavy_carry_moved(xp_amount: float, weight_percentage: float) -> void:
	"""Handles heavy carry movement XP from MovementTracker - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		XPLevelingSystem._on_heavy_carry_moved(xp_amount, weight_percentage)


# Derived Stats (UPDATED: Resilience/Agility)
func get_total_resilience() -> int:
	# Formerly get_total_str()
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_RESILIENCE)
	var temp_modifier: int = 0
	if BuffSystem != null:
		temp_modifier = BuffSystem.get_stat_modifier(StatConstants.STAT_RESILIENCE)
	return base_resilience + bonus + temp_modifier


func get_total_agility() -> int:
	# Formerly get_total_dex()
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_AGILITY)
	var temp_modifier: int = 0
	if BuffSystem != null:
		temp_modifier = BuffSystem.get_stat_modifier(StatConstants.STAT_AGILITY)
	return base_agility + bonus + temp_modifier


func get_total_int() -> int:
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_INT)
	var temp_modifier: int = 0
	if BuffSystem != null:
		temp_modifier = BuffSystem.get_stat_modifier(StatConstants.STAT_INT)
	return base_int + bonus + temp_modifier


func get_total_vit() -> int:
	var bonus: int = 0
	if InventorySystem != null:
		bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_VIT)
	var temp_modifier: int = 0
	if BuffSystem != null:
		temp_modifier = BuffSystem.get_stat_modifier(StatConstants.STAT_VIT)
	return base_vit + bonus + temp_modifier


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


# Carry weight system - delegates to CarryWeightSystem
func get_max_carry_weight() -> float:
	"""Returns maximum carry weight in kg based on resilience."""
	if CarryWeightSystem == null:
		return 0.0
	var resilience: int = get_total_resilience()
	return CarryWeightSystem.get_max_carry_weight(resilience)


func get_current_carry_weight() -> float:
	"""Calculates current total weight of all items in inventory."""
	if CarryWeightSystem == null:
		return 0.0
	return CarryWeightSystem.get_current_carry_weight()


func can_carry_item(item: ItemData, count: int = 1) -> bool:
	"""Checks if player can carry additional items."""
	if CarryWeightSystem == null:
		return false
	var resilience: int = get_total_resilience()
	return CarryWeightSystem.can_carry_item(item, count, resilience)


# Agility-based stamina consumption
func get_stamina_consumption_multiplier() -> float:
	"""Returns stamina consumption multiplier based on agility (lower = less stamina used)."""
	var agility: int = get_total_agility()
	return StatFormulas.calculate_stamina_consumption_multiplier(agility)


# Agility-based movement speed multiplier
func get_movement_speed_multiplier() -> float:
	"""Returns movement speed multiplier based on agility and buffs."""
	var agility: int = get_total_agility()
	var base_multiplier: float = StatFormulas.calculate_movement_speed_multiplier(agility)
	var speed_buff: float = 1.0
	if BuffSystem != null:
		speed_buff = BuffSystem.get_speed_multiplier()
	return base_multiplier * speed_buff


func get_carry_weight_slow_multiplier() -> float:
	"""Returns movement speed multiplier when carrying heavy load (85%+ weight)."""
	if CarryWeightSystem == null:
		return 1.0
	var resilience: int = get_total_resilience()
	return CarryWeightSystem.get_carry_weight_slow_multiplier(resilience)


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
	# Gain Resilience XP for taking damage - delegate to XPLevelingSystem
	if reduced_damage > 0 and XPLevelingSystem != null:
		XPLevelingSystem.gain_base_stat_xp(StatConstants.STAT_RESILIENCE, max(1, int(reduced_damage / 2.0)), StatConstants.STAT_RESILIENCE)


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
	# Gain Intelligence XP for casting spells - delegate to XPLevelingSystem
	if amount > 0 and XPLevelingSystem != null:
		XPLevelingSystem.gain_base_stat_xp(StatConstants.STAT_INT, max(1, int(amount / 2.5)), StatConstants.STAT_INT)
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
	# Gain Agility XP for using stamina - delegate to XPLevelingSystem
	if final_amount > 0 and XPLevelingSystem != null:
		XPLevelingSystem.gain_base_stat_xp(StatConstants.STAT_AGILITY, max(1, int(final_amount / 3.5)), StatConstants.STAT_AGILITY)
	return true


func has_stamina(amount: int) -> bool:
	return stamina >= amount


func restore_stamina(amount: int) -> void:
	set_stamina(stamina + amount)


# Getters for current resource values
func get_health() -> int:
	return health


func get_mana() -> int:
	return mana


func get_stamina() -> int:
	return stamina


# Gold Methods (LOCKED SIGNATURES per SPEC.md) - delegates to CurrencySystem
func add_gold(amount: int) -> void:
	if CurrencySystem != null:
		CurrencySystem.add_gold(amount)
	else:
		gold += amount
		gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if CurrencySystem != null:
		return CurrencySystem.spend_gold(amount)
	else:
		if not has_gold(amount):
			_logger.log("Failed to spend " + str(amount) + " gold (insufficient)")
			return false
		gold -= amount
		gold_changed.emit(gold)
		return true


func has_gold(amount: int) -> bool:
	if CurrencySystem != null:
		return CurrencySystem.has_gold(amount)
	return gold >= amount


# Base Stat XP and Leveling Methods - delegates to XPLevelingSystem
func gain_base_stat_xp(stat_name: String, amount: int, source_stat: String = "") -> void:
	"""Gains XP for a base stat - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		XPLevelingSystem.gain_base_stat_xp(stat_name, amount, source_stat)


func get_base_stat_xp(stat_name: String) -> int:
	"""Returns current XP for a base stat - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		return XPLevelingSystem.get_base_stat_xp(stat_name)
	return 0


func get_base_stat_xp_for_current_level(stat_name: String) -> int:
	"""Returns the minimum total XP needed for the current level - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		return XPLevelingSystem.get_base_stat_xp_for_current_level(stat_name)
	return 0


func get_base_stat_xp_for_next_level(stat_name: String) -> int:
	"""Returns the total XP needed to reach the next level - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		return XPLevelingSystem.get_base_stat_xp_for_next_level(stat_name)
	return 100


func get_stat_display_data(stat_name: String) -> Dictionary:
	"""Returns all display data needed for UI - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		return XPLevelingSystem.get_stat_display_data(stat_name)
	return {
		"level": 1,
		"total_xp": 0,
		"xp_in_level": 0,
		"xp_needed": 1,
		"xp_for_current": 0,
		"xp_for_next": 100
	}


func get_base_stat_level(stat_name: String) -> int:
	"""Returns the stored level for a base stat - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		return XPLevelingSystem.get_base_stat_level(stat_name)
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


func set_base_stat_level(stat_name: String, level: int) -> void:
	"""Sets a base stat to a specific level - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		XPLevelingSystem.set_base_stat_level(stat_name, level)
	else:
		set_base_stat(stat_name, level)


func set_base_stat(stat_name: String, value: int) -> void:
	"""Sets a base stat value directly - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		XPLevelingSystem.set_base_stat(stat_name, value)
	else:
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


func recalculate_stat_levels_from_xp() -> void:
	"""Recalculates all base stat levels from their current XP values - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		XPLevelingSystem.recalculate_stat_levels_from_xp()


func gain_resilience_xp_for_damage_dealt(damage: int) -> void:
	"""Called when player deals damage to gain Resilience XP - delegates to XPLevelingSystem."""
	if damage > 0 and XPLevelingSystem != null:
		XPLevelingSystem.gain_resilience_xp_for_damage_dealt(damage)


# Character Level Methods (combines all base stats + magic elements)
func get_character_level() -> int:
	"""Returns the player's character level based on all stats - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		return XPLevelingSystem.get_character_level()
	return 1


func get_character_level_info() -> Dictionary:
	"""Returns full character level information - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		return XPLevelingSystem.get_character_level_info()
	return {"character_level": 1, "total_skill_levels": 0, "levels_needed_for_next": 8}


func _update_character_level() -> void:
	"""Recalculates and emits character level changed signal - delegates to XPLevelingSystem."""
	if XPLevelingSystem != null:
		XPLevelingSystem._update_character_level()
	else:
		var new_level: int = get_character_level()
		character_level_changed.emit(new_level)


# Buff Methods - delegates to BuffSystem
func apply_stat_buff(stat_name: String, modifier: int, duration: float) -> void:
	"""Applies a temporary stat buff - delegates to BuffSystem."""
	if BuffSystem != null:
		BuffSystem.apply_stat_buff(stat_name, modifier, duration)
	else:
		_logger.log_error("BuffSystem not available")


func apply_speed_buff(multiplier: float, duration: float) -> void:
	"""Applies a movement speed buff - delegates to BuffSystem."""
	if BuffSystem != null:
		BuffSystem.apply_speed_buff(multiplier, duration)
	else:
		_logger.log_error("BuffSystem not available")
