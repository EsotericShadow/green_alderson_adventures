extends "res://scripts/workers/base/base_worker.gd"
class_name RunningStateManager

## WORKER: Manages running state and stamina drain
## Does ONE thing: manages running state based on input and stamina
## Does NOT: make high-level decisions, handle movement logic

# Configuration (should be set from coordinator or GameBalance config)
var stamina_drain_rate: float = 20.0  # Stamina per second while running
var min_stamina_to_run: int = 5  # Minimum stamina required to run

# References (set by coordinator)
var input_reader: InputReader = null

# State
var _running_enabled: bool = false  # Whether running is currently enabled
var _stamina_drain_accumulator: float = 0.0  # Fractional accumulator for smooth stamina drain


func _on_initialize() -> void:
	"""Initialize running state manager."""
	# No additional initialization needed - BaseWorker handles logging
	pass


func update_running_state(delta: float, input_vec: Vector2) -> void:
	"""Updates running state and handles stamina drain.
	
	Args:
		delta: Frame delta time
		input_vec: Current movement input vector (to determine if player is moving)
	"""
	if input_reader == null:
		return
	
	var run_key_just_pressed := input_reader.is_run_just_pressed()
	var run_key_just_released := input_reader.is_run_just_released()
	
	# Handle running state transitions
	# Enable running when run key is pressed (can happen while already moving)
	if run_key_just_pressed:
		if PlayerStats.has_stamina(min_stamina_to_run):
			_running_enabled = true
			_logger.log_debug("🏃 Running enabled (run key pressed)")
		else:
			_logger.log_debug("🏃 Run key pressed but insufficient stamina")
	
	# Disable running when run key is released
	if run_key_just_released:
		_running_enabled = false
		_logger.log_debug("🚶 Running disabled (run key released)")
	
	# Auto-disable running when stamina depletes (even if run key is still held)
	var has_enough_stamina: bool = PlayerStats.has_stamina(min_stamina_to_run)
	if _running_enabled and not has_enough_stamina:
		_running_enabled = false
		_logger.log_debug("🚶 Running auto-disabled (stamina depleted)")
	
	# Consume stamina while running (fractional accumulation for smooth drain)
	# Stamina consumption is already reduced by agility in PlayerStats.consume_stamina()
	var wants_run: bool = _running_enabled and has_enough_stamina
	if wants_run and input_vec.length() > 0.0:
		_stamina_drain_accumulator += stamina_drain_rate * delta
		if _stamina_drain_accumulator >= 1.0:
			var stamina_cost: int = int(_stamina_drain_accumulator)
			_stamina_drain_accumulator -= float(stamina_cost)
			PlayerStats.consume_stamina(stamina_cost)
	else:
		# Reset accumulator when not running
		_stamina_drain_accumulator = 0.0


func can_run() -> bool:
	"""Returns true if player can currently run (enabled and has enough stamina)."""
	if input_reader == null:
		return false
	
	var has_enough_stamina: bool = PlayerStats.has_stamina(min_stamina_to_run)
	return _running_enabled and has_enough_stamina


func is_running_enabled() -> bool:
	"""Returns true if running is currently enabled (regardless of stamina)."""
	return _running_enabled


func reset() -> void:
	"""Resets running state (used for respawn, death, etc.)."""
	_running_enabled = false
	_stamina_drain_accumulator = 0.0

