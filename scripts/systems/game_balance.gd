extends Node
## Global game balance configuration system (autoload singleton).
## Loads and exposes GameBalanceConfig resource for all systems to use.

# Logging
var _logger = GameLogger.create("[GameBalance] ")

# Configuration (loaded from resource)
var config: GameBalanceConfig = null

# Default config path
const DEFAULT_CONFIG_PATH: String = "res://resources/config/default_balance.tres"


func _ready() -> void:
	_logger.log("GameBalance initialized")
	_load_config()


func _load_config() -> void:
	"""Loads the game balance configuration resource."""
	# Check if file exists before attempting to load
	if ResourceLoader.exists(DEFAULT_CONFIG_PATH):
		var loaded_config = load(DEFAULT_CONFIG_PATH) as GameBalanceConfig
		if loaded_config != null:
			config = loaded_config
			_logger.log("Loaded GameBalanceConfig from " + DEFAULT_CONFIG_PATH)
		else:
			_logger.log_warning("Failed to load GameBalanceConfig from " + DEFAULT_CONFIG_PATH + " - using defaults")
			config = GameBalanceConfig.new()
	else:
		_logger.log_debug("GameBalanceConfig file not found at " + DEFAULT_CONFIG_PATH + " - using defaults")
		# Create default config in memory
		config = GameBalanceConfig.new()


# Convenience getters (delegate to config)
func get_walk_speed() -> float:
	return config.walk_speed if config != null else 120.0


func get_run_speed() -> float:
	return config.run_speed if config != null else 220.0


func get_stamina_drain_rate() -> float:
	return config.stamina_drain_rate if config != null else 20.0


func get_min_stamina_to_run() -> int:
	return config.min_stamina_to_run if config != null else 5


func get_base_mana_regen() -> float:
	return config.base_mana_regen if config != null else 5.0


func get_base_stamina_regen() -> float:
	return config.base_stamina_regen if config != null else 3.0


func get_base_health_regen() -> float:
	return config.base_health_regen if config != null else 0.5


func get_health_per_vit() -> int:
	return config.health_per_vit if config != null else 20


func get_mana_per_int() -> int:
	return config.mana_per_int if config != null else 15


func get_stamina_per_agility() -> int:
	return config.stamina_per_agility if config != null else 10


func get_max_base_stat_level() -> int:
	return config.max_base_stat_level if config != null else 110


func get_max_element_level() -> int:
	return config.max_element_level if config != null else 110


func get_vitality_xp_ratio() -> int:
	return config.vitality_xp_ratio if config != null else 8


func get_heavy_carry_threshold() -> float:
	return config.heavy_carry_threshold if config != null else 0.90


func get_heavy_carry_xp_per_meter() -> float:
	return config.heavy_carry_xp_per_meter if config != null else 0.1


func get_spell_cast_delay_ratio() -> float:
	return config.spell_cast_delay_ratio if config != null else 0.583


func get_spell_xp_damage_ratio() -> float:
	return config.spell_xp_damage_ratio if config != null else 2.0
