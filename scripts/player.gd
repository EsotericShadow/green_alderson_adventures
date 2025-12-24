extends CharacterBody2D

## COORDINATOR: Player controller
## Makes ALL decisions about player behavior
## Delegates actual work to worker nodes

signal player_died
signal health_changed(current: int, max_health: int)

@export var walk_speed: float = 120.0
@export var run_speed: float = 220.0
# max_health now comes from PlayerStats.get_max_health()
@export var fireball_cooldown: float = 0.6   # Snappier spellcasting
@export var fireball_cast_delay: float = 0.35  # Faster cast wind-up
@export var fireball_mana_cost: int = 15  # Mana consumed per fireball cast (increased)
@export var stamina_drain_rate: float = 20.0  # Stamina per second while running (increased)
@export var min_stamina_to_run: int = 5  # Minimum stamina required to run

# Worker references
@onready var mover: Mover = $Mover
@onready var animator: Animator = $Animator
@onready var input_reader: InputReader = $InputReader
@onready var health_tracker: HealthTracker = $HealthTracker
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var spell_spawner: SpellSpawner = $SpellSpawner

# State
var last_direction: String = "down"
var is_dead: bool = false
var cooldown_timer: float = 0.0
var is_casting: bool = false
var _stamina_drain_accumulator: float = 0.0  # Fractional accumulator for smooth stamina drain

# Screen shake
var _camera: Camera2D = null
var _shake_tween: Tween = null

# Logging
const LOG_PREFIX := "[PLAYER] "
var _last_logged_state := ""


func _log(msg: String) -> void:
	print(LOG_PREFIX + msg)


func _log_error(msg: String) -> void:
	push_error(LOG_PREFIX + "ERROR: " + msg)
	print(LOG_PREFIX + "❌ ERROR: " + msg)


func _ready() -> void:
	add_to_group("player")
	_log("Player spawned at " + str(global_position))
	
	# Configure workers - log any missing ones
	_log("Checking workers...")
	
	if mover == null:
		_log_error("Mover worker is MISSING! Movement will not work.")
	else:
		_log("  ✓ Mover ready")
	
	if animator == null:
		_log_error("Animator worker is MISSING! Animations will not work.")
	else:
		animator.finished.connect(_on_animation_finished)
		_log("  ✓ Animator ready")
	
	if input_reader == null:
		_log_error("InputReader worker is MISSING! Controls will not work.")
	else:
		_log("  ✓ InputReader ready")
	
	if health_tracker == null:
		_log_error("HealthTracker worker is MISSING! Health system disabled.")
	else:
		var max_hp: int = PlayerStats.get_max_health()
		health_tracker.set_max_health(max_hp)
		health_tracker.changed.connect(_on_health_changed)
		health_tracker.died.connect(_on_died)
		# Sync PlayerStats health with HealthTracker initial value
		PlayerStats.set_health(max_hp)
		_log("  ✓ HealthTracker ready (HP: " + str(max_hp) + " from PlayerStats)")
	
	if hurtbox == null:
		_log_error("Hurtbox worker is MISSING! Player cannot take damage.")
	else:
		hurtbox.owner_node = self
		hurtbox.hurt.connect(_on_hurt)
		_log("  ✓ Hurtbox ready")
	
	if spell_spawner == null:
		_log_error("SpellSpawner worker is MISSING! Spells will not work.")
	else:
		_log("  ✓ SpellSpawner ready")
	
	# Find camera for screen shake
	_camera = get_node_or_null("Camera2D")
	if _camera != null:
		_log("  ✓ Camera2D found (screen shake enabled)")
	else:
		_log("  ⚠ No Camera2D found (screen shake disabled)")
	
	_log("Player ready! All systems: " + ("GO" if _all_workers_ready() else "SOME MISSING"))


