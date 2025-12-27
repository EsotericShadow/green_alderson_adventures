extends RefCounted
class_name ActionCooldown
## Utility for managing action cooldowns (spells, attacks, abilities).
## Wraps CooldownManager with action-specific convenience methods.

## Checks if an action can be performed (cooldown has expired).
## 
## Args:
##   action_id: Unique identifier for the action (e.g., "spell_fire", "attack_melee")
##   cooldown_duration: Cooldown duration in seconds
## 
## Returns: true if cooldown has passed, false if still on cooldown
static func can_perform(action_id: String, cooldown_duration: float) -> bool:
	return CooldownManager.can_perform_action(action_id, cooldown_duration)


## Records that an action was performed (updates cooldown timestamp).
## 
## Args:
##   action_id: Unique identifier for the action
static func record(action_id: String) -> void:
	CooldownManager.record_action(action_id)


## Gets the time remaining on an action cooldown in seconds.
## Returns 0.0 if cooldown has expired or action was never performed.
## 
## Args:
##   action_id: Unique identifier for the action
##   cooldown_duration: Cooldown duration in seconds
## 
## Returns: Time remaining in seconds (0.0 if ready)
static func get_time_remaining(action_id: String, cooldown_duration: float) -> float:
	return CooldownManager.get_time_remaining(action_id, cooldown_duration)


## Resets cooldown for a specific action.
## 
## Args:
##   action_id: Unique identifier for the action (or empty string to reset all)
static func reset(action_id: String = "") -> void:
	CooldownManager.reset(action_id)


## Resets all action cooldowns.
static func reset_all() -> void:
	CooldownManager.reset_all()

