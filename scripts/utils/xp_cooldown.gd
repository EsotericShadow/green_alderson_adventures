extends RefCounted
class_name XPCooldown
## Specialized utility for managing XP gain cooldowns per stat.
## Wraps CooldownManager with XP-specific defaults and convenience methods.

# Cooldown duration in seconds
const COOLDOWN_DURATION: float = 0.1


## Checks if a stat can gain XP (cooldown has expired).
## Returns true if cooldown has passed, false if still on cooldown.
static func can_gain_xp(stat_name: String) -> bool:
	var action_id: String = "xp_" + stat_name
	return CooldownManager.can_perform_action(action_id, COOLDOWN_DURATION)


## Records that XP was gained for a stat (updates cooldown timestamp).
static func record_xp_gain(stat_name: String) -> void:
	var action_id: String = "xp_" + stat_name
	CooldownManager.record_action(action_id)


## Gets the time remaining on XP cooldown for a stat.
## Returns 0.0 if cooldown has expired.
static func get_time_remaining(stat_name: String) -> float:
	var action_id: String = "xp_" + stat_name
	return CooldownManager.get_time_remaining(action_id, COOLDOWN_DURATION)


## Resets XP cooldown for a specific stat.
static func reset(stat_name: String = "") -> void:
	if stat_name == "":
		# Reset all XP cooldowns
		CooldownManager.reset_all()
	else:
		var action_id: String = "xp_" + stat_name
		CooldownManager.reset(action_id)


## Resets all XP cooldowns (useful for testing or reset scenarios).
static func reset_all() -> void:
	CooldownManager.reset_all()
