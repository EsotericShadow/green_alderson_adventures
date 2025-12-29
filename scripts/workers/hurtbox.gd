extends BaseAreaWorker
class_name Hurtbox

## WORKER: Receives hits from hitboxes
## Does ONE thing: reports when it gets hit
## Does NOT: apply damage to health, trigger animations

signal hurt(damage: int, knockback: Vector2, attacker: Node)

@export var invincibility_time: float = 0.5

var is_invincible: bool = false
var _blink_tween: Tween = null  # Track our own tween


func _on_initialize() -> void:
	"""Initialize hurtbox - set collision layers."""
	# Hurtbox layer = 8, doesn't detect anything (gets detected by hitboxes)
	collision_layer = 8
	collision_mask = 0
	
	monitoring = false
	monitorable = true


## Called by Hitbox when it hits us
func receive_hit(damage: int, knockback: Vector2, attacker: Node) -> void:
	if is_invincible:
		# _log("🛡️ Hit received but INVINCIBLE - ignoring (from " + (str(attacker.name) if attacker != null else "unknown") + ")")  # Commented out: enemy AI logging
		return
	
	# _log("💥 HIT RECEIVED! Damage: " + str(damage) + " from " + (str(attacker.name) if attacker != null else "unknown"))  # Commented out: enemy AI logging (health changes logged in PlayerStats)
	# _log("   Emitting 'hurt' signal...")  # Commented out: enemy AI logging
	
	hurt.emit(damage, knockback, attacker)
	
	if invincibility_time > 0.0:
		_start_invincibility()


func _start_invincibility() -> void:
	# _log("🛡️ Invincibility START (" + str(invincibility_time) + "s)")  # Commented out: enemy AI logging
	is_invincible = true
	_start_blink()
	get_tree().create_timer(invincibility_time).timeout.connect(_end_invincibility)


func _end_invincibility() -> void:
	# _log("🛡️ Invincibility END")  # Commented out: enemy AI logging
	is_invincible = false
	_stop_blink()


func _start_blink() -> void:
	if owner_node == null:
		return
	var sprite := owner_node.get_node_or_null("AnimatedSprite2D")
	if sprite != null:
		# Kill previous blink tween if exists
		if _blink_tween != null and _blink_tween.is_valid():
			_blink_tween.kill()
		_blink_tween = create_tween()
		_blink_tween.set_loops()
		_blink_tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
		_blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.1)


func _stop_blink() -> void:
	# Kill only OUR blink tween
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
		_blink_tween = null
	
	# Reset sprite visibility
	if owner_node == null:
		return
	var sprite := owner_node.get_node_or_null("AnimatedSprite2D")
	if sprite != null:
		sprite.modulate.a = 1.0


## Enable the hurtbox
func enable() -> void:
	set_deferred("monitorable", true)


## Disable the hurtbox (for death, etc.)
func disable() -> void:
	set_deferred("monitorable", false)
