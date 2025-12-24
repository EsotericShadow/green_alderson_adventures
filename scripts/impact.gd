extends Node2D

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var pool_manager: ProjectilePool = null
var animation_finished_connected := false

func _ready() -> void:
	# Find pool manager for returning to pool
	_find_pool_manager()
	
	# If spawned without calling setup(), still play default
	_play_and_auto_free(0.0)


func _find_pool_manager() -> void:
	var current_scene = get_tree().current_scene
	if current_scene != null:
		pool_manager = current_scene.get_node_or_null("ProjectilePool")
		if pool_manager == null:
			pool_manager = current_scene.find_child("ProjectilePool", true, false)


# angle is in radians
func setup(angle: float) -> void:
	rotation = angle
	_play_and_auto_free(angle)

func _play_and_auto_free(_angle: float) -> void:
	if anim == null or anim.sprite_frames == null:
		_return_to_pool()
		return

	if anim.sprite_frames.has_animation("impact_left"):
		anim.flip_h = false
		anim.play("impact_left")
		if not animation_finished_connected:
			anim.animation_finished.connect(_on_animation_finished)
			animation_finished_connected = true
	else:
		_return_to_pool()


func _on_animation_finished() -> void:
	_return_to_pool()


func _return_to_pool() -> void:
	# Return to pool if available, otherwise free
	if pool_manager != null and pool_manager.has_method("return_impact"):
		pool_manager.return_impact(self)
	else:
		queue_free()
