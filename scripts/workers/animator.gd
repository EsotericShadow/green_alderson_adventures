extends Node
class_name Animator

## WORKER: Plays animations on an AnimatedSprite2D
## Does ONE thing: plays the requested animation
## Does NOT: decide which animation to play, track state

signal finished(anim_name: String)

var sprite: AnimatedSprite2D = null
var is_one_shot_playing: bool = false
var current_one_shot: String = ""
var use_4_directions: bool = false  # false = 8 directions, true = 4 directions

var _log_prefix := "[Animator] "
var _last_anim := ""


func _log(msg: String) -> void:
	print(_log_prefix + msg)


func _log_error(msg: String) -> void:
	push_error(_log_prefix + "ERROR: " + msg)
	print(_log_prefix + "❌ ERROR: " + msg)


func _ready() -> void:
	_log_prefix = "[" + get_parent().name + "/Animator] "
	
	sprite = get_parent().get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		_log_error("No AnimatedSprite2D found as sibling! Animations will NOT work.")
		return
	
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)


## Play a looping animation (walk, run, idle)
## Will not interrupt a one-shot animation
func play(base_name: String, direction: String) -> void:
	if sprite == null:
		_log_error("Cannot play '" + base_name + "' - sprite is null!")
		return
	
	# Don't interrupt one-shot animations
	if is_one_shot_playing:
		return
	
	var anim_name := _resolve_anim_name(base_name, direction)
	_update_flip(direction)
	
	if sprite.animation != anim_name:
		if anim_name != _last_anim:
			_log("▶️ " + anim_name)
			_last_anim = anim_name
		sprite.play(anim_name)


## Play a one-shot animation (attack, hurt, cast)
## Returns immediately, emits 'finished' signal when done
func play_one_shot(base_name: String, direction: String) -> void:
	if sprite == null:
		_log_error("Cannot play one-shot '" + base_name + "' - sprite is null!")
		return
	
	var anim_name := _resolve_anim_name(base_name, direction)
	_update_flip(direction)
	
	if sprite.sprite_frames.has_animation(anim_name):
		_log("🎬 ONE-SHOT: " + anim_name)
		is_one_shot_playing = true
		current_one_shot = anim_name
		_last_anim = anim_name
		sprite.play(anim_name)
	else:
		_log_error("Animation '" + anim_name + "' NOT FOUND!")
		_log("   Requested: " + base_name + " + " + direction)
		_log("   Resolved to: " + anim_name)


## Check if a one-shot animation is currently playing
func is_locked() -> bool:
	return is_one_shot_playing


## Force stop the current one-shot (for interrupts like death)
func force_stop_one_shot() -> void:
	is_one_shot_playing = false
	current_one_shot = ""


func _resolve_anim_name(base: String, direction: String) -> String:
	# Consistency fix: Use flipped NE animations for NW
	# This ensures consistent animation quality for northwest-facing animations
	var resolved_dir := direction
	if direction == "nw":
		resolved_dir = "ne"
	
	var full_name := base + "_" + resolved_dir
	
	if sprite.sprite_frames.has_animation(full_name):
		return full_name
	
	# Fallback: try 4-direction version
	var dir4 := _dir8_to_dir4(direction)
	var fallback := base + "_" + dir4
	
	if sprite.sprite_frames.has_animation(fallback):
		return fallback
	
	# Last resort: just the base name
	if sprite.sprite_frames.has_animation(base):
		return base
	
	return full_name  # Return original, let Godot handle missing anim


func _dir8_to_dir4(dir8: String) -> String:
	match dir8:
		"up", "ne", "nw": return "up"
		"down", "se", "sw": return "down"
		"left": return "left"
		"right": return "right"
		_: return "down"


func _update_flip(direction: String) -> void:
	if sprite == null:
		return
	
	# Consistency fix: Flip NW to use NE animations
	# Flip horizontally when using NE animation for NW direction
	if direction == "nw":
		sprite.flip_h = true
	# Only flip for 4-directional sprites (left direction)
	elif use_4_directions:
		sprite.flip_h = (direction == "left")
	else:
		sprite.flip_h = false


func _on_animation_finished() -> void:
	if is_one_shot_playing:
		var anim := current_one_shot
		_log("🎬 One-shot finished: " + anim)
		is_one_shot_playing = false
		current_one_shot = ""
		finished.emit(anim)

