extends CharacterBody2D
class_name BaseEnemy

## COORDINATOR: Base enemy AI controller
## Makes ALL decisions about enemy behavior
## Delegates actual work to worker nodes

signal enemy_died
signal state_changed(old_state: String, new_state: String)

# Stats (override in subclass or scene)
@export_group("Stats")
@export var max_health: int = 100
@export var move_speed: float = 80.0
@export var attack_damage: int = 10
@export var attack_range: float = 40.0
@export var detection_range: float = 200.0

@export_group("Combat")
@export var attack_cooldown: float = 1.5
@export var hurt_duration: float = 0.3
@export var attack_hit_delay: float = 0.2  # Time into attack anim before hitbox activates
@export var attack_hit_duration: float = 0.15  # How long hitbox stays active

# Worker references
@onready var mover: Mover = $Mover
@onready var animator: Animator = $Animator
@onready var health_tracker: HealthTracker = $HealthTracker
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var target_tracker: TargetTracker = $TargetTracker
@onready var detection_area: Area2D = $DetectionArea

# State
enum State { IDLE, CHASE, ATTACK, HURT, DEATH, RETURN }
var current_state: State = State.IDLE
var last_direction: String = "down"
var attack_cooldown_timer: float = 0.0
var hurt_timer: float = 0.0
var is_dead: bool = false

# Logging
var _log_name := "[ENEMY] "

# Effects
var _hit_flash_tween: Tween = null


func _log(msg: String) -> void:
	print(_log_name + msg)


func _log_error(msg: String) -> void:
	push_error(_log_name + "ERROR: " + msg)
	print(_log_name + "❌ ERROR: " + msg)


func _ready() -> void:
	_log_name = "[" + name + "] "
	add_to_group("enemy")
	_log("Enemy spawned at " + str(global_position))
	_setup_workers()
	_connect_signals()


func _setup_workers() -> void:
	_log("Checking workers...")
	
	if mover == null:
		_log_error("Mover is MISSING! Movement will not work.")
	else:
		_log("  ✓ Mover ready")
	
	if animator == null:
		_log_error("Animator is MISSING! Animations will not work.")
	else:
		animator.use_4_directions = true
		_log("  ✓ Animator ready (4-directional)")
	
	if health_tracker == null:
		_log_error("HealthTracker is MISSING!")
	else:
		health_tracker.set_max_health(max_health)
		_log("  ✓ HealthTracker ready (HP: " + str(max_health) + ")")
	
	if hurtbox == null:
		_log_error("Hurtbox is MISSING! Cannot take damage.")
	else:
		hurtbox.owner_node = self
		_log("  ✓ Hurtbox ready")
	
	if hitbox == null:
		_log_error("Hitbox is MISSING! Cannot deal damage.")
	else:
		hitbox.owner_node = self
		hitbox.damage = attack_damage
		hitbox.disable()
		_log("  ✓ Hitbox ready (damage: " + str(attack_damage) + ")")
	
	if target_tracker == null:
		_log_error("TargetTracker is MISSING! Cannot track player.")
	else:
		target_tracker.detection_range = detection_range
		target_tracker.lose_range = detection_range * 1.5
		_log("  ✓ TargetTracker ready (range: " + str(detection_range) + ")")
	
	if detection_area == null:
		_log_error("DetectionArea is MISSING! Cannot detect player.")
	else:
		_log("  ✓ DetectionArea ready")
	
	_log("Setup complete!")


func _connect_signals() -> void:
	if health_tracker != null:
		health_tracker.died.connect(_on_died)
	
	if hurtbox != null:
		hurtbox.hurt.connect(_on_hurt)
	
	if detection_area != null:
		detection_area.body_entered.connect(_on_body_entered_detection)
		detection_area.body_exited.connect(_on_body_exited_detection)
	
	if animator != null:
		animator.finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update timers
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if hurt_timer > 0.0:
		hurt_timer -= delta
	
	# Process current state
	match current_state:
		State.IDLE:
			_process_idle()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack()
		State.HURT:
			_process_hurt()
		State.RETURN:
			_process_return()
		State.DEATH:
			pass  # Do nothing when dead


func _process_idle() -> void:
	if mover != null:
		mover.stop()
	if animator != null:
		animator.play("idle", last_direction)
	
	# Check if target acquired
	if target_tracker != null and target_tracker.has_target():
		_log("👁️ Target detected! Switching to CHASE")
		_change_state(State.CHASE)


