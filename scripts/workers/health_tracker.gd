extends Node
class_name HealthTracker

## WORKER: Tracks health points
## Does ONE thing: manages HP value and reports changes
## Does NOT: apply knockback, trigger animations, make decisions

signal changed(current: int, maximum: int)
signal died(killer: Node)
signal damaged(amount: int, source: Node)

@export var max_health: int = 100

var current_health: int = 100
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health


## Take damage from a source
func take_damage(amount: int, source: Node = null) -> void:
	if is_dead:
		return
	
	current_health = max(0, current_health - amount)
	damaged.emit(amount, source)
	changed.emit(current_health, max_health)
	
	if current_health <= 0:
		is_dead = true
		died.emit(source)


## Heal by an amount
func heal(amount: int) -> void:
	if is_dead:
		return
	
	current_health = min(max_health, current_health + amount)
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

