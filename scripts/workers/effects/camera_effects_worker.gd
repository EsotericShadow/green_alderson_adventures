extends "res://scripts/workers/base/base_worker.gd"
class_name CameraEffectsWorker
## Worker that handles camera effects like screen shake.
## Should be added as a child of an entity with a Camera2D node.

signal effect_finished

var _camera: Camera2D = null
var _shake_tween: Tween = null


func _on_initialize() -> void:
	# Find camera in parent or children
	_camera = _find_camera()
	if _camera == null:
		_logger.log_error("CameraEffectsWorker: No Camera2D found! Screen shake will not work.")
	else:
		_logger.log("CameraEffectsWorker: Camera2D found")


func _find_camera() -> Camera2D:
	# Try parent first (entity might have camera as child)
	var parent = get_parent()
	if parent != null:
		var camera = parent.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			return camera
		# Try parent's children
		for child in parent.get_children():
			if child is Camera2D:
				return child
	
	# Try node path from parent
	if parent != null:
		return parent.get_node_or_null("../Camera2D") as Camera2D
	
	return null


## Shakes the camera for impact feel.
## 
## Args:
##   intensity: Shake intensity (higher = more intense)
##   duration: Duration of shake in seconds
func screen_shake(intensity: float, duration: float) -> void:
	if _camera == null:
		return
	
	_logger.log_debug("📳 SCREEN SHAKE! Intensity: " + str(intensity) + ", Duration: " + str(duration))
	
	# Kill any existing shake
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	
	if owner_node == null:
		return
	
	_shake_tween = owner_node.create_tween()
	var base_offset := _camera.offset
	
	# Do a series of random shakes
	var shake_count := int(duration * 30)  # ~30 shakes per second
	var time_per_shake: float = duration / float(shake_count)
	
	for i in range(shake_count):
		var random_offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		# Reduce intensity over time
		var falloff := 1.0 - (float(i) / shake_count)
		_shake_tween.tween_property(_camera, "offset", base_offset + random_offset * falloff, time_per_shake)
	
	# Return to original position
	_shake_tween.tween_property(_camera, "offset", base_offset, 0.05)
	_shake_tween.tween_callback(func(): effect_finished.emit())

