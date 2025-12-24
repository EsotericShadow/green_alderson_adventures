extends Node
class_name ProjectilePool

# Object pooling system for projectiles - best practice for performance
# Reuses projectiles instead of constantly instantiating/destroying them

@export var pool_size: int = 20
@export var fireball_scene: PackedScene
@export var impact_scene: PackedScene

var fireball_pool: Array[Node] = []
var impact_pool: Array[Node] = []
var active_fireballs: Array[Node] = []
var active_impacts: Array[Node] = []


func _ready() -> void:
	# Pre-instantiate projectiles for better performance
	if fireball_scene != null:
		_preload_fireballs()
	if impact_scene != null:
		_preload_impacts()


func _preload_fireballs() -> void:
	for i in range(pool_size):
		var fireball := fireball_scene.instantiate()
		fireball.set_process(false)
		fireball.set_physics_process(false)
		fireball.visible = false
		add_child(fireball)
		fireball_pool.append(fireball)


func _preload_impacts() -> void:
	# Smaller pool for impacts since they're shorter-lived
	for i in range(int(pool_size / 2.0)):
		var impact := impact_scene.instantiate()
		impact.set_process(false)
		impact.visible = false
		add_child(impact)
		impact_pool.append(impact)


func get_fireball() -> Node:
	var fireball: Node
	
	if fireball_pool.is_empty():
		# Pool exhausted, create new one (shouldn't happen often)
		fireball = fireball_scene.instantiate()
		add_child(fireball)
	else:
		fireball = fireball_pool.pop_back()
	
	# Reset and activate
	fireball.set_process(true)
	fireball.set_physics_process(true)
	fireball.visible = true
	active_fireballs.append(fireball)
	
	return fireball


func return_fireball(fireball: Node) -> void:
	if fireball == null:
		return
	
	# Check if it's in active list (use find instead of has for Array)
	var index := active_fireballs.find(fireball)
	if index == -1:
		return
	
	active_fireballs.remove_at(index)
	
	# Remove from current parent and return to pool
	var current_parent = fireball.get_parent()
	if current_parent != null and current_parent != self:
		current_parent.remove_child(fireball)
	
	# Make sure it's our child
	if fireball.get_parent() != self:
		add_child(fireball)
	
	# Reset state
	fireball.set_process(false)
	fireball.set_physics_process(false)
	fireball.visible = false
	fireball.position = Vector2.ZERO
	fireball.rotation = 0.0
	fireball.z_index = 2  # Reset to default z_index
	
	# Reset velocity if accessible (fireball.gd has this property)
	# Access the property directly since it's defined in fireball.gd
	if "velocity" in fireball:
		fireball.velocity = Vector2.ZERO
	
	# Reset sprite z_index if it exists
	var sprite = fireball.get_node_or_null("AnimatedSprite2D")
	if sprite != null:
		sprite.z_index = 2
	
	# Return to pool
	fireball_pool.append(fireball)


func get_impact() -> Node:
	var impact: Node
	
	if impact_pool.is_empty():
		impact = impact_scene.instantiate()
		add_child(impact)
	else:
		impact = impact_pool.pop_back()
	
	impact.visible = true
	active_impacts.append(impact)
	
	return impact


func return_impact(impact: Node) -> void:
	if impact == null:
		return
	
	# Check if it's in active list
	var index := active_impacts.find(impact)
	if index == -1:
		return
	
	active_impacts.remove_at(index)
	
	# Remove from current parent and return to pool
	var current_parent = impact.get_parent()
	if current_parent != null and current_parent != self:
		current_parent.remove_child(impact)
	
	# Make sure it's our child
	if impact.get_parent() != self:
		add_child(impact)
	
	impact.visible = false
	impact.position = Vector2.ZERO
	impact.rotation = 0.0
	impact_pool.append(impact)
