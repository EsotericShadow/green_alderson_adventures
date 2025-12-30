class_name PotionConsumptionHandler
extends RefCounted
## Worker class that handles potion effect application.
## Called by InventorySystem when a potion is consumed.

# Logging
var _logger = GameLogger.create("[PotionHandler] ")

# Scene tree reference (set by InventorySystem)
var _scene_tree: SceneTree = null

# Signals
signal potion_consumed(potion: PotionData, success: bool)
signal effect_applied(effect: String, potency: int)


## Sets the scene tree reference for area effects.
## Called by InventorySystem in _ready().
func set_scene_tree(tree: SceneTree) -> void:
	_scene_tree = tree
	_logger.log("Scene tree reference set")


## Main entry point - validates and applies potion effect.
## 
## Args:
##   potion: The PotionData resource to consume
## 
## Returns: True if potion was consumed successfully, false otherwise
func consume_potion(potion: PotionData) -> bool:
	# Validate input
	if potion == null:
		_logger.log_error("consume_potion() called with null potion")
		potion_consumed.emit(null, false)
		return false
	
	# Check PlayerStats dependency
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot consume potion")
		potion_consumed.emit(potion, false)
		return false
	
	# Apply the effect
	_apply_effect(potion)
	
	# Emit signal
	potion_consumed.emit(potion, true)
	_logger.log("Potion consumed: " + potion.display_name + " (effect: " + potion.effect + ", potency: " + str(potion.potency) + ")")
	
	return true


## Routes to appropriate effect handler based on potion.effect
func _apply_effect(potion: PotionData) -> void:
	match potion.effect:
		"restore_health", "restore_mana", "restore_stamina":
			_handle_restore_effect(potion)
		"restore_all":
			_handle_restore_all(potion.potency)
		"buff_speed":
			_handle_speed_buff(potion)
		"buff_strength":
			_handle_strength_buff(potion)
		"buff_defense":
			_handle_defense_buff(potion)
		"buff_intelligence":
			_handle_intelligence_buff(potion)
		"buff_water_spells":
			_handle_water_spell_buff(potion)
		"buff_curse_resistance":
			_handle_curse_resistance_buff(potion)
		"area_fire_damage", "area_radiant_damage":
			_handle_area_damage(potion)
		"area_enemy_slow":
			_handle_enemy_slow(potion)
		"buff_random_element":
			_handle_random_element_buff(potion)
		"buff_lightning_chaining":
			_handle_lightning_chaining_buff(potion)
		_:
			_logger.log_error("Unknown potion effect: " + potion.effect)
	
	# Emit effect applied signal
	effect_applied.emit(potion.effect, potion.potency)


## Handles instant restore effects (health, mana, stamina)
func _handle_restore_effect(potion: PotionData) -> void:
	match potion.effect:
		"restore_health":
			PlayerStats.heal(potion.potency)
			_logger.log("Restored " + str(potion.potency) + " health")
		"restore_mana":
			PlayerStats.restore_mana(potion.potency)
			_logger.log("Restored " + str(potion.potency) + " mana")
		"restore_stamina":
			PlayerStats.restore_stamina(potion.potency)
			_logger.log("Restored " + str(potion.potency) + " stamina")


## Handles all-in-one elixir that restores all three resources
func _handle_restore_all(potency: int) -> void:
	if potency < 0:
		_logger.log("Warning: restore_all called with negative potency: " + str(potency))
		return
	
	PlayerStats.heal(potency)
	PlayerStats.restore_mana(potency)
	PlayerStats.restore_stamina(potency)
	_logger.log("Restored " + str(potency) + " to all resources (health, mana, stamina)")


## Handles speed buff effect
func _handle_speed_buff(potion: PotionData) -> void:
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot apply speed buff")
		return
	
	var multiplier: float = 1.0 + (potion.potency / 100.0)  # potency is percentage (e.g., 30 = +30%)
	PlayerStats.apply_speed_buff(multiplier, potion.duration)
	_logger.log("Applied speed buff: " + str(multiplier) + "x for " + str(potion.duration) + "s")


## Handles strength buff effect (damage percentage bonus)
## Note: Strength buff affects damage percentage, not a stat modifier
func _handle_strength_buff(potion: PotionData) -> void:
	# Strength buff could be implemented as a damage percentage bonus
	# For now, treat as resilience modifier (affects damage dealt)
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot apply strength buff")
		return
	
	# Apply as resilience modifier (affects damage output indirectly)
	# Future: Could add separate damage_bonus_multiplier to PlayerStats
	PlayerStats.apply_stat_buff(StatConstants.STAT_RESILIENCE, potion.potency, potion.duration)
	_logger.log("Applied strength buff: +" + str(potion.potency) + " resilience for " + str(potion.duration) + "s")


