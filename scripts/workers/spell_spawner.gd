extends BaseWorker
class_name SpellSpawner

## WORKER: Spawns projectiles
## Does ONE thing: creates and positions projectiles
## Does NOT: handle cooldowns, decide when to cast

@export var fireball_scene: PackedScene

var pool: Node = null  # ProjectilePool reference


func _on_initialize() -> void:
	"""Initialize spell spawner - find projectile pool."""
	_find_pool()


func _find_pool() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		pool = scene.get_node_or_null("ProjectilePool")
		if pool == null:
			pool = scene.find_child("ProjectilePool", true, false)
	
	if pool != null:
		# _log("✓ ProjectilePool found")  # Commented out: spell casting logging
		pass
	else:
		pass  # _log("⚠️ No ProjectilePool found - will instantiate directly")  # Commented out: spell casting logging


## Spawn a fireball in the given direction
## Returns the spawned fireball node
func spawn_fireball(direction: String, spawn_pos: Vector2, z_index_value: int, spell_data: SpellData = null) -> Node:
	# _log("🔥 Spawning projectile...")  # Commented out: spell casting logging
	# _log("   Direction: " + direction)  # Commented out: spell casting logging
	# _log("   Position: " + str(spawn_pos))  # Commented out: spell casting logging
	# _log("   Z-index: " + str(z_index_value))  # Commented out: spell casting logging
	
	# Load projectile scene from SpellData (data-driven approach)
	var projectile_scene: PackedScene = null
	if spell_data != null and not spell_data.projectile_scene_path.is_empty():
		projectile_scene = ResourceManager.load_scene(spell_data.projectile_scene_path)
	
	# Fallback to fireball_scene if path is empty or load fails
	if projectile_scene == null:
		projectile_scene = fireball_scene
	
	if projectile_scene == null:
		_logger.log_error("No projectile scene available! Cannot spawn.")
		return null
	
	var fb: Node = null
	
	# Only use pool if we're using the default fireball scene (pool only has fireballs)
	# For element-specific projectiles, always instantiate directly
	var use_pool: bool = (pool != null and pool.has_method("get_fireball") and 
	                      spell_data != null and spell_data.element == "fire" and
	                      projectile_scene == fireball_scene)
	
	if use_pool:
		# _log("   Source: Pool (fireball)")  # Commented out: spell casting logging
		fb = pool.get_fireball()
		if fb == null:
			_logger.log_error("Pool.get_fireball() returned null!")
			return null
		var parent := fb.get_parent()
		if parent != null:
			parent.remove_child(fb)
		get_tree().current_scene.add_child(fb)
	else:
		# _log("   Source: Instantiate (element-specific)")  # Commented out: spell casting logging
		fb = projectile_scene.instantiate()
		get_tree().current_scene.add_child(fb)
	
	fb.global_position = spawn_pos
	
	var dir_vec := DirectionUtils.dir_to_vector(direction)
	# _log("   Direction vector: " + str(dir_vec))  # Commented out: spell casting logging
	
	if fb.has_method("setup"):
		fb.call("setup", dir_vec, owner_node, z_index_value, spell_data)
		# _log("   ✓ Projectile setup() called")  # Commented out: spell casting logging
		# if spell_data != null:
		# 	_log("   ✓ SpellData provided: " + spell_data.display_name + " (" + spell_data.element + ")")  # Commented out: spell casting logging
	else:
		fb.z_index = z_index_value
		# _log("   ⚠️ Projectile has no setup() method - set z_index directly")  # Commented out: spell casting logging
	
	# _log("   ✓ Projectile spawned successfully!")  # Commented out: spell casting logging
	return fb



