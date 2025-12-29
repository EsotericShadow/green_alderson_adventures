extends Node
## Global resource regeneration system (autoload singleton).
## Handles health, mana, and stamina regeneration.

# Logging
var _logger = GameLogger.create("[ResourceRegenSystem] ")

# Fractional accumulation for smooth regeneration
var _mana_regen_accumulator: float = 0.0
var _stamina_regen_accumulator: float = 0.0
var _health_regen_accumulator: float = 0.0


func _ready() -> void:
	_logger.log_info("ResourceRegenSystem initialized")


func _process(delta: float) -> void:
	if PlayerStats == null:
		return
	
	# Get base regen rates from GameBalance config
	var base_mana_regen: float = GameBalance.get_base_mana_regen()
	var base_stamina_regen: float = GameBalance.get_base_stamina_regen()
	var base_health_regen: float = GameBalance.get_base_health_regen()
	
	# Regenerate mana (scaled by INT)
	# Note: Uses PlayerStats.get_total_int() which will use XPLevelingSystem after split
	var int_stat: int = 1
	if PlayerStats != null:
		int_stat = PlayerStats.get_total_int()
	
	var mana_regen_rate: float = base_mana_regen * (1.0 + int_stat * 0.1)  # +10% per INT point
	if PlayerStats.mana < PlayerStats.get_max_mana():
		_mana_regen_accumulator += mana_regen_rate * delta
		if _mana_regen_accumulator >= 1.0:
			var regen_amount: int = int(_mana_regen_accumulator)
			_mana_regen_accumulator -= float(regen_amount)
			PlayerStats.restore_mana(regen_amount)
	
	# Regenerate stamina (scaled by Agility)
	if PlayerStats != null:
		var agility: int = PlayerStats.get_total_agility()
		var stamina_regen_rate: float = base_stamina_regen * (1.0 + agility * 0.15)  # +15% per agility point
		if PlayerStats.stamina < PlayerStats.get_max_stamina():
			_stamina_regen_accumulator += stamina_regen_rate * delta
			if _stamina_regen_accumulator >= 1.0:
				var regen_amount: int = int(_stamina_regen_accumulator)
				_stamina_regen_accumulator -= float(regen_amount)
				PlayerStats.restore_stamina(regen_amount)

	# Regenerate health (scaled by VIT)
	if PlayerStats != null:
		var vit: int = PlayerStats.get_total_vit()
		var health_regen_rate: float = base_health_regen * (1.0 + vit * 0.1)  # +10% per VIT point
		if PlayerStats.health < PlayerStats.get_max_health() and PlayerStats.health > 0:  # Don't regen if dead
			_health_regen_accumulator += health_regen_rate * delta
			if _health_regen_accumulator >= 1.0:
				var regen_amount: int = int(_health_regen_accumulator)
				_health_regen_accumulator -= float(regen_amount)
				PlayerStats.heal(regen_amount)
