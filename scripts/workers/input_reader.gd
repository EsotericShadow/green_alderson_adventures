extends Node
class_name InputReader

## WORKER: Reads player input
## Does ONE thing: reports what buttons are pressed
## Does NOT: trigger actions, make decisions, emit signals

var enabled: bool = true


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


## Check if the player wants to run
func is_running() -> bool:
	if not enabled:
		return false
	
	return (
		Input.is_action_pressed("run_north") or
		Input.is_action_pressed("run_south") or
		Input.is_action_pressed("run_east") or
		Input.is_action_pressed("run_west") or
		(InputMap.has_action("run") and Input.is_action_pressed("run"))
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


## Enable input reading
func enable() -> void:
	enabled = true

