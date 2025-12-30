class_name AreaDamageWorker
extends RefCounted
## Worker that handles area damage detection and application.
## Instantiated by PotionConsumptionHandler when area damage effects are triggered.

# Logging
var _logger = GameLogger.create("[AreaDamageWorker] ")

## Deals area damage to all enemies in radius around center point.
## 
## Args:
##   center: Center point of area damage (player position)
##   radius: Radius of area damage in pixels
##   damage: Damage amount to deal
##   damage_type: Type of damage (for logging/future resistance system)
func deal_area_damage(center: Vector2, radius: float, damage: int, damage_type: String = "magic", scene_tree: SceneTree = null) -> void:
	if scene_tree == null:
		_logger.log_error("deal_area_damage() called with null scene_tree")
		return
	
	_logger.log("Dealing area damage: " + str(damage) + " " + damage_type + " damage at " + str(center) + " (radius: " + str(radius) + ")")
	
	# Get all enemies in scene
	var enemies = scene_tree.get_nodes_in_group(GameConstants.GROUP_ENEMY)
	var hit_count: int = 0
	
	for enemy in enemies:
		if not enemy is BaseEnemy:
			continue
		
		var enemy_pos: Vector2 = enemy.global_position
		var distance: float = center.distance_to(enemy_pos)
		
		if distance <= radius:
			enemy.take_damage(damage, null)  # Source is null (potion effect)
			hit_count += 1
			_logger.log("  Hit enemy: " + enemy.name + " at distance " + str(int(distance)))
	
	_logger.log("Area damage complete: hit " + str(hit_count) + " enemies")

