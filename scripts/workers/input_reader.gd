extends BaseWorker
class_name InputReader

## WORKER: Reads player input
## Does ONE thing: reports what buttons are pressed
## Does NOT: trigger actions, make decisions, emit signals

var enabled: bool = true

# Track previous state of run modifier for "just pressed" detection
var _previous_run_modifier_pressed: bool = false


func _on_initialize() -> void:
	"""Initialize input reader - set up run modifier tracking."""
	_previous_run_modifier_pressed = is_run_modifier_pressed()


func _process(_delta: float) -> void:
	# Update previous state at the END of the frame for "just pressed" detection
	# This ensures we check the state correctly at the start of the next frame
	# We'll update it at the end by using call_deferred
	call_deferred("_update_previous_run_modifier_state")


func _update_previous_run_modifier_state() -> void:
	_previous_run_modifier_pressed = is_run_modifier_pressed()


## Get the current movement direction as a normalized vector
func get_movement() -> Vector2:
	if not enabled:
		return Vector2.ZERO
	
	var vec := Vector2(
		Input.get_action_strength("move_east") - Input.get_action_strength("move_west"),
		Input.get_action_strength("move_south") - Input.get_action_strength("move_north")
	)
	
	if vec.length() > 0.0:
		return vec.normalized()
	return Vector2.ZERO


## Check if the run modifier key (Command/Control) is currently held
func is_run_modifier_pressed() -> bool:
	if not enabled:
		return false
	# Check for Command (Meta) or Control key
	return Input.is_key_pressed(KEY_META) or Input.is_key_pressed(KEY_CTRL)


## Check if the run modifier key was just pressed this frame
func is_run_modifier_just_pressed() -> bool:
	if not enabled:
		return false
	# Check if modifier is pressed now but wasn't before
	var currently_pressed: bool = is_run_modifier_pressed()
	return currently_pressed and not _previous_run_modifier_pressed


## Check if the run modifier key was just released this frame
func is_run_modifier_just_released() -> bool:
	if not enabled:
		return false
	# Check if modifier was pressed before but isn't now
	var currently_pressed: bool = is_run_modifier_pressed()
	return _previous_run_modifier_pressed and not currently_pressed


## Check if the player wants to run (run key is currently held)
func is_running() -> bool:
	if not enabled:
		return false
	
	# Check for directional run actions OR run modifier + movement
	var has_movement: bool = get_movement().length() > 0.0
	return (
		Input.is_action_pressed("run_north") or
		Input.is_action_pressed("run_south") or
		Input.is_action_pressed("run_east") or
		Input.is_action_pressed("run_west") or
		(is_run_modifier_pressed() and has_movement) or
		(InputMap.has_action("run") and Input.is_action_pressed("run"))
	)


## Check if the run key was just pressed this frame
func is_run_just_pressed() -> bool:
	if not enabled:
		return false
	
	# Check for directional run actions OR run modifier just pressed while moving
	var has_movement: bool = get_movement().length() > 0.0
	var modifier_just_pressed: bool = is_run_modifier_just_pressed()
	
	return (
		Input.is_action_just_pressed("run_north") or
		Input.is_action_just_pressed("run_south") or
		Input.is_action_just_pressed("run_east") or
		Input.is_action_just_pressed("run_west") or
		(modifier_just_pressed and has_movement) or
		(InputMap.has_action("run") and Input.is_action_just_pressed("run"))
	)


## Check if the run key was just released this frame
func is_run_just_released() -> bool:
	if not enabled:
		return false
	
	return (
		Input.is_action_just_released("run_north") or
		Input.is_action_just_released("run_south") or
		Input.is_action_just_released("run_east") or
		Input.is_action_just_released("run_west") or
		is_run_modifier_just_released() or
		(InputMap.has_action("run") and Input.is_action_just_released("run"))
	)


## Check if an action was just pressed this frame
func is_action_just_pressed(action: String) -> bool:
	if not enabled:
		return false
	return Input.is_action_just_pressed(action)


## Check if an action is currently held
func is_action_pressed(action: String) -> bool:
	if not enabled:
		return false
	return Input.is_action_pressed(action)


## Disable input reading
func disable() -> void:
	enabled = false
	# _logger.log("Input disabled")  # Commented out: movement logging


## Enable input reading
func enable() -> void:
	enabled = true
	# _logger.log("Input enabled")  # Commented out: movement logging

