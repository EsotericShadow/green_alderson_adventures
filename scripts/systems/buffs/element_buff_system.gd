extends Node
## Global element buff system (autoload singleton).
## Manages element damage buff multipliers with timers.

# Logging
var _logger = GameLogger.create("[ElementBuffSystem] ")

# Element damage multipliers for buffs (default 1.0 = no buff)
var element_damage_multipliers: Dictionary = {
	"fire": 1.0,
	"water": 1.0,
	"earth": 1.0,
	"air": 1.0
}

# Buff timers: {buff_id: {"timer": float, "multiplier": float, "element": String}}
var buff_timers: Dictionary = {}


func _ready() -> void:
	_logger.log_info("ElementBuffSystem initialized")


func _process(delta: float) -> void:
	"""Process buff timers and expire them when duration ends."""
	if buff_timers.is_empty():
		return
	
	# Process buff timers
	var expired_buffs: Array[String] = []
	for buff_id in buff_timers.keys():
		var buff_data: Dictionary = buff_timers[buff_id]
		buff_data["timer"] -= delta
		
		if buff_data["timer"] <= 0.0:
			# Buff expired - reset multiplier
			var element: String = buff_data["element"]
			element_damage_multipliers[element] = 1.0
			expired_buffs.append(buff_id)
			_logger.log("Buff expired: " + buff_id + " (" + element + " spell damage multiplier reset)")
	
	# Remove expired buffs
	for buff_id in expired_buffs:
		buff_timers.erase(buff_id)


## Gets element damage multiplier.
## 
## Args:
##   element: Element name ("fire", "water", "earth", "air")
## 
## Returns: Damage multiplier (1.0 = no buff)
func get_element_multiplier(element: String) -> float:
	return element_damage_multipliers.get(element, 1.0)


## Applies an element damage buff for a specified duration.
## 
## Args:
##   element: Element to buff ("fire", "water", "earth", "air")
##   multiplier: Damage multiplier (1.3 = +30% damage)
##   duration: Duration in seconds
func apply_element_buff(element: String, multiplier: float, duration: float) -> void:
	if not element_damage_multipliers.has(element):
		_logger.log_error("apply_element_buff() called with unknown element: " + element)
		return
	
	if duration <= 0.0:
		_logger.log_error("apply_element_buff() called with invalid duration: " + str(duration))
		return
	
	# Generate unique buff ID
	var buff_id: String = "element_buff_" + element + "_" + str(Time.get_ticks_msec())
	
	# Apply multiplier
	element_damage_multipliers[element] = multiplier
	
	# Store timer
	buff_timers[buff_id] = {
		"timer": duration,
		"multiplier": multiplier,
		"element": element
	}
	
	_logger.log("Applied " + element + " spell buff: " + str(multiplier) + "x damage for " + str(duration) + "s (buff_id: " + buff_id + ")")

