extends Node
class_name Mover

## WORKER: Moves a CharacterBody2D
## Does ONE thing: applies velocity and calls move_and_slide
## Does NOT: decide direction, read input, make any decisions

# Logging
var _logger: GameLogger.GameLoggerInstance

var body: CharacterBody2D = null
var current_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 8.0  # Slower decay = more impactful knockback


func _ready() -> void:
	body = get_parent() as CharacterBody2D
	if body == null:
		push_error("Mover: Parent must be CharacterBody2D")
		return
	_logger = GameLogger.create("[" + body.name + "/Mover] ")
	_logger.log("Mover initialized")


func _physics_process(delta: float) -> void:
	if body == null:
		return
	
	# Decay knockback
	if knockback_velocity.length() > 1.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
	else:
		knockback_velocity = Vector2.ZERO
	
	# Apply movement
	body.velocity = current_velocity + knockback_velocity
	body.move_and_slide()


## Tell the mover to move in a direction at a speed
func move(direction: Vector2, speed: float) -> void:
	if direction.length() > 0.0:
		current_velocity = direction.normalized() * speed
	else:
		current_velocity = Vector2.ZERO


## Stop all voluntary movement
func stop() -> void:
	current_velocity = Vector2.ZERO


## Apply knockback force
func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force
	_logger.log("Knockback applied: " + str(force))


## Check if currently moving (voluntary movement, not knockback)
func is_moving() -> bool:
	return current_velocity.length() > 1.0


## Get the current movement direction
func get_direction() -> Vector2:
	if current_velocity.length() > 0.0:
		return current_velocity.normalized()
	return Vector2.ZERO