func _process_chase() -> void:
	if target_tracker == null:
		_change_state(State.IDLE)
		return
	
	# Lost target?
	if not target_tracker.has_target():
		_log("👁️ Lost target - returning to spawn")
		_change_state(State.RETURN)
		return
	
	if target_tracker.is_target_too_far():
		_log("👁️ Target too far (" + str(int(target_tracker.get_distance_to_target())) + " > " + str(int(target_tracker.lose_range)) + ") - giving up")
		target_tracker.clear_target()
		_change_state(State.RETURN)
		return
	
	# In attack range and can attack?
	var dist := target_tracker.get_distance_to_target()
	if dist <= attack_range and attack_cooldown_timer <= 0.0:
		_log("⚔️ In range (" + str(int(dist)) + " <= " + str(int(attack_range)) + ") - ATTACKING!")
		_change_state(State.ATTACK)
		return
	
	# Move toward target
	var dir := target_tracker.get_direction_to_target()
	if mover != null:
		mover.move(dir, move_speed)
	
	# Update facing direction
	last_direction = _vector_to_dir4(dir)
	if animator != null:
		animator.play("walk", last_direction)


func _process_attack() -> void:
	if mover != null:
		mover.stop()
	# Attack animation and hitbox handled in _start_attack


func _process_hurt() -> void:
	if mover != null:
		mover.stop()
	
	# Wait for hurt duration
	if hurt_timer <= 0.0:
		_log("💢 Hurt recovery complete")
		if target_tracker != null and target_tracker.has_target():
			_change_state(State.CHASE)
		else:
			_change_state(State.IDLE)


func _process_return() -> void:
	if target_tracker == null:
		_change_state(State.IDLE)
		return
	
	# Reached spawn?
	if target_tracker.is_at_spawn():
		_log("🏠 Reached spawn - going idle")
		_change_state(State.IDLE)
		return
	
	# Move toward spawn
	var dir := target_tracker.get_direction_to_spawn()
	if mover != null:
		mover.move(dir, move_speed * 0.7)  # Walk back slower
	
	last_direction = _vector_to_dir4(dir)
	if animator != null:
		animator.play("walk", last_direction)


func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	var old_state := current_state
	current_state = new_state
	
	_log("📍 State: " + _state_name(old_state) + " → " + _state_name(new_state))
	
	# Handle state entry
	match new_state:
		State.ATTACK:
			_start_attack()
		State.HURT:
			_start_hurt()
		State.DEATH:
			_start_death()
	
	state_changed.emit(_state_name(old_state), _state_name(new_state))


func _start_attack() -> void:
	attack_cooldown_timer = attack_cooldown
	_log("⚔️ Starting attack!")
	_log("   Cooldown set to " + str(attack_cooldown) + "s")
	
	# Face target
	if target_tracker != null and target_tracker.has_target():
		var dir := target_tracker.get_direction_to_target()
		last_direction = _vector_to_dir4(dir)
		_log("   Facing: " + last_direction)
	
	# Play attack animation
	if animator != null:
		_log("   Playing: attack_" + last_direction)
		animator.play_one_shot("attack", last_direction)
	else:
		_log_error("Cannot play attack animation - Animator is null!")
	
	# Enable hitbox after delay
	_log("   Hitbox activates in " + str(attack_hit_delay) + "s")
	get_tree().create_timer(attack_hit_delay).timeout.connect(_enable_hitbox)


func _enable_hitbox() -> void:
	if current_state != State.ATTACK:
		_log("⚔️ Hitbox activation cancelled - no longer in ATTACK state")
		return
	
	if hitbox == null:
		_log_error("Cannot enable hitbox - Hitbox is null!")
		return
	
	# Position hitbox based on facing direction
	_position_hitbox()
	_log("⚔️ HITBOX ACTIVE for " + str(attack_hit_duration) + "s (position: " + str(hitbox.position) + ")")
	hitbox.enable_for(attack_hit_duration)


func _position_hitbox() -> void:
	if hitbox == null:
		return
	
	var offset := Vector2(20, 0)
	match last_direction:
		"down": offset = Vector2(0, 20)
		"up": offset = Vector2(0, -20)
		"left": offset = Vector2(-20, 0)
		"right": offset = Vector2(20, 0)
	
	hitbox.position = offset