func _all_workers_ready() -> bool:
	return mover != null and animator != null and input_reader != null and health_tracker != null and spell_spawner != null


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	# --- READ INPUT ---
	if input_reader == null:
		return
	
	var input_vec := input_reader.get_movement()
	var wants_run := input_reader.is_running()
	
	# Check if player has enough stamina to run
	var can_run: bool = wants_run and PlayerStats.has_stamina(min_stamina_to_run)
	if wants_run and not can_run:
		wants_run = false  # Force walk if not enough stamina
	
	# Consume stamina while running (fractional accumulation for smooth drain)
	if wants_run and input_vec.length() > 0.0:
		_stamina_drain_accumulator += stamina_drain_rate * delta
		if _stamina_drain_accumulator >= 1.0:
			var stamina_cost: int = int(_stamina_drain_accumulator)
			_stamina_drain_accumulator -= float(stamina_cost)
			PlayerStats.consume_stamina(stamina_cost)
	else:
		# Reset accumulator when not running
		_stamina_drain_accumulator = 0.0
	
	# --- HANDLE SPELL CASTING ---
	if input_reader.is_action_just_pressed("spell_1"):
		if _can_cast():
			_log("🔥 Spell key pressed - CASTING fireball!")
			_start_fireball_cast(input_vec)
		else:
			if is_casting:
				_log("🔥 Spell key pressed but already casting...")
			elif cooldown_timer > 0.0:
				_log("🔥 Spell key pressed but on cooldown (" + str(snappedf(cooldown_timer, 0.1)) + "s left)")
			elif not PlayerStats.has_mana(fireball_mana_cost):
				_log("🔥 Spell key pressed but not enough mana!")
	
	# --- HANDLE RUN JUMP ---
	if input_reader.is_action_just_pressed("jump") and wants_run and input_vec.length() > 0.0:
		if animator != null and not animator.is_locked():
			last_direction = _vector_to_dir8(input_vec)
			_log("🦘 Run jump! Direction: " + last_direction)
			animator.play_one_shot("run_jump", last_direction)
			return
	
	# --- MOVEMENT ---
	if mover != null:
		var speed := run_speed if wants_run else walk_speed
		mover.move(input_vec, speed)
	
	# --- ANIMATION ---
	if animator == null:
		return
	
	# Log state changes only when they happen
	var current_state := ""
	if animator.is_locked():
		current_state = "locked (one-shot playing)"
	elif input_vec.length() > 0.0:
		current_state = ("running" if wants_run else "walking") + " " + _vector_to_dir8(input_vec)
	else:
		current_state = "idle " + last_direction
	
	if current_state != _last_logged_state:
		_log("State: " + current_state)
		_last_logged_state = current_state
	
	# Don't change animation if one-shot is playing (but movement still works)
	if not animator.is_locked():
		if input_vec.length() > 0.0:
			last_direction = _vector_to_dir8(input_vec)
			var anim_type := "run" if wants_run else "walk"
			animator.play(anim_type, last_direction)
		else:
			animator.play("idle", last_direction)


func _can_cast() -> bool:
	return cooldown_timer <= 0.0 and not is_casting and PlayerStats.has_mana(fireball_mana_cost)


func _start_fireball_cast(input_vec: Vector2) -> void:
	# Consume mana for casting
	if not PlayerStats.consume_mana(fireball_mana_cost):
		_log_error("Failed to consume mana for fireball cast!")
		return
	
	is_casting = true
	cooldown_timer = fireball_cooldown
	
	# Use movement direction if moving, else use last direction
	var cast_dir := last_direction
	if input_vec.length() > 0.0:
		cast_dir = _vector_to_dir8(input_vec)
	
	_log("🔥 Starting fireball cast facing " + cast_dir)
	_log("   Animation: fireball_" + cast_dir)
	_log("   Fireball will spawn in " + str(fireball_cast_delay) + "s")
	
	# Play cast animation (one-shot, but doesn't lock movement)
	if animator != null:
		animator.play_one_shot("fireball", cast_dir)
	else:
		_log_error("Cannot play cast animation - Animator is null!")
	
	# Spawn fireball after delay
	get_tree().create_timer(fireball_cast_delay).timeout.connect(
		_spawn_fireball.bind(cast_dir)
	)


