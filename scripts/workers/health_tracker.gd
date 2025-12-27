extends Node
class_name HealthTracker

## WORKER: Tracks health points
## Does ONE thing: manages HP value and reports changes
## Does NOT: apply knockback, trigger animations, make decisions

# Logging
var _logger: GameLogger.GameLoggerInstance

signal changed(current: int, maximum: int)
signal died(killer: Node)
signal damaged(amount: int, source: Node)

@export var max_health: int = 100

var current_health: int = 100
var is_dead: bool = false


func _ready() -> void:
	_logger = GameLogger.create("[" + get_parent().name + "/HealthTracker] ")
	current_health = max_health
	_logger.log("HealthTracker initialized: " + str(current_health) + "/" + str(max_health) + " HP")


## Take damage from a source
func take_damage(amount: int, source: Node = null) -> void:
	if is_dead:
		return
	
	var old_health: int = current_health
	current_health = max(0, current_health - amount)
	var source_name: String = "unknown"
	if source != null:
		source_name = source.name
	_logger.log("Taking damage: " + str(amount) + " from " + source_name + " (" + str(old_health) + " → " + str(current_health) + "/" + str(max_health) + ")")
	damaged.emit(amount, source)
	changed.emit(current_health, max_health)
	
	if current_health <= 0:
		is_dead = true
		_logger.log("💀 Entity died! Killed by: " + source_name)
		died.emit(source)


## Heal by an amount
func heal(amount: int) -> void:
	if is_dead:
		return
	
	var old_health: int = current_health
	current_health = min(max_health, current_health + amount)
	_logger.log("Healed: +" + str(amount) + " (" + str(old_health) + " → " + str(current_health) + "/" + str(max_health) + ")")
	changed.emit(current_health, max_health)


## Reset to full health
func reset() -> void:
	is_dead = false
	current_health = max_health
	changed.emit(current_health, max_health)


## Set max health (also resets current to max)
func set_max_health(value: int) -> void:
	max_health = value
	current_health = max_health
	changed.emit(current_health, max_health)


## Get current health percentage (0.0 to 1.0)
func get_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)
