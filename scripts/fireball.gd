extends Area2D

@export var speed: float = 450.0
@export var lifetime: float = 1.5
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
	
	# Set collision mask to detect terrain/walls (layer 1)
	collision_mask = 1
	
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
	
	_spawn_impact()
	_deactivate()


func _on_area_entered(area: Area2D) -> void:
	# Don't collide with other fireballs (check by group for better performance)
	if area.is_in_group("fireball"):
		return
	
	# Handle collisions with Area2D nodes (like terrain areas)
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


func _spawn_impact() -> void:
	if impact_scene == null:
		return

	var fx: Node
	
	# Use pool if available (best practice)
	if pool_manager != null and pool_manager.has_method("get_impact"):
		fx = pool_manager.get_impact()
		fx.global_position = global_position
	else:
		# Fallback to instantiation
		fx = impact_scene.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position

	# We want the impact to orient based on the direction the fireball traveled.
	# Your impact animation is "impact_left" (points LEFT).
	# So we rotate it so LEFT points opposite the travel direction (i.e., it "faces" the hit).
	# If you prefer it to face the travel direction, flip the sign below.
	var desired_dir := -travel_dir  # point toward where it came from (looks like it hit the surface)
	var desired_angle := desired_dir.angle()

	if fx.has_method("setup"):
		fx.call("setup", desired_angle)
	else:
		# Fallback: rotate the impact node directly
		fx.rotation = desired_angle