func _spawn_fireball(direction: String) -> void:
	is_casting = false
	_log("🔥 Cast delay complete - spawning fireball!")
	
	if spell_spawner == null:
		_log_error("Cannot spawn fireball - SpellSpawner is null!")
		return
	
	# Z-index: below player when facing north, above when facing south/sides
	var z_index_value := 2
	if _is_facing_north(direction):
		z_index_value = 1
		_log("   Facing north - fireball spawns BELOW player (z=" + str(z_index_value) + ")")
	else:
		_log("   Facing south/side - fireball spawns ABOVE player (z=" + str(z_index_value) + ")")
	
	var fireball := spell_spawner.spawn_fireball(direction, global_position, z_index_value)
	if fireball != null:
		_log("   ✓ Fireball spawned at " + str(global_position))
	else:
		_log_error("SpellSpawner.spawn_fireball returned null!")


func _is_facing_north(dir: String) -> bool:
	return dir == "up" or dir == "ne" or dir == "nw"


func _vector_to_dir8(v: Vector2) -> String:
	if v.length() < 0.1:
		return last_direction
	
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


# --- SIGNAL HANDLERS ---

func _on_health_changed(current: int, maximum: int) -> void:
	_log("💚 Health changed: " + str(current) + "/" + str(maximum))
	health_changed.emit(current, maximum)


func _on_died(killer: Node) -> void:
	var killer_name: String = killer.name if killer != null else "unknown"
	_log("💀 PLAYER DIED! Killed by: " + killer_name)
	is_dead = true
	if input_reader != null:
		input_reader.disable()
		_log("   Input disabled")
	if mover != null:
		mover.stop()
		_log("   Movement stopped")
	player_died.emit()


func _on_hurt(damage: int, knockback: Vector2, attacker: Node) -> void:
	var attacker_name: String = attacker.name if attacker != null else "unknown"
	_log("💥 PLAYER HIT! Damage: " + str(damage) + " from " + attacker_name)
	_log("   Knockback: " + str(knockback))
	
	# SCREEN SHAKE!
	_screen_shake(8.0, 0.2)
	
	# Apply knockback
	if mover != null:
		mover.apply_knockback(knockback * 0.5)
		_log("   Applied knockback")
	
	# Apply damage to PlayerStats (global system) - this will emit health_changed signal
	PlayerStats.take_damage(damage)
	
	# Also update HealthTracker for backwards compatibility
	if health_tracker != null:
		health_tracker.take_damage(damage, attacker)


func _on_animation_finished(anim_name: String) -> void:
	_log("🎬 Animation finished: " + anim_name)
	# One-shot animation finished, casting is done
	if is_casting:
		is_casting = false
		_log("   Cast animation complete, is_casting = false")


## Shake the camera for impact feel
func _screen_shake(intensity: float, duration: float) -> void:
	if _camera == null:
		return
	
	_log("📳 SCREEN SHAKE! Intensity: " + str(intensity))
	
	# Kill any existing shake
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	
	_shake_tween = create_tween()
	var base_offset := _camera.offset
	
	# Do a series of random shakes
	var shake_count := int(duration * 30)  # ~30 shakes per second
	var time_per_shake := duration / shake_count
	
	for i in shake_count:
		var random_offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		# Reduce intensity over time
		var falloff := 1.0 - (float(i) / shake_count)
		_shake_tween.tween_property(_camera, "offset", base_offset + random_offset * falloff, time_per_shake)
	
	# Return to original position
	_shake_tween.tween_property(_camera, "offset", base_offset, 0.05)


# --- PUBLIC API ---

func take_damage(amount: int, source: Node = null) -> void:
	if health_tracker != null:
		health_tracker.take_damage(amount, source)


func get_health() -> int:
	if health_tracker != null:
		return health_tracker.current_health
	return 0
