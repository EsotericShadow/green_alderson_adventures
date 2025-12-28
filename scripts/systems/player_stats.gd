extends Node
## Global player stats system (autoload singleton).
## Manages base stats (Resilience/Agility/INT/VIT), derived values (health/mana/stamina), and gold.
##
## System Ownership and Data Flow:
## - PlayerStats stores the actual stat levels (base_resilience, base_agility, base_int, base_vit)
## - PlayerStats stored levels are the single source of truth for display
## - BaseStatLeveling owns XP storage and level calculation logic
## - BaseStatLeveling directly modifies PlayerStats levels on level-up (clear ownership)
## - UI layer retrieves data via delegation methods (get_base_stat_xp, get_stat_display_data, etc.)
##
## Data Flow: BaseStatLeveling (XP) → Level Calculation → PlayerStats (stored) → UI (display)

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

# Base Stats (RENAMED: STR→Resilience, DEX→Agility)
# These values represent both the stat value AND the level
var base_resilience: int = 1  # Formerly base_str
var base_agility: int = 1  # Formerly base_dex
var base_int: int = 1
var base_vit: int = 1



# Current Values (LOCKED NAMES per SPEC.md)
var health: int = 100
var mana: int = 75
var stamina: int = 50
var gold: int = 0

# Constants (LOCKED FORMULAS per SPEC.md)
const HEALTH_PER_VIT: int = 20
const MANA_PER_INT: int = 15
const STAMINA_PER_AGILITY: int = 10  # Formerly STAMINA_PER_DEX

# Regeneration base rates (will be scaled by stats)
# NOTE: Increased for testing - will be reduced when potions/buffs are implemented
const BASE_MANA_REGEN: float = 5.0  # Base mana per second (increased from 0.8 for testing)
const BASE_STAMINA_REGEN: float = 3.0  # Base stamina per second
const BASE_HEALTH_REGEN: float = 0.5  # Base health per second




func _ready() -> void:
	_logger.log("PlayerStats initialized")
	# Initialize health/mana/stamina to max values
	health = get_max_health()
	mana = get_max_mana()
	stamina = get_max_stamina()
	_logger.log("Initialized: Health=" + str(health) + ", Mana=" + str(mana) + ", Stamina=" + str(stamina))
	
	# Connect to SpellSystem element level changes to update character level
	if SpellSystem != null:
		SpellSystem.element_leveled_up.connect(_on_element_leveled_up)
	
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
	
	# Regenerate mana (scaled by INT)
	var mana_regen_rate: float = BASE_MANA_REGEN * (1.0 + get_total_int() * 0.1)  # +10% per INT point
	if mana < get_max_mana():
		_mana_regen_accumulator += mana_regen_rate * delta
		if _mana_regen_accumulator >= 1.0:
			var regen_amount: int = int(_mana_regen_accumulator)
			_mana_regen_accumulator -= float(regen_amount)
			restore_mana(regen_amount)
	
	# Regenerate stamina (scaled by Agility)
	var agility: int = get_total_agility()
	var stamina_regen_rate: float = BASE_STAMINA_REGEN * (1.0 + agility * 0.15)  # +15% per agility point
	if stamina < get_max_stamina():
		_stamina_regen_accumulator += stamina_regen_rate * delta
		if _stamina_regen_accumulator >= 1.0:
			var regen_amount: int = int(_stamina_regen_accumulator)
			_stamina_regen_accumulator -= float(regen_amount)
			restore_stamina(regen_amount)

	# Regenerate health (scaled by VIT)
	var vit: int = get_total_vit()
	var health_regen_rate: float = BASE_HEALTH_REGEN * (1.0 + vit * 0.1)  # +10% per VIT point
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
	return get_total_vit() * HEALTH_PER_VIT


func get_max_mana() -> int:
	return get_total_int() * MANA_PER_INT


func get_max_stamina() -> int:
	return get_total_agility() * STAMINA_PER_AGILITY


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
	if reduced_damage > 0 and BaseStatLeveling != null:
		BaseStatLeveling.gain_base_stat_xp(StatConstants.STAT_RESILIENCE, max(1, int(reduced_damage / 2.0)), StatConstants.STAT_RESILIENCE)


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
	if amount > 0 and BaseStatLeveling != null:
		BaseStatLeveling.gain_base_stat_xp(StatConstants.STAT_INT, max(1, int(amount / 2.5)), StatConstants.STAT_INT)
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
	if final_amount > 0 and BaseStatLeveling != null:
		BaseStatLeveling.gain_base_stat_xp(StatConstants.STAT_AGILITY, max(1, int(final_amount / 3.5)), StatConstants.STAT_AGILITY)
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


# Base Stat XP and Leveling Methods (delegated to BaseStatLeveling)
func gain_base_stat_xp(stat_name: String, amount: int, source_stat: String = "") -> void:
	"""Delegates to BaseStatLeveling for XP gain."""
	if BaseStatLeveling != null:
		BaseStatLeveling.gain_base_stat_xp(stat_name, amount, source_stat)


func get_base_stat_xp(stat_name: String) -> int:
	"""Returns current XP for a base stat (delegated to BaseStatLeveling)."""
	if BaseStatLeveling != null:
		return BaseStatLeveling.get_base_stat_xp(stat_name)
	return 0


func get_base_stat_xp_for_current_level(stat_name: String) -> int:
	"""Returns the minimum total XP needed for the current level (delegated to BaseStatLeveling)."""
	if BaseStatLeveling != null:
		return BaseStatLeveling.get_base_stat_xp_for_current_level(stat_name)
	return 0


func get_base_stat_xp_for_next_level(stat_name: String) -> int:
	"""Returns the total XP needed to reach next level for a base stat (delegated to BaseStatLeveling)."""
	if BaseStatLeveling != null:
		return BaseStatLeveling.get_base_stat_xp_for_next_level(stat_name)
	return 100


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
	if damage > 0 and BaseStatLeveling != null:
		BaseStatLeveling.gain_base_stat_xp(StatConstants.STAT_RESILIENCE, max(1, int(damage / 2.0)), StatConstants.STAT_RESILIENCE)


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
