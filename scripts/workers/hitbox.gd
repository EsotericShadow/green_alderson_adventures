extends Area2D
class_name Hitbox

## WORKER: Detects when this hitbox hits a hurtbox
## Does ONE thing: reports when it hits something
## Does NOT: decide when to attack, handle cooldowns

signal hit_landed(target: Node, damage: int)

@export var damage: int = 10
@export var knockback_force: float = 200.0  # More impact!

var owner_node: Node = null
var _logger: GameLogger.GameLoggerInstance


func _log(msg: String) -> void:
	_logger.log(msg)


func _ready() -> void:
	owner_node = get_parent()
	_logger = GameLogger.create("[" + owner_node.name + "/Hitbox] ")
	
	# Hitbox layer = 4, detects Hurtbox layer = 8
	collision_layer = 4
	collision_mask = 8
	
	# Start disabled
	monitoring = false
	monitorable = false
	
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		
		# Don't hit ourselves
		if hurtbox.owner_node == owner_node:
			# _log("Hit own hurtbox - ignoring")  # Commented out: enemy AI logging
			return
		
		# _log("💥 HIT! Target: " + (str(hurtbox.owner_node.name) if hurtbox.owner_node != null else "unknown") + ", Damage: " + str(damage))  # Commented out: enemy AI logging (health changes logged in PlayerStats)
		
		# Calculate knockback direction
		var knockback_dir := Vector2.ZERO
		if hurtbox.owner_node != null and owner_node != null:
			knockback_dir = (hurtbox.owner_node.global_position - owner_node.global_position).normalized()
		
		var knockback := knockback_dir * knockback_force
		# _log("   Knockback: " + str(knockback))  # Commented out: enemy AI logging
		
		hurtbox.receive_hit(damage, knockback, owner_node)
		hit_landed.emit(hurtbox.owner_node, damage)


## Enable the hitbox (call when attack animation hits)
func enable() -> void:
	# _log("⚔️ ENABLED")  # Commented out: enemy AI logging
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


## Disable the hitbox
func disable() -> void:
	# _log("⚔️ disabled")  # Commented out: enemy AI logging
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


## Enable for a short duration then auto-disable
func enable_for(duration: float) -> void:
	# _log("⚔️ ENABLED for " + str(duration) + "s")  # Commented out: enemy AI logging
	enable()
	get_tree().create_timer(duration).timeout.connect(disable)
