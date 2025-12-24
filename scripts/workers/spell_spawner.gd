extends Node
class_name SpellSpawner

## WORKER: Spawns projectiles
## Does ONE thing: creates and positions projectiles
## Does NOT: handle cooldowns, decide when to cast

@export var fireball_scene: PackedScene

var owner_node: Node2D = null
var pool: Node = null  # ProjectilePool reference

var _log_prefix := "[SpellSpawner] "


func _log(msg: String) -> void:
	print(_log_prefix + msg)


func _log_error(msg: String) -> void:
	push_error(_log_prefix + "ERROR: " + msg)
	print(_log_prefix + "❌ ERROR: " + msg)


func _ready() -> void:
	_log_prefix = "[" + get_parent().name + "/SpellSpawner] "
	owner_node = get_parent() as Node2D
	_find_pool()
	
	if fireball_scene == null:
		_log("⚠️ No fireball_scene assigned - will need pool")
	else:
		_log("✓ Fireball scene ready")


func _find_pool() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		pool = scene.get_node_or_null("ProjectilePool")
		if pool == null:
			pool = scene.find_child("ProjectilePool", true, false)
	
	if pool != null:
		_log("✓ ProjectilePool found")
	else:
		_log("⚠️ No ProjectilePool found - will instantiate directly")


## Spawn a fireball in the given direction
## Returns the spawned fireball node
func spawn_fireball(direction: String, spawn_pos: Vector2, z_index_value: int) -> Node:
	_log("🔥 Spawning fireball...")
	_log("   Direction: " + direction)
	_log("   Position: " + str(spawn_pos))
	_log("   Z-index: " + str(z_index_value))
	
	var fb: Node = null
	
	# Try pool first
	if pool != null and pool.has_method("get_fireball"):
		_log("   Source: Pool")
		fb = pool.get_fireball()
		if fb == null:
			_log_error("Pool.get_fireball() returned null!")
			return null
		var parent := fb.get_parent()
		if parent != null:
			parent.remove_child(fb)
		get_tree().current_scene.add_child(fb)
	elif fireball_scene != null:
		_log("   Source: Instantiate")
		fb = fireball_scene.instantiate()
		get_tree().current_scene.add_child(fb)
	else:
		_log_error("No fireball scene AND no pool available! Cannot spawn.")
		return null
	
	fb.global_position = spawn_pos
	
	var dir_vec := _dir_to_vector(direction)
	_log("   Direction vector: " + str(dir_vec))
	
	if fb.has_method("setup"):
		fb.call("setup", dir_vec, owner_node, z_index_value)
		_log("   ✓ Fireball setup() called")
	else:
		fb.z_index = z_index_value
		_log("   ⚠️ Fireball has no setup() method - set z_index directly")
	
	_log("   ✓ Fireball spawned successfully!")
	return fb


func _dir_to_vector(d: String) -> Vector2:
	match d:
		"right": return Vector2.RIGHT
		"left": return Vector2.LEFT
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"ne": return Vector2(1, -1).normalized()
		"nw": return Vector2(-1, -1).normalized()
		"se": return Vector2(1, 1).normalized()
		"sw": return Vector2(-1, 1).normalized()
		_: return Vector2.DOWN

