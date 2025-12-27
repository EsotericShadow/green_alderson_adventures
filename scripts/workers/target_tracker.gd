extends Node
class_name TargetTracker

## WORKER: Tracks a target node
## Does ONE thing: provides info about target position/distance
## Does NOT: decide to chase, trigger attacks, manage AI state

# Logging
var _logger: GameLogger.GameLoggerInstance

signal target_acquired(target: Node2D)
signal target_lost

@export var detection_range: float = 200.0
@export var lose_range: float = 250.0  # Lose target if they go beyond this

var target: Node2D = null
var owner_node: Node2D = null
var spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	owner_node = get_parent() as Node2D
	if owner_node != null:
		spawn_position = owner_node.global_position
		_logger = GameLogger.create("[" + owner_node.name + "/TargetTracker] ")
		_logger.log("TargetTracker initialized (detection: " + str(detection_range) + ", lose: " + str(lose_range) + ")")


## Set the target to track
func set_target(new_target: Node2D) -> void:
	if target != new_target:
		target = new_target
		if target != null:
			_logger.log("Target acquired: " + target.name)
			target_acquired.emit(target)


## Clear the current target
func clear_target() -> void:
	if target != null:
		_logger.log("Target lost")
		target = null
		target_lost.emit()


## Check if we have a valid target
func has_target() -> bool:
	if target == null:
		return false
	if not is_instance_valid(target):
		target = null
		return false
	return true


## Get direction toward target (normalized)
func get_direction_to_target() -> Vector2:
	if not has_target() or owner_node == null:
		return Vector2.ZERO
	return (target.global_position - owner_node.global_position).normalized()


## Get distance to target
func get_distance_to_target() -> float:
	if not has_target() or owner_node == null:
		return 999999.0
	return owner_node.global_position.distance_to(target.global_position)


## Get direction back to spawn
func get_direction_to_spawn() -> Vector2:
	if owner_node == null:
		return Vector2.ZERO
	return (spawn_position - owner_node.global_position).normalized()


## Get distance to spawn
func get_distance_to_spawn() -> float:
	if owner_node == null:
		return 0.0
	return owner_node.global_position.distance_to(spawn_position)


## Check if at spawn position (within threshold)
func is_at_spawn(threshold: float = 5.0) -> bool:
	return get_distance_to_spawn() < threshold


## Check if target is too far (beyond lose_range)
func is_target_too_far() -> bool:
	return get_distance_to_target() > lose_range

