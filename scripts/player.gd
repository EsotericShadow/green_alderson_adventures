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
var _running_enabled: bool = false  # Whether running is currently enabled (separate from run key state)
var spawn_position: Vector2 = Vector2(0, -2)  # Default spawn position (will be set from scene)

# Spell system (Commit 3C: 10 spell slots)
var equipped_spells: Array[SpellData] = []  # Size 10
var selected_spell_index: int = 0
var spell_bar: Node = null  # Reference to spell bar UI (CanvasLayer)

# Screen shake
var _camera: Camera2D = null
var _shake_tween: Tween = null

# Logging
var _last_logged_state := ""
var _logger = GameLogger.create("[PLAYER] ")


func _log(msg: String) -> void:
	_logger.log(msg)


func _log_error(msg: String) -> void:
	_logger.log_error(msg)


func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position  # Store initial spawn position
	# _log("Player spawned at " + str(global_position))  # Commented out: initialization logging
	# _log("Checking workers...")  # Commented out: initialization logging
	
	if mover == null:
		_log_error("Mover worker is MISSING! Movement will not work.")
	# else:
		# _log("  ✓ Mover ready")  # Commented out: initialization logging (keep errors)
	
	if animator == null:
		_log_error("Animator worker is MISSING! Animations will not work.")
	else:
		animator.finished.connect(_on_animation_finished)
		# _log("  ✓ Animator ready")  # Commented out: initialization logging (keep errors)
	
	if input_reader == null:
		_log_error("InputReader worker is MISSING! Controls will not work.")
	# else:
		# _log("  ✓ InputReader ready")  # Commented out: initialization logging (keep errors)
	
	if health_tracker == null:
		_log_error("HealthTracker worker is MISSING! Health system disabled.")
	else:
		var max_hp: int = PlayerStats.get_max_health()
		health_tracker.set_max_health(max_hp)
		# Connect HealthTracker died signal (for death handling via PlayerStats)
		# Note: HealthTracker will be synced from PlayerStats, so death comes from PlayerStats.player_died
		PlayerStats.player_died.connect(_on_died)
		# Sync PlayerStats health with HealthTracker initial value
		PlayerStats.set_health(max_hp)
		# Sync HealthTracker from PlayerStats (PlayerStats is source of truth)
		PlayerStats.health_changed.connect(_sync_health_tracker_from_stats)
		# Initial sync
		_sync_health_tracker_from_stats(PlayerStats.health, PlayerStats.get_max_health())
		_log("  ✓ HealthTracker ready (HP: " + str(max_hp) + " from PlayerStats)")
	
	if hurtbox == null:
		_log_error("Hurtbox worker is MISSING! Player cannot take damage.")
	else:
		hurtbox.owner_node = self
		hurtbox.hurt.connect(_on_hurt)
		# _log("  ✓ Hurtbox ready")  # Commented out: initialization logging (keep errors)
	
	if spell_spawner == null:
		_log_error("SpellSpawner worker is MISSING! Spells will not work.")
	# else:
		# _log("  ✓ SpellSpawner ready")  # Commented out: initialization logging (keep errors)
	
	# Find camera for screen shake
	_camera = get_node_or_null("Camera2D")
	if _camera != null:
		# _log("  ✓ Camera2D found (screen shake enabled)")  # Commented out: initialization logging
		pass
	else:
		pass  # _log("  ⚠ No Camera2D found (screen shake disabled)")  # Commented out: initialization logging
	
	# Load default spells (Commit 3C: 10 spell slots)
	equipped_spells.resize(10)
	equipped_spells[0] = load("res://resources/spells/fireball.tres") as SpellData
	equipped_spells[1] = load("res://resources/spells/waterball.tres") as SpellData
	equipped_spells[2] = load("res://resources/spells/earthball.tres") as SpellData
	equipped_spells[3] = load("res://resources/spells/airball.tres") as SpellData
	# Slots 4-9 remain null for now
	
	# Find and connect to spell bar UI
	_find_spell_bar()
	
	# _log("  ✓ Loaded " + str(_count_equipped_spells()) + " spells")  # Commented out: initialization logging
	# _log("Player ready! All systems: " + ("GO" if _all_workers_ready() else "SOME MISSING"))  # Commented out: initialization logging


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
	var run_key_just_pressed := input_reader.is_run_just_pressed()
	var run_key_just_released := input_reader.is_run_just_released()
	
	# Handle running state transitions
	# Enable running when run key is pressed (can happen while already moving)
	if run_key_just_pressed:
		if PlayerStats.has_stamina(min_stamina_to_run):
			_running_enabled = true
			# _log("🏃 Running enabled (run key pressed)")  # Commented out: movement logging
		else:
			# _log("🏃 Run key pressed but insufficient stamina (" + str(PlayerStats.stamina) + "/" + str(min_stamina_to_run) + ")")  # Commented out: movement logging
			pass
	
	# Disable running when run key is released
	if run_key_just_released:
		_running_enabled = false
		# _log("🚶 Running disabled (run key released)")  # Commented out: movement logging
	
	# Auto-disable running when stamina depletes (even if run key is still held)
	var has_enough_stamina: bool = PlayerStats.has_stamina(min_stamina_to_run)
	if _running_enabled and not has_enough_stamina:
		_running_enabled = false
		# _log("🚶 Running auto-disabled (stamina depleted, run key still held)")  # Commented out: movement logging
	
	# Determine if player should actually run
	var wants_run: bool = _running_enabled and has_enough_stamina
	
	# Consume stamina while running (fractional accumulation for smooth drain)
	# Stamina consumption is already reduced by agility in PlayerStats.consume_stamina()
	if wants_run and input_vec.length() > 0.0:
		_stamina_drain_accumulator += stamina_drain_rate * delta
		if _stamina_drain_accumulator >= 1.0:
			var stamina_cost: int = int(_stamina_drain_accumulator)
			_stamina_drain_accumulator -= float(stamina_cost)
			PlayerStats.consume_stamina(stamina_cost)
	else:
		# Reset accumulator when not running
		_stamina_drain_accumulator = 0.0
	
	# --- HANDLE SPELL SELECTION AND CASTING (1-9, 0) ---
	for i in range(10):
		var action_name := "spell_" + str(i + 1) if i < 9 else "spell_0"
		if input_reader.is_action_just_pressed(action_name):
			# If already selected, cast it; otherwise just select
			if selected_spell_index == i:
				# Cast the spell
				if _can_cast():
					var spell := get_selected_spell()
					if spell != null:
						# _log("🔥 Spell key pressed - CASTING " + spell.display_name + "!")  # Commented out: spell casting logging
						_start_fireball_cast(input_vec)
					else:
						# _log("🔥 Spell key pressed but no spell in slot " + str(i + 1))  # Commented out: spell casting logging
						pass
				else:
					if is_casting:
						# _log("🔥 Spell key pressed but already casting...")  # Commented out: spell casting logging
						pass
					elif cooldown_timer > 0.0:
						# _log("🔥 Spell key pressed but on cooldown (" + str(snappedf(cooldown_timer, 0.1)) + "s left)")  # Commented out: spell casting logging
						pass
					else:
						var spell := get_selected_spell()
						if spell != null and not PlayerStats.has_mana(spell.mana_cost):
							# _log("🔥 Spell key pressed but not enough mana!")  # Commented out: spell casting logging (mana logged in PlayerStats)
							pass
			else:
				# Select the spell
				_select_spell(i)
			break
	
	# --- HANDLE RUN JUMP ---
	if input_reader.is_action_just_pressed("jump") and wants_run and input_vec.length() > 0.0:
		if animator != null and not animator.is_locked():
			last_direction = DirectionUtils.vector_to_dir8(input_vec, last_direction)
			# _log("🦘 Run jump! Direction: " + last_direction)  # Commented out: movement logging
			animator.play_one_shot("run_jump", last_direction)
			return
	
	# --- MOVEMENT ---
	if mover != null:
		var base_speed := run_speed if wants_run else walk_speed
		# Apply agility-based speed multiplier
		var speed_multiplier: float = PlayerStats.get_movement_speed_multiplier() if wants_run else 1.0
		# Apply carry weight slow down effect (85%+ weight)
		var carry_slow_multiplier: float = PlayerStats.get_carry_weight_slow_multiplier()
		var speed := base_speed * speed_multiplier * carry_slow_multiplier
		mover.move(input_vec, speed)
	
	# --- ANIMATION ---
	if animator == null:
		return
	
	# Log state changes only when they happen
	var current_state := ""
	if animator.is_locked():
		current_state = "locked (one-shot playing)"
	elif input_vec.length() > 0.0:
		current_state = ("running" if wants_run else "walking") + " " + DirectionUtils.vector_to_dir8(input_vec, last_direction)
	else:
		current_state = "idle " + last_direction
	
	if current_state != _last_logged_state:
		# _log("State: " + current_state)  # Commented out: movement logging
		_last_logged_state = current_state
	
	# Don't change animation if one-shot is playing (but movement still works)
	if not animator.is_locked():
		if input_vec.length() > 0.0:
			last_direction = DirectionUtils.vector_to_dir8(input_vec, last_direction)
			var anim_type := "run" if wants_run else "walk"
			animator.play(anim_type, last_direction)
		else:
			animator.play("idle", last_direction)


