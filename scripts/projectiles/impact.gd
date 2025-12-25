extends Node2D

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var pool_manager: ProjectilePool = null
var is_active := false

const LOG_PREFIX := "[Impact] "


func _log(msg: String) -> void:
	print(LOG_PREFIX + msg)


func _ready() -> void:
	_find_pool_manager()
	
	if anim != null:
		if not anim.animation_finished.is_connected(_on_animation_finished):
			anim.animation_finished.connect(_on_animation_finished)
		_log("AnimatedSprite2D found and connected")
	else:
		_log("❌ ERROR: AnimatedSprite2D NOT found!")


func _find_pool_manager() -> void:
	var current_scene = get_tree().current_scene
	if current_scene != null:
		pool_manager = current_scene.get_node_or_null("ProjectilePool")
		if pool_manager == null:
			pool_manager = current_scene.find_child("ProjectilePool", true, false)


func setup(angle: float) -> void:
	# angle is the direction the fireball came FROM (pointing back toward shooter)
	# We want the impact to face the direction the fireball was traveling TO
	var travel_angle := angle + PI  # Reverse direction (180 degrees)
	is_active = true
	visible = true
	
	# Ensure impact appears on top of everything
	z_index = 100
	if anim != null:
		anim.z_index = 100
	
	_log("💥 SETUP at " + str(global_position) + ", travel_angle: " + str(rad_to_deg(travel_angle)))
	
	if anim != null and anim.sprite_frames != null:
		# Find the correct animation name (element-specific impacts have different names)
		var animation_name: String = ""
		var animations := anim.sprite_frames.get_animation_names()
		
		# Check for element-specific animations first
		if anim.sprite_frames.has_animation("fireball_impact_left"):
			animation_name = "fireball_impact_left"
		elif anim.sprite_frames.has_animation("waterball_impact_left"):
			animation_name = "waterball_impact_left"
		elif anim.sprite_frames.has_animation("earthball_impact_left"):
			animation_name = "earthball_impact_left"
		elif anim.sprite_frames.has_animation("airball_impact_left"):
			animation_name = "airball_impact_left"
		elif anim.sprite_frames.has_animation("impact_left"):
			animation_name = "impact_left"
		else:
			# Fallback to first available animation
			if animations.size() > 0:
				animation_name = animations[0]
				_log("   ⚠️ Using first available animation: " + animation_name)
		
		if animation_name != "":
			anim.visible = true
			anim.frame = 0
			
			# impact animations face left by default
			# Determine flip/rotation based on travel direction
			# Normalize angle to 0-2π range
			var normalized_angle := fposmod(travel_angle, TAU)
			
			# Reset flips and rotation
			anim.flip_h = false
			anim.flip_v = false
			rotation = 0.0
			
			# Convert to 4 main directions (left, right, up, down)
			if normalized_angle >= 7 * PI / 8 and normalized_angle < 9 * PI / 8:
				# Traveling LEFT (180°) - impact_left already faces left, no change
				rotation = 0.0
			elif normalized_angle < PI / 8 or normalized_angle >= 15 * PI / 8:
				# Traveling RIGHT (0°) - flip horizontally
				anim.flip_h = true
				rotation = 0.0
			elif normalized_angle >= 3 * PI / 8 and normalized_angle < 5 * PI / 8:
				# Traveling DOWN (90°) - rotate 90° clockwise
				rotation = PI / 2
			elif normalized_angle >= 11 * PI / 8 and normalized_angle < 13 * PI / 8:
				# Traveling UP (270°) - rotate 90° counter-clockwise
				rotation = -PI / 2
			else:
				# Diagonal - rotate to match travel direction
				# impact_left faces left (180°), so adjust
				rotation = normalized_angle - PI
			
			anim.play(animation_name)
			_log("   Playing '" + animation_name + "' animation (normalized: " + str(int(rad_to_deg(normalized_angle))) + "°, rotation: " + str(int(rad_to_deg(rotation))) + "°)")
		else:
			_log("   ❌ No valid impact animation found! Available: " + str(animations))
	else:
		_log("   ❌ anim or sprite_frames is null!")


func _on_animation_finished() -> void:
	_log("Animation finished")
	if is_active:
		_return_to_pool()


func _return_to_pool() -> void:
	_log("Returning to pool")
	is_active = false
	visible = false
	
	if pool_manager != null and pool_manager.has_method("return_impact"):
		pool_manager.return_impact(self)
	else:
		queue_free()
