extends Node
## Global buff system (autoload singleton).
## Manages temporary stat modifiers and movement speed buffs with timers.

# Logging
var _logger = GameLogger.create("[BuffSystem] ")

# Temporary stat modifiers from buffs: {stat_name: modifier_value}
var temporary_stat_modifiers: Dictionary = {}

# Buff timers: {buff_id: {"timer": float, "stat": String, "modifier": int}}
var buff_timers: Dictionary = {}

# Movement speed buff multiplier (applied on top of agility multiplier)
var movement_speed_buff_multiplier: float = 1.0
var speed_buff_timer: float = 0.0


func _ready() -> void:
	_logger.log_info("BuffSystem initialized")


func _process(delta: float) -> void:
	# Process stat buff timers
	var expired_buffs: Array[String] = []
	for buff_id in buff_timers.keys():
		var buff_data: Dictionary = buff_timers[buff_id]
		buff_data["timer"] -= delta
		
		if buff_data["timer"] <= 0.0:
			# Buff expired - remove modifier
			var stat: String = buff_data["stat"]
			temporary_stat_modifiers.erase(stat)
			expired_buffs.append(buff_id)
			_logger.log("Stat buff expired: " + stat + " (buff_id: " + buff_id + ")")
	
	# Remove expired buffs
	for buff_id in expired_buffs:
		buff_timers.erase(buff_id)
	
	# Process speed buff timer
	if speed_buff_timer > 0.0:
		speed_buff_timer -= delta
		if speed_buff_timer <= 0.0:
			movement_speed_buff_multiplier = 1.0
			speed_buff_timer = 0.0
			_logger.log("Speed buff expired")


## Gets temporary stat modifier for a stat.
## 
## Args:
##   stat_name: Stat constant (StatConstants.STAT_*)
## 
## Returns: Modifier value (0 if no buff active)
func get_stat_modifier(stat_name: String) -> int:
	return temporary_stat_modifiers.get(stat_name, 0)


## Gets movement speed buff multiplier.
## 
## Returns: Speed multiplier (1.0 = no buff)
func get_speed_multiplier() -> float:
	return movement_speed_buff_multiplier


## Applies a temporary stat buff for a specified duration.
## 
## Args:
##   stat_name: Stat to buff (use StatConstants.STAT_*)
##   modifier: Stat modifier value (added to base stat)
##   duration: Duration in seconds
func apply_stat_buff(stat_name: String, modifier: int, duration: float) -> void:
	if duration <= 0.0:
		_logger.log_error("apply_stat_buff() called with invalid duration: " + str(duration))
		return
	
	# Generate unique buff ID
	var buff_id: String = "stat_buff_" + stat_name + "_" + str(Time.get_ticks_msec())
	
	# Apply modifier
	temporary_stat_modifiers[stat_name] = modifier
	
	# Store timer
	buff_timers[buff_id] = {
		"timer": duration,
		"stat": stat_name,
		"modifier": modifier
	}
	
	_logger.log("Applied " + stat_name + " buff: +" + str(modifier) + " for " + str(duration) + "s (buff_id: " + buff_id + ")")


## Applies a movement speed buff multiplier for a specified duration.
## 
## Args:
##   multiplier: Speed multiplier (1.3 = +30% speed)
##   duration: Duration in seconds
func apply_speed_buff(multiplier: float, duration: float) -> void:
	if duration <= 0.0:
		_logger.log_error("apply_speed_buff() called with invalid duration: " + str(duration))
		return
	
	movement_speed_buff_multiplier = multiplier
	speed_buff_timer = duration
	
	_logger.log("Applied speed buff: " + str(multiplier) + "x for " + str(duration) + "s")