func _can_cast() -> bool:
	var spell := get_selected_spell()
	if spell == null:
		# Fallback to hardcoded mana cost if no spell
		return cooldown_timer <= 0.0 and not is_casting and PlayerStats.has_mana(fireball_mana_cost)
	
	# Use spell's mana cost and validate with SpellSystem
	if SpellSystem != null and not SpellSystem.can_cast(spell):
		return false
	
	return cooldown_timer <= 0.0 and not is_casting


func _start_fireball_cast(input_vec: Vector2) -> void:
	# Consume mana for casting (use spell's mana cost if available)
	var spell := get_selected_spell()
	var mana_to_consume: int = fireball_mana_cost
	if spell != null:
		mana_to_consume = spell.mana_cost
	
	if not PlayerStats.consume_mana(mana_to_consume):
		_log_error("Failed to consume mana for fireball cast!")
		return
	
	is_casting = true
	# Use spell's cooldown if available, otherwise use default
	if spell != null:
		cooldown_timer = spell.cooldown
	else:
		cooldown_timer = fireball_cooldown
	
	# Use movement direction if moving, else use last direction
	var cast_dir := last_direction
	if input_vec.length() > 0.0:
		cast_dir = DirectionUtils.vector_to_dir8(input_vec, last_direction)
	
	# _log("🔥 Starting fireball cast facing " + cast_dir)  # Commented out: spell casting logging
	# _log("   Animation: fireball_" + cast_dir)  # Commented out: spell casting logging
	# _log("   Fireball will spawn in " + str(fireball_cast_delay) + "s")  # Commented out: spell casting logging
	
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
	# _log("🔥 Cast delay complete - spawning fireball!")  # Commented out: spell casting logging
	
	if spell_spawner == null:
		_log_error("Cannot spawn fireball - SpellSpawner is null!")
		return
	
	# Z-index: below player when facing north, above when facing south/sides
	var z_index_value := 2
	if DirectionUtils.is_facing_north(direction):
		z_index_value = 1
		# _log("   Facing north - fireball spawns BELOW player (z=" + str(z_index_value) + ")")  # Commented out: spell casting logging
	else:
		pass  # _log("   Facing south/side - fireball spawns ABOVE player (z=" + str(z_index_value) + ")")  # Commented out: spell casting logging
	
	# Pass selected spell data to spawner
	var spell := get_selected_spell()
	var fireball := spell_spawner.spawn_fireball(direction, global_position, z_index_value, spell)
	if fireball != null:
		# _log("   ✓ Fireball spawned at " + str(global_position))  # Commented out: spell casting logging
		# if spell != null:
		# 	_log("   ✓ Using spell: " + spell.display_name + " (" + spell.element + ")")  # Commented out: spell casting logging
		pass
	else:
		_log_error("SpellSpawner.spawn_fireball returned null!")






