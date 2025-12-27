extends RefCounted
class_name CooldownManager
## General-purpose cooldown manager utility.
## Tracks cooldowns for any action type by string identifier.
## Simple, maintainable, reusable cooldown system.

# Dictionary tracking last action time per identifier (in milliseconds)
static var _last_action_time: Dictionary = {}


## Checks if an action can be performed (cooldown has expired).
## 
## Args:
##   action_id: Unique identifier for the action (e.g., "spell_fire", "attack", "resilience_xp")
##   cooldown_duration: Cooldown duration in seconds
## 
## Returns: true if cooldown has passed, false if still on cooldown
static func can_perform_action(action_id: String, cooldown_duration: float) -> bool:
	if not _last_action_time.has(action_id):
		return true  # Never performed this action, allow it
	
	var last_time: int = _last_action_time[action_id]
	var current_time: int = Time.get_ticks_msec()
	var time_since_last: float = (current_time - last_time) / 1000.0
	
	return time_since_last >= cooldown_duration


## Records that an action was performed (updates cooldown timestamp).
## 
## Args:
##   action_id: Unique identifier for the action
static func record_action(action_id: String) -> void:
	_last_action_time[action_id] = Time.get_ticks_msec()


## Gets the time remaining on a cooldown in seconds.
## Returns 0.0 if cooldown has expired or action was never performed.
## 
## Args:
##   action_id: Unique identifier for the action
##   cooldown_duration: Cooldown duration in seconds
## 
## Returns: Time remaining in seconds (0.0 if ready)
static func get_time_remaining(action_id: String, cooldown_duration: float) -> float:
	if not _last_action_time.has(action_id):
		return 0.0
	
	var last_time: int = _last_action_time[action_id]
	var current_time: int = Time.get_ticks_msec()
	var time_since_last: float = (current_time - last_time) / 1000.0
	var remaining: float = cooldown_duration - time_since_last
	
	return max(0.0, remaining)


## Resets cooldown for a specific action.
## 
## Args:
##   action_id: Unique identifier for the action (or null to reset all)
static func reset(action_id: String = "") -> void:
	if action_id == "":
		_last_action_time.clear()
	elif _last_action_time.has(action_id):
		_last_action_time.erase(action_id)


## Resets all cooldowns (useful for testing or reset scenarios).
static func reset_all() -> void:
	_last_action_time.clear()

