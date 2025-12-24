extends Area2D

@export var speed: float = 500.0  # Faster, more responsive
@export var lifetime: float = 1.5
@export var damage: int = 25  # Damage dealt to enemies
@export var impact_scene: PackedScene

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var visibility_notifier: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D")

var velocity: Vector2 = Vector2.ZERO
var travel_dir: Vector2 = Vector2.RIGHT
var owner_node: Node = null  # Track who shot this fireball
var signals_connected := false
var lifetime_timer: float = 0.0
var pool_manager: ProjectilePool = null  # Reference to pool for returning
var is_active := false


func _ready() -> void:
	# Connect collision signals once (optimized - best practice)
	if not signals_connected:
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)
		signals_connected = true
	
	# Set collision mask to detect terrain/walls (layer 1) and hurtboxes (layer 8)
	collision_mask = 9  # Layer 1 (terrain) + Layer 8 (hurtbox) = 1 + 8 = 9
	
	# Connect visibility notifier for off-screen culling (best practice)
	if visibility_notifier != null:
		if not visibility_notifier.screen_exited.is_connected(_on_screen_exited):
			visibility_notifier.screen_exited.connect(_on_screen_exited)
	
	# Find pool manager in scene tree
	_find_pool_manager()
	
	if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("fireball"):
		anim.flip_h = false
		anim.rotation = 0.0
		anim.play("fireball")


func _find_pool_manager() -> void:
	# Look for pool manager in scene tree (best practice: singleton or scene root)
	var current_scene = get_tree().current_scene
	if current_scene != null:
		pool_manager = current_scene.get_node_or_null("ProjectilePool")
		if pool_manager == null:
			# Try finding it anywhere in the scene
			pool_manager = current_scene.find_child("ProjectilePool", true, false)


# Called by Player right after instancing (or when getting from pool)
func setup(dir_vec: Vector2, shooter: Node = null, z_index_override: int = -1) -> void:
	travel_dir = dir_vec.normalized()
	velocity = travel_dir * speed
	owner_node = shooter
	lifetime_timer = lifetime
	is_active = true

	# Rotate the whole projectile so the "right-facing" sprite points where it's traveling
	# (Rotate the node, not just the sprite: keeps collision aligned too.)
	rotation = travel_dir.angle()
	
	# Set z_index if provided (for directional spawning)
	if z_index_override >= 0:
		z_index = z_index_override
		if anim != null:
			anim.z_index = z_index_override
	
	# Reset animation
	if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("fireball"):
		anim.play("fireball")


func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	position += velocity * delta
	
	# Manual lifetime management (better than timer for pooling)
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		_deactivate()


func _on_body_entered(body: Node) -> void:
	# Don't collide with the player who shot it
	if body == owner_node or body.is_in_group("player"):
		return
	
	# Deal damage to enemies
	_deal_damage_to(body)
	
	_spawn_impact()
	_deactivate()


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	
	# Don't collide with other fireballs
	if area.is_in_group("fireball"):
		return
	
	# Check if this is a hurtbox
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		
		# IGNORE player hurtbox entirely (don't hit ourselves!)
		if hurtbox.owner_node == owner_node or hurtbox.owner_node.is_in_group("player"):
			return  # <-- IMPORTANT: Don't fall through!
		
		# Hit enemy hurtbox
		hurtbox.receive_hit(damage, travel_dir * 150.0, owner_node)
		_spawn_impact()
		_deactivate()
		return
	
	# Only deactivate on terrain/walls, not on random areas
	# Check if it's a static body area (terrain)
	if area.collision_layer & 1:  # Layer 1 = terrain
		_spawn_impact()
		_deactivate()


func _on_screen_exited() -> void:
	# Best practice: deactivate off-screen projectiles to save resources
	_deactivate()


func _deactivate() -> void:
	if not is_active:
		return
	
	is_active = false
	
	# Return to pool if available, otherwise free
	if pool_manager != null:
		if pool_manager.has_method("return_fireball"):
			pool_manager.return_fireball(self)
		else:
			queue_free()
	else:
		queue_free()


func _deal_damage_to(body: Node) -> void:
	"""Deal damage to a body if it has a take_damage method or is an enemy"""
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage, owner_node)
	elif body.has_method("take_damage"):
		body.take_damage(damage, owner_node)


func _spawn_impact() -> void:
	# Calculate impact position at the edge of collision shape in travel direction
	var collision_radius := 25.0  # Match fireball collision shape radius
	var impact_offset := travel_dir * collision_radius
	var impact_position := global_position + impact_offset
	
	print("[Fireball] 💥 Spawning impact at " + str(impact_position) + " (fireball was at " + str(global_position) + ")")
	var fx: Node
	
	# Use pool if available (best practice)
	if pool_manager != null and pool_manager.has_method("get_impact"):
		fx = pool_manager.get_impact()
		print("[Fireball]    Source: Pool")
		# Reparent from pool to scene
		var current_parent = fx.get_parent()
		if current_parent != null:
			current_parent.remove_child(fx)
		get_tree().current_scene.add_child(fx)
		fx.global_position = impact_position
	elif impact_scene != null:
		# Fallback to instantiation
		fx = impact_scene.instantiate()
		print("[Fireball]    Source: Instantiate")
		get_tree().current_scene.add_child(fx)
		fx.global_position = impact_position
	else:
		print("[Fireball]    ❌ No pool or impact_scene available!")
		return

	# We want the impact to orient based on the direction the fireball traveled.
	var desired_dir := -travel_dir  # point toward where it came from
	var desired_angle := desired_dir.angle()

	if fx.has_method("setup"):
		fx.call("setup", desired_angle)
		print("[Fireball]    ✓ Impact setup() called")
	else:
		fx.rotation = desired_angle
		print("[Fireball]    Impact has no setup(), set rotation directly")