func get_selected_spell() -> SpellData:
	"""Returns the currently selected spell."""
	if selected_spell_index >= 0 and selected_spell_index < equipped_spells.size():
		return equipped_spells[selected_spell_index]
	return null


func _select_spell(index: int) -> void:
	"""Selects a spell slot (0-9)."""
	if index < 0 or index >= equipped_spells.size():
		return
	
	if equipped_spells[index] == null:
		# _log("⚠️ Spell slot " + str(index + 1) + " is empty")  # Commented out: spell casting logging
		return
	
	selected_spell_index = index
	# _log("📖 Selected spell slot " + str(index + 1) + ": " + equipped_spells[index].display_name)  # Commented out: spell casting logging
	
	# Update spell bar UI
	if spell_bar != null and spell_bar.has_method("select_slot"):
		spell_bar.select_slot(index)


func _find_spell_bar() -> void:
	"""Finds the spell bar UI in the scene tree."""
	# Spell bar is now a CanvasLayer, so find it directly in the scene
	spell_bar = get_tree().current_scene.get_node_or_null("SpellBar")
	if spell_bar == null:
		# Try finding it in HUD (if it's still there)
		var hud := get_tree().current_scene.get_node_or_null("HUD")
		if hud != null:
			spell_bar = hud.get_node_or_null("SpellBar")
	
	if spell_bar == null:
		_log_error("⚠️ SpellBar not found - spell bar UI unavailable")
		# _log("   Searching for SpellBar in scene tree...")  # Commented out: initialization logging (keep errors)
		var scene := get_tree().current_scene
		if scene != null:
			# _log("   Current scene: " + scene.name)  # Commented out: initialization logging
			# for child in scene.get_children():
			# 	_log("   - Child: " + child.name + " (type: " + child.get_class() + ")")  # Commented out: initialization logging
			pass
		return
	
	# _log("  ✓ SpellBar found: " + str(spell_bar.name) + " (type: " + spell_bar.get_class() + ")")  # Commented out: initialization logging
	
	# Setup spell bar with equipped spells
	if spell_bar.has_method("setup_spells"):
		spell_bar.setup_spells(equipped_spells)
		spell_bar.select_slot(selected_spell_index)
		# _log("  ✓ Spell bar connected and spells set up")  # Commented out: initialization logging
	else:
		_log_error("SpellBar missing setup_spells() method!")


