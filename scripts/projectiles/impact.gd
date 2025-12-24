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
	rotation = angle
	is_active = true
	visible = true
	
	_log("💥 SETUP at " + str(global_position) + ", angle: " + str(rad_to_deg(angle)))
	
	if anim != null and anim.sprite_frames != null:
		if anim.sprite_frames.has_animation("impact_left"):
			anim.visible = true
			anim.frame = 0
			anim.play("impact_left")
			_log("   Playing 'impact_left' animation")
		else:
			_log("   ❌ Animation 'impact_left' NOT found!")
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
