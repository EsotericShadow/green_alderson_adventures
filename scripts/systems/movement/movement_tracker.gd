extends Node
## Global movement and weight tracking system (autoload singleton).
## Tracks player movement and carry weight, emits signals for movement-based XP gain.

# Logging
var _logger = GameLogger.create("[MovementTracker] ")

# Signals
signal heavy_carry_moved(distance: float, weight_percentage: float)
## Emitted when player moves while carrying >= 90% of max weight.
## Args:
##   distance: Distance moved in meters
##   weight_percentage: Current weight as percentage of max (0.0 to 1.0)

# Constants (now loaded from GameBalance config)
const HEAVY_CARRY_THRESHOLD: float = 0.90  # Use GameBalance.get_heavy_carry_threshold() instead (fallback)
const HEAVY_CARRY_XP_PER_METER: float = 0.1  # Use GameBalance.get_heavy_carry_xp_per_meter() instead (fallback)

# State
var _last_player_position: Vector2 = Vector2.ZERO
var _heavy_carry_distance_accumulator: float = 0.0


func _ready() -> void:
	_logger.log_info("MovementTracker initialized")
	_logger.log_debug("  Heavy carry threshold: " + str(HEAVY_CARRY_THRESHOLD * 100) + "%")
	_logger.log_debug("  XP per meter: " + str(HEAVY_CARRY_XP_PER_METER))


func _process(_delta: float) -> void:
	"""Tracks player movement and emits signals for heavy carry XP."""
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or PlayerStats == null:
		return
	
	var current_position: Vector2 = player_node.global_position
	var current_weight: float = InventorySystem.get_current_carry_weight()
	var max_weight: float = MovementSystem.get_max_carry_weight()
	
	if max_weight <= 0:
		_heavy_carry_distance_accumulator = 0.0
		_last_player_position = current_position
		return
	
	var weight_percentage: float = current_weight / max_weight
	
	# Get threshold and XP rate from GameBalance config
	var threshold: float = GameBalance.get_heavy_carry_threshold()
	var xp_per_meter: float = GameBalance.get_heavy_carry_xp_per_meter()
	
	if weight_percentage >= threshold:
		# Track distance moved while carrying heavy load
		if _last_player_position != Vector2.ZERO:
			var distance_moved: float = current_position.distance_to(_last_player_position)
			# Accumulate distance and convert to XP (distance-based, lower rate)
			_heavy_carry_distance_accumulator += distance_moved * xp_per_meter
			if _heavy_carry_distance_accumulator >= 1.0:
				var xp_amount: float = _heavy_carry_distance_accumulator
				_heavy_carry_distance_accumulator = 0.0  # Reset after emitting
				_logger.log("Heavy carry moved: " + str(int(xp_amount)) + " XP (distance: " + str(snappedf(distance_moved, 0.1)) + "m, weight: " + str(snappedf(weight_percentage * 100, 0.1)) + "%)")
				heavy_carry_moved.emit(xp_amount, weight_percentage)
		# Always update position (even if first frame, for next frame's calculation)
		_last_player_position = current_position
	else:
		# Reset accumulator when not carrying heavy load, but keep tracking position
		_heavy_carry_distance_accumulator = 0.0
		_last_player_position = current_position