## Handles defense buff effect
func _handle_defense_buff(potion: PotionData) -> void:
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot apply defense buff")
		return
	
	PlayerStats.apply_stat_buff(StatConstants.STAT_RESILIENCE, potion.potency, potion.duration)
	_logger.log("Applied defense buff: +" + str(potion.potency) + " resilience for " + str(potion.duration) + "s")


## Handles intelligence buff effect
func _handle_intelligence_buff(potion: PotionData) -> void:
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot apply intelligence buff")
		return
	
	PlayerStats.apply_stat_buff(StatConstants.STAT_INT, potion.potency, potion.duration)
	_logger.log("Applied intelligence buff: +" + str(potion.potency) + " INT for " + str(potion.duration) + "s")


## Handles water spell buff effect
func _handle_water_spell_buff(potion: PotionData) -> void:
	if SpellSystem == null:
		_logger.log_error("SpellSystem is null, cannot apply water spell buff")
		return
	
	var multiplier: float = 1.0 + (potion.potency / 100.0)  # potency is percentage
	SpellSystem.apply_element_buff("water", multiplier, potion.duration)
	_logger.log("Applied water spell buff: " + str(multiplier) + "x damage for " + str(potion.duration) + "s")


## Handles curse resistance buff effect
## Note: Curse system not yet implemented, treat as enhanced defense
func _handle_curse_resistance_buff(potion: PotionData) -> void:
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot apply curse resistance buff")
		return
	
	# Treat as enhanced defense until curse system is implemented
	PlayerStats.apply_stat_buff(StatConstants.STAT_RESILIENCE, potion.potency, potion.duration)
	_logger.log("Applied curse resistance buff: +" + str(potion.potency) + " resilience for " + str(potion.duration) + "s")


## Handles area damage effects (fire pulse, radiant burst)
func _handle_area_damage(potion: PotionData) -> void:
	if _scene_tree == null:
		_logger.log_error("Scene tree not available for area damage")
		return
	
	var player = _scene_tree.get_first_node_in_group(GameConstants.GROUP_PLAYER)
	if player == null:
		_logger.log_error("Player not found for area damage")
		return
	
	var worker = AreaDamageWorker.new()
	var damage_type = "fire" if potion.effect == "area_fire_damage" else "radiant"
	var radius: float = 100.0  # Area damage radius in pixels
	worker.deal_area_damage(player.global_position, radius, potion.potency, damage_type, _scene_tree)
	_logger.log("Applied area damage: " + str(potion.potency) + " " + damage_type + " damage")


## Handles enemy slow debuff effect
func _handle_enemy_slow(potion: PotionData) -> void:
	if _scene_tree == null:
		_logger.log_error("Scene tree not available for enemy slow")
		return
	
	var player = _scene_tree.get_first_node_in_group(GameConstants.GROUP_PLAYER)
	if player == null:
		_logger.log_error("Player not found for enemy slow")
		return
	
	var enemies = _scene_tree.get_nodes_in_group(GameConstants.GROUP_ENEMY)
	var radius: float = 150.0  # Slow radius in pixels
	var hit_count: int = 0
	
	for enemy in enemies:
		if not enemy is BaseEnemy:
			continue
		
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance <= radius:
			# potency is percentage (0-100), convert to 0.0-1.0
			var potency_float: float = potion.potency / 100.0
			enemy.apply_debuff("slow", potency_float, potion.duration)
			hit_count += 1
	
	_logger.log("Applied slow debuff to " + str(hit_count) + " enemies")


## Handles random element buff effect
func _handle_random_element_buff(potion: PotionData) -> void:
	if SpellSystem == null:
		_logger.log_error("SpellSystem is null, cannot apply random element buff")
		return
	
	# Randomly select an element
	var elements: Array[String] = ["fire", "water", "earth", "air"]
	var random_element: String = elements[randi() % elements.size()]
	
	var multiplier: float = 1.0 + (potion.potency / 100.0)  # potency is percentage
	SpellSystem.apply_element_buff(random_element, multiplier, potion.duration)
	_logger.log("Applied random element buff: " + random_element + " " + str(multiplier) + "x damage for " + str(potion.duration) + "s")


## Handles lightning chaining buff effect
func _handle_lightning_chaining_buff(potion: PotionData) -> void:
	if SpellSystem == null:
		_logger.log_error("SpellSystem is null, cannot apply lightning chaining buff")
		return
	
	# Lightning chaining applies to air spells
	var multiplier: float = 1.0 + (potion.potency / 100.0)  # potency is percentage
	SpellSystem.apply_element_buff("air", multiplier, potion.duration)
	_logger.log("Applied lightning chaining buff: air " + str(multiplier) + "x damage for " + str(potion.duration) + "s")
	# Note: Actual chaining logic would be implemented in spell projectiles (future enhancement)