func _start_hurt() -> void:
	hurt_timer = hurt_duration
	_log("💢 HURT! Recovery time: " + str(hurt_duration) + "s")
	
	if animator != null:
		animator.force_stop_one_shot()  # Interrupt any current animation
		animator.play_one_shot("hurt", last_direction)
		_log("   Playing: hurt_" + last_direction)
	else:
		_log_error("Cannot play hurt animation - Animator is null!")


func _start_death() -> void:
	is_dead = true
	_log("💀 DEATH!")
	
	if mover != null:
		mover.stop()
	
	if hurtbox != null:
		hurtbox.disable()
		_log("   Hurtbox disabled")
	if hitbox != null:
		hitbox.disable()
		_log("   Hitbox disabled")
	
	if animator != null:
		animator.play_one_shot("death", last_direction)
		_log("   Playing: death_" + last_direction)
	else:
		_log_error("Cannot play death animation - Animator is null!")


func _vector_to_dir4(v: Vector2) -> String:
	if v.length() < 0.1:
		return last_direction
	
	var deg := rad_to_deg(atan2(v.y, v.x))
	deg = fposmod(deg + 45.0, 360.0)
	
	if deg < 90.0: return "right"
	elif deg < 180.0: return "down"
	elif deg < 270.0: return "left"
	else: return "up"


func _state_name(state: State) -> String:
	match state:
		State.IDLE: return "idle"
		State.CHASE: return "chase"
		State.ATTACK: return "attack"
		State.HURT: return "hurt"
		State.DEATH: return "death"
		State.RETURN: return "return"
		_: return "unknown"


## Flash red when taking damage
func _flash_red() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return
	
	# Kill previous flash tween
	if _hit_flash_tween != null and _hit_flash_tween.is_valid():
		_hit_flash_tween.kill()
	
	_log("💥 FLASH RED")
	sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red tint
	
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


# --- SIGNAL HANDLERS ---

func _on_body_entered_detection(body: Node2D) -> void:
	if body.is_in_group("player"):
		_log("👁️ PLAYER DETECTED! (" + body.name + " entered detection area)")
		if target_tracker != null:
			target_tracker.set_target(body)
		else:
			_log_error("Cannot track player - TargetTracker is null!")


func _on_body_exited_detection(body: Node2D) -> void:
	if target_tracker != null and body == target_tracker.target:
		_log("👁️ Player left detection area (but still tracking...)")
		# Don't immediately lose target, let distance check handle it


func _on_hurt(damage: int, knockback: Vector2, attacker: Node) -> void:
	if is_dead:
		_log("💢 Hit received but already dead - ignoring")
		return
	
	var attacker_name: String = attacker.name if attacker != null else "unknown"
	_log("💥 HIT! Damage: " + str(damage) + " from " + attacker_name)
	_log("   Knockback: " + str(knockback))
	
	# Visual feedback - flash red!
	_flash_red()
	
	# Apply knockback
	if mover != null:
		mover.apply_knockback(knockback)
		_log("   Applied knockback")
	
	# Apply damage
	if health_tracker != null:
		var hp_before := health_tracker.current_health
		health_tracker.take_damage(damage, attacker)
		_log("   Health: " + str(hp_before) + " → " + str(health_tracker.current_health))
	
	# Enter hurt state (unless dead)
	if not is_dead:
		_change_state(State.HURT)


func _on_died(killer: Node) -> void:
	var killer_name: String = killer.name if killer != null else "unknown"
	_log("💀 KILLED by " + killer_name + "!")
	_change_state(State.DEATH)


func _on_animation_finished(anim_name: String) -> void:
	_log("🎬 Animation finished: " + anim_name)
	
	# Attack finished
	if anim_name.begins_with("attack"):
		_log("   Attack complete - deciding next action...")
		if target_tracker != null and target_tracker.has_target():
			_log("   Still have target - continuing chase")
			_change_state(State.CHASE)
		else:
			_log("   No target - going idle")
			_change_state(State.IDLE)
	
	# Death animation finished
	elif anim_name.begins_with("death"):
		_log("   Death animation complete - removing from scene")
		enemy_died.emit()
		queue_free()


# --- PUBLIC API ---

func take_damage(amount: int, source: Node = null) -> void:
	if hurtbox != null:
		var knockback := Vector2.ZERO
		if source != null and source is Node2D:
			knockback = (global_position - source.global_position).normalized() * 100.0
		hurtbox.receive_hit(amount, knockback, source)
