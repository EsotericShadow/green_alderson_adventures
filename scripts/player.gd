extends CharacterBody2D

@export var walk_speed := 120.0
@export var run_speed  := 220.0

@export var fireball_scene: PackedScene
@onready var fire_point: Marker2D = get_node_or_null("FirePoint")

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var projectile_pool: ProjectilePool = null

var last_dir := "down"
var is_action_locked := false
var fireball_cooldown_timer: float = 0.0
var fireball_cooldown: float = 0.8  # Cooldown in seconds


func _ready() -> void:
	if anim == null:
		push_error("Player.gd: Couldn't find child node 'AnimatedSprite2D'.")
		set_process(false)
		set_physics_process(false)
	
	# Find projectile pool (best practice: use pooling for performance)
	_find_projectile_pool()


func _find_projectile_pool() -> void:
	var current_scene = get_tree().current_scene
	if current_scene != null:
		projectile_pool = current_scene.get_node_or_null("ProjectilePool")
		if projectile_pool == null:
			projectile_pool = current_scene.find_child("ProjectilePool", true, false)


func _physics_process(delta: float) -> void:
	if anim == null:
		return
	
	# Update cooldown timer
	if fireball_cooldown_timer > 0.0:
		fireball_cooldown_timer -= delta

	var input_vec := Vector2(
		Input.get_action_strength("move_east") - Input.get_action_strength("move_west"),
		Input.get_action_strength("move_south") - Input.get_action_strength("move_north")
	)

	if input_vec.length() > 0.0:
		input_vec = input_vec.normalized()

	var wants_run := (
		Input.is_action_pressed("run_north")
		or Input.is_action_pressed("run_south")
		or Input.is_action_pressed("run_east")
		or Input.is_action_pressed("run_west")
	)

	if InputMap.has_action("run") and Input.is_action_pressed("run"):
		wants_run = true

	# Cast fireball - allow casting while moving and multiple casts
	if Input.is_action_just_pressed("spell_1") and _can_cast_fireball():
		# Use current movement direction if moving, otherwise use last direction
		var cast_dir := last_dir
		if input_vec.length() > 0.0:
			cast_dir = _vector_to_dir8(input_vec)
		
		# Play cast animation (allows movement but prevents movement anims from overriding)
		_play_cast_animation("fireball_" + cast_dir)
		# Delay fireball launch by 0.5 seconds
		var timer := get_tree().create_timer(0.5)
		# Capture direction at cast time, but allow it to update if player moves
		var dir := cast_dir
		timer.timeout.connect(_spawn_fireball.bind(dir))

	# Run-jump example
	if Input.is_action_just_pressed("jump") and not is_action_locked and wants_run and input_vec.length() > 0.0:
		last_dir = _vector_to_dir8(input_vec)
		_play_one_shot("run_jump_" + last_dir)
		return

	# Check if we're actively playing a fireball cast animation
	var is_fireball_anim := false
	if anim != null and anim.animation != null:
		is_fireball_anim = anim.animation.begins_with("fireball_") and anim.is_playing()
	
	# Only lock movement for non-fireball animations (like jump)
	if is_action_locked and not is_fireball_anim:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var speed := run_speed if wants_run else walk_speed
	velocity = input_vec * speed
	move_and_slide()

	# Only play movement animations if not in a fireball cast animation
	if not is_fireball_anim:
		if input_vec.length() > 0.0:
			last_dir = _vector_to_dir8(input_vec)
			_play_loop(("run_" if wants_run else "walk_") + last_dir)
		else:
			_play_loop("idle_" + last_dir)


func _can_cast_fireball() -> bool:
	return fireball_cooldown_timer <= 0.0


func _is_facing_north(dir_name: String) -> bool:
	# Check if facing north, northeast, or northwest
	return dir_name == "up" or dir_name == "ne" or dir_name == "nw"


func _spawn_fireball(dir_name: String) -> void:
	if fireball_scene == null:
		push_warning("Player.gd: Assign fireball_scene in the Inspector.")
		return
	
	# Set cooldown
	fireball_cooldown_timer = fireball_cooldown

	var fb: Node
	
	# Use pool if available (best practice for performance)
	if projectile_pool != null and projectile_pool.has_method("get_fireball"):
		fb = projectile_pool.get_fireball()
		# Reparent to current scene (remove from pool first)
		var current_parent = fb.get_parent()
		if current_parent != null:
			current_parent.remove_child(fb)
		get_tree().current_scene.add_child(fb)
	else:
		# Fallback to instantiation
		fb = fireball_scene.instantiate()
		get_tree().current_scene.add_child(fb)

	var spawn_pos := global_position
	if fire_point != null:
		spawn_pos = fire_point.global_position
	fb.global_position = spawn_pos

	# Set z_index based on direction: below player when facing north, above when facing south/sides
	var z_index_value := 2  # Default above player
	if _is_facing_north(dir_name):
		z_index_value = 1  # Below player but above tilemap

	var dir_vec := _dir_to_vector(dir_name).normalized()

	# Hand off direction to projectile with z_index
	if fb.has_method("setup"):
		fb.call("setup", dir_vec, self, z_index_value)  # Pass self as shooter and z_index
	else:
		# Fallback: set z_index directly
		fb.z_index = z_index_value
		var sprite = fb.get_node_or_null("AnimatedSprite2D")
		if sprite != null:
			sprite.z_index = z_index_value


func _dir_to_vector(d: String) -> Vector2:
	match d:
		"right": return Vector2.RIGHT
		"left": return Vector2.LEFT
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"ne": return Vector2(1, -1)
		"nw": return Vector2(-1, -1)
		"se": return Vector2(1, 1)
		"sw": return Vector2(-1, 1)
		_: return Vector2.DOWN


func _vector_to_dir8(v: Vector2) -> String:
	var deg := rad_to_deg(atan2(v.y, v.x))
	deg = fposmod(deg + 22.5, 360.0)

	if deg < 45.0: return "right"
	elif deg < 90.0: return "se"
	elif deg < 135.0: return "down"
	elif deg < 180.0: return "sw"
	elif deg < 225.0: return "left"
	elif deg < 270.0: return "nw"
	elif deg < 315.0: return "up"
	else: return "ne"


# ---- Animation helpers (your player directional anims) ----

func _resolve_anim_and_flip(anim_name: String) -> Dictionary:
	# All 8 directions exist, no flipping needed
	return {"name": anim_name, "flip_h": false}


func _play_loop(anim_name: String) -> void:
	var resolved := _resolve_anim_and_flip(anim_name)
	anim.flip_h = resolved["flip_h"]

	if anim.sprite_frames and anim.sprite_frames.has_animation(resolved["name"]):
		if anim.animation != resolved["name"]:
			anim.play(resolved["name"])


func _play_one_shot(anim_name: String) -> void:
	var resolved := _resolve_anim_and_flip(anim_name)
	anim.flip_h = resolved["flip_h"]

	if not (anim.sprite_frames and anim.sprite_frames.has_animation(resolved["name"])):
		return

	is_action_locked = true
	anim.play(resolved["name"])

	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)


func _play_cast_animation(anim_name: String) -> void:
	# Play cast animation without locking movement
	var resolved := _resolve_anim_and_flip(anim_name)
	anim.flip_h = resolved["flip_h"]

	if anim.sprite_frames and anim.sprite_frames.has_animation(resolved["name"]):
		anim.play(resolved["name"])


func _on_anim_finished() -> void:
	is_action_locked = false