func _count_equipped_spells() -> int:
	"""Returns the number of equipped spells."""
	var count := 0
	for spell in equipped_spells:
		if spell != null:
			count += 1
	return count


# --- SIGNAL HANDLERS ---

## Sync HealthTracker from PlayerStats (PlayerStats is the source of truth)
func _sync_health_tracker_from_stats(current: int, maximum: int) -> void:
	if health_tracker != null:
		# Update HealthTracker to match PlayerStats values
		health_tracker.max_health = maximum
		health_tracker.current_health = current
		# Update death state
		if current <= 0:
			health_tracker.is_dead = true
		else:
			health_tracker.is_dead = false


func _on_health_changed(current: int, maximum: int) -> void:
	_log("💚 Health changed: " + str(current) + "/" + str(maximum))
	health_changed.emit(current, maximum)


func _on_died() -> void:
	# PlayerStats.player_died signal doesn't pass killer, but we can log it
	_log("💀 PLAYER DIED!")
	is_dead = true
	
	# Disable input
	if input_reader != null:
		input_reader.disable()
		# _log("   Input disabled")  # Commented out: movement logging
	
	# Stop movement
	if mover != null:
		mover.stop()
		# _log("   Movement stopped")  # Commented out: movement logging
	
	# Disable hurtbox (can't take more damage)
	if hurtbox != null:
		hurtbox.disable()
		# _log("   Hurtbox disabled")  # Commented out: enemy AI logging
	
	# Play death animation
	if animator != null:
		animator.force_stop_one_shot()  # Stop any current one-shot animation
		animator.play_one_shot("death", "down")  # Death animation is non-directional
		# _log("   Playing death animation: death")  # Commented out: animation logging
	else:
		_log_error("Cannot play death animation - Animator is null!")
		# If no animator, respawn immediately
		call_deferred("_respawn")
	
	player_died.emit()


