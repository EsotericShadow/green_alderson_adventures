extends RefCounted
class_name RateLimiter
## Utility for rate limiting actions (e.g., max X actions per second).
## Prevents spam by limiting how frequently actions can occur.

# Dictionary tracking action counts and timestamps
static var _action_counts: Dictionary = {}  # { action_id: { "count": int, "window_start": int } }


## Checks if an action can be performed based on rate limit.
## 
## Args:
##   action_id: Unique identifier for the action
##   max_actions: Maximum number of actions allowed
##   time_window: Time window in seconds (e.g., 1.0 for "max_actions per second")
## 
## Returns: true if action is allowed, false if rate limit exceeded
static func can_perform(action_id: String, max_actions: int, time_window: float) -> bool:
	if not _action_counts.has(action_id):
		# First action, allow it
		_action_counts[action_id] = { "count": 0, "window_start": Time.get_ticks_msec() }
	
	var data: Dictionary = _action_counts[action_id]
	var current_time: int = Time.get_ticks_msec()
	var window_start: int = data["window_start"]
	var elapsed: float = (current_time - window_start) / 1000.0
	
	# Reset window if time has passed
	if elapsed >= time_window:
		data["count"] = 0
		data["window_start"] = current_time
		return true
	
	# Check if we've exceeded the limit
	if data["count"] >= max_actions:
		return false
	
	return true


## Records that an action was performed (increments counter).
## 
## Args:
##   action_id: Unique identifier for the action
static func record(action_id: String) -> void:
	if not _action_counts.has(action_id):
		_action_counts[action_id] = { "count": 0, "window_start": Time.get_ticks_msec() }
	
	var data: Dictionary = _action_counts[action_id]
	data["count"] = data.get("count", 0) + 1


## Gets the number of actions performed in the current time window.
## 
## Args:
##   action_id: Unique identifier for the action
##   time_window: Time window in seconds
## 
## Returns: Number of actions in current window
static func get_action_count(action_id: String, time_window: float) -> int:
	if not _action_counts.has(action_id):
		return 0
	
	var data: Dictionary = _action_counts[action_id]
	var current_time: int = Time.get_ticks_msec()
	var window_start: int = data["window_start"]
	var elapsed: float = (current_time - window_start) / 1000.0
	
	# Reset if window has passed
	if elapsed >= time_window:
		return 0
	
	return data.get("count", 0)


## Resets rate limit tracking for a specific action.
## 
## Args:
##   action_id: Unique identifier for the action (or empty string to reset all)
static func reset(action_id: String = "") -> void:
	if action_id == "":
		_action_counts.clear()
	elif _action_counts.has(action_id):
		_action_counts.erase(action_id)


## Resets all rate limit tracking.
static func reset_all() -> void:
	_action_counts.clear()

