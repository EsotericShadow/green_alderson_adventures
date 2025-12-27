extends Node
class_name EnemyRespawnManager
## Manages enemy respawning for testing purposes.
## Tracks spawn positions and respawns enemies after they die.

# Logging
var _logger = GameLogger.create("[EnemyRespawnManager] ")

# Respawn configuration
const RESPAWN_DELAY: float = 3.0  # Seconds before respawning

# Track enemy spawn data: { node_path: { scene: PackedScene, position: Vector2, scale: Vector2, z_index: int, parent: Node } }
var _enemy_spawns: Dictionary = {}


func _ready() -> void:
	_logger.log("EnemyRespawnManager initialized")
	_logger.log("  Respawn delay: " + str(RESPAWN_DELAY) + "s")
	# Wait a frame for all enemies to be in the scene
	await get_tree().process_frame
	_register_all_enemies()


func _register_all_enemies() -> void:
	"""Register all enemies in the scene for respawning."""
	var enemies = get_tree().get_nodes_in_group("enemy")
	_logger.log("Registering " + str(enemies.size()) + " enemies for respawning...")
	
	# Load the orc scene (all enemies are orcs for now)
	var orc_scene: PackedScene = load("res://scenes/enemies/orc_1.tscn")
	if orc_scene == null:
		_logger.log_error("Failed to load orc scene for respawning!")
		return
	
	for enemy in enemies:
		if enemy is BaseEnemy:
			var enemy_path: String = enemy.get_path()
			
			# Get z_index if enemy is a Node2D
			var z_index_value: int = 0
			if enemy is Node2D:
				z_index_value = enemy.z_index
			
			_enemy_spawns[enemy_path] = {
				"scene": orc_scene,
				"position": enemy.global_position,
				"scale": enemy.scale,
				"z_index": z_index_value,
				"parent": enemy.get_parent()
			}
			
			# Connect to death signal
			if not enemy.enemy_died.is_connected(_on_enemy_died):
				enemy.enemy_died.connect(_on_enemy_died.bind(enemy_path))
			
			_logger.log("  Registered: " + enemy.name + " at " + str(enemy.global_position) + " (z_index: " + str(z_index_value) + ")")


func _on_enemy_died(enemy_path: String) -> void:
	"""Called when an enemy dies - schedules respawn."""
	if not _enemy_spawns.has(enemy_path):
		_logger.log_error("Enemy died but not registered: " + enemy_path)
		return
	
	var spawn_data: Dictionary = _enemy_spawns[enemy_path]
	_logger.log("💀 Enemy died: " + enemy_path + " - respawning in " + str(RESPAWN_DELAY) + "s")
	
	# Schedule respawn
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_respawn_enemy(enemy_path, spawn_data)


func _respawn_enemy(enemy_path: String, spawn_data: Dictionary) -> void:
	"""Respawn an enemy at its original position."""
	var enemy_scene: PackedScene = spawn_data["scene"]
	var position: Vector2 = spawn_data["position"]
	var scale: Vector2 = spawn_data["scale"]
	var z_index_value: int = spawn_data.get("z_index", 0)
	var parent: Node = spawn_data["parent"]
	
	if parent == null:
		_logger.log_error("Cannot respawn - parent node is null for " + enemy_path)
		return
	
	if enemy_scene == null:
		_logger.log_error("Cannot respawn - enemy scene is null for " + enemy_path)
		return
	
	# Instantiate the enemy scene
	var new_enemy: Node = enemy_scene.instantiate()
	if new_enemy == null:
		_logger.log_error("Failed to instantiate enemy from scene for " + enemy_path)
		return
	
	# Set position, scale, and z_index
	if new_enemy is Node2D:
		new_enemy.global_position = position
		new_enemy.scale = scale
		new_enemy.z_index = z_index_value
	
	# Add to parent
	parent.add_child(new_enemy)
	
	# Re-register the new enemy
	if new_enemy is BaseEnemy:
		var new_path: String = new_enemy.get_path()
		_enemy_spawns[new_path] = spawn_data
		if not new_enemy.enemy_died.is_connected(_on_enemy_died):
			new_enemy.enemy_died.connect(_on_enemy_died.bind(new_path))
		
		_logger.log("✨ Respawned enemy: " + new_enemy.name + " at " + str(position) + " (z_index: " + str(z_index_value) + ")")
	else:
		_logger.log_error("Respawned node is not a BaseEnemy: " + str(new_enemy))