func _on_hurt(damage: int, knockback: Vector2, attacker: Node) -> void:
	# _log("💥 PLAYER HIT! Damage: " + str(damage) + " from " + (str(attacker.name) if attacker != null else "unknown"))  # Commented out: enemy AI logging (health changes logged in PlayerStats)
	# _log("   Knockback: " + str(knockback))  # Commented out: enemy AI logging
	
	# SCREEN SHAKE!
	_screen_shake(8.0, 0.2)
	
	# Apply knockback
	if mover != null:
		mover.apply_knockback(knockback * 0.5)
		# _log("   Applied knockback")  # Commented out: movement logging
	
	# Apply damage to PlayerStats (global system) - this will emit health_changed signal
	# HealthTracker will be synced automatically via _sync_health_tracker_from_stats()
	PlayerStats.take_damage(damage)


func _on_animation_finished(anim_name: String) -> void:
	# _log("🎬 Animation finished: " + anim_name)  # Commented out: animation logging
	
	# Death animation finished - respawn
	if anim_name.begins_with("death"):
		# _log("   Death animation complete - respawning...")  # Commented out: animation logging (respawn logs kept)
		call_deferred("_respawn")
		return
	
	# One-shot animation finished, casting is done
	if is_casting:
		is_casting = false
		# _log("   Cast animation complete, is_casting = false")  # Commented out: animation logging


## Respawn the player after death
func _respawn() -> void:
	_log("🔄 RESPAWNING PLAYER...")
	
	# Reset position to spawn point
	global_position = spawn_position
	# _log("   Position reset to " + str(spawn_position))  # Commented out: movement logging
	
	# Reset death state
	is_dead = false
	
	# Reset health, mana, stamina to full (levels/XP are preserved)
	PlayerStats.set_health(PlayerStats.get_max_health())
	PlayerStats.set_mana(PlayerStats.get_max_mana())
	PlayerStats.set_stamina(PlayerStats.get_max_stamina())
	_log("   Health/Mana/Stamina reset to full")
	
	# HealthTracker will be synced automatically via _sync_health_tracker_from_stats() signal
	# Just ensure it's marked as not dead
	if health_tracker != null:
		health_tracker.max_health = PlayerStats.get_max_health()
		health_tracker.current_health = PlayerStats.health
		health_tracker.is_dead = false
		# _log("   HealthTracker reset")  # Commented out: initialization logging
	
	# Re-enable input
	if input_reader != null:
		input_reader.enable()
		# _log("   Input re-enabled")  # Commented out: movement logging
	
	# Re-enable hurtbox
	if hurtbox != null:
		hurtbox.enable()
		# _log("   Hurtbox re-enabled")  # Commented out: enemy AI logging
	
	# Reset casting state
	is_casting = false
	cooldown_timer = 0.0
	_running_enabled = false
	_stamina_drain_accumulator = 0.0
	
	_log("✅ Player respawned successfully!")


## Shake the camera for impact feel
func _screen_shake(intensity: float, duration: float) -> void:
	if _camera == null:
		return
	
	# _log("📳 SCREEN SHAKE! Intensity: " + str(intensity))  # Commented out: visual effect logging
	
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

func take_damage(amount: int, _source: Node = null) -> void:
	# Use PlayerStats as the source of truth - it will sync HealthTracker automatically
	PlayerStats.take_damage(amount)


func get_health() -> int:
	if health_tracker != null:
		return health_tracker.current_health
	return 0
