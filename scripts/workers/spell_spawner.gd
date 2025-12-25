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
func spawn_fireball(direction: String, spawn_pos: Vector2, z_index_value: int, spell_data: SpellData = null) -> Node:
	_log("🔥 Spawning projectile...")
	_log("   Direction: " + direction)
	_log("   Position: " + str(spawn_pos))
	_log("   Z-index: " + str(z_index_value))
	
	# Determine which projectile scene to use based on element
	var projectile_scene: PackedScene = null
	if spell_data != null:
		match spell_data.element:
			"fire":
				projectile_scene = load("res://scenes/projectiles/fireball.tscn") as PackedScene
			"water":
				projectile_scene = load("res://scenes/projectiles/waterball.tscn") as PackedScene
			"earth":
				projectile_scene = load("res://scenes/projectiles/earthball.tscn") as PackedScene
			"air":
				projectile_scene = load("res://scenes/projectiles/airball.tscn") as PackedScene
		
		if projectile_scene != null:
			_log("   Using element-specific projectile: " + spell_data.element)
		else:
			_log("   ⚠️ Element-specific scene not found, using fallback")
	
	# Fallback to fireball_scene if element-specific scene not found
	if projectile_scene == null:
		projectile_scene = fireball_scene
	
	if projectile_scene == null:
		_log_error("No projectile scene available! Cannot spawn.")
		return null
	
	var fb: Node = null
	
	# Only use pool if we're using the default fireball scene (pool only has fireballs)
	# For element-specific projectiles, always instantiate directly
	var use_pool: bool = (pool != null and pool.has_method("get_fireball") and 
	                      spell_data != null and spell_data.element == "fire" and
	                      projectile_scene == fireball_scene)
	
	if use_pool:
		_log("   Source: Pool (fireball)")
		fb = pool.get_fireball()
		if fb == null:
			_log_error("Pool.get_fireball() returned null!")
			return null
		var parent := fb.get_parent()
		if parent != null:
			parent.remove_child(fb)
		get_tree().current_scene.add_child(fb)
	else:
		_log("   Source: Instantiate (element-specific)")
		fb = projectile_scene.instantiate()
		get_tree().current_scene.add_child(fb)
	
	fb.global_position = spawn_pos
	
	var dir_vec := _dir_to_vector(direction)
	_log("   Direction vector: " + str(dir_vec))
	
	if fb.has_method("setup"):
		fb.call("setup", dir_vec, owner_node, z_index_value, spell_data)
		_log("   ✓ Projectile setup() called")
		if spell_data != null:
			_log("   ✓ SpellData provided: " + spell_data.display_name + " (" + spell_data.element + ")")
	else:
		fb.z_index = z_index_value
		_log("   ⚠️ Projectile has no setup() method - set z_index directly")
	
	_log("   ✓ Projectile spawned successfully!")
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

