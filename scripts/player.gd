extends BaseEntity

## COORDINATOR: Player controller
## Makes ALL decisions about player behavior
## Delegates actual work to worker nodes

signal player_died
signal health_changed(current: int, max_health: int)

# Movement speeds (loaded from GameBalance config)
# These are kept as fallback defaults but should use GameBalance getters
var walk_speed: float = 120.0  # Use GameBalance.get_walk_speed() instead
var run_speed: float = 220.0  # Use GameBalance.get_run_speed() instead
# max_health now comes from PlayerStats.get_max_health()
var stamina_drain_rate: float = 20.0  # Use GameBalance.get_stamina_drain_rate() instead
var min_stamina_to_run: int = 5  # Use GameBalance.get_min_stamina_to_run() instead

# Worker references (mover, animator, health_tracker, hurtbox inherited from BaseEntity)
@onready var input_reader: InputReader = $InputReader
@onready var spell_spawner: SpellSpawner = $SpellSpawner
@onready var running_state_manager: RunningStateManager = $RunningStateManager
@onready var spell_caster: SpellCaster = $SpellCaster
@onready var spell_selection_manager: SpellSelectionManager = $SpellSelectionManager
@onready var camera_effects_worker: CameraEffectsWorker = $CameraEffectsWorker

# State
var last_direction: String = "down"
var is_dead: bool = false
var spawn_position: Vector2 = Vector2(0, -2)  # Default spawn position (will be set from scene)

# Logging (logger inherited from BaseEntity)
var _last_logged_state := ""


func _ready() -> void:
	# Initialize logger before calling super (BaseEntity checks if null)
	_logger = GameLogger.create("[PLAYER] ")
	# Call parent _ready() to initialize BaseEntity (calls _setup_workers())
	super._ready()
	
	add_to_group("player")
	spawn_position = global_position  # Store initial spawn position
	_logger.log_debug("Player spawned at " + str(global_position))
	_logger.log_debug("Checking workers...")
	
	# Connect animator finished signal
	if animator != null:
		animator.finished.connect(_on_animation_finished)
		_logger.log_debug("  ✓ Animator ready")
	
	# Set up player-specific workers
	if input_reader == null:
		_log_error("InputReader worker is MISSING! Controls will not work.")
	else:
		_logger.log_debug("  ✓ InputReader ready")
	
	# Configure health_tracker (player-specific: sync with PlayerStats)
	if health_tracker != null:
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
		_logger.log_info("  ✓ HealthTracker ready (HP: " + str(max_hp) + " from PlayerStats)")
	
	# Connect hurtbox signal
	if hurtbox != null:
		hurtbox.hurt.connect(_on_hurt)
		_logger.log_debug("  ✓ Hurtbox ready")
	
	if spell_spawner == null:
		_log_error("SpellSpawner worker is MISSING! Spells will not work.")
	else:
		_logger.log_debug("  ✓ SpellSpawner ready")
	
	if spell_caster == null:
		_log_error("SpellCaster worker is MISSING! Spell casting will not work.")
	else:
		spell_caster.spell_spawner = spell_spawner
		_logger.log_debug("  ✓ SpellCaster ready")
	
	if running_state_manager == null:
		_log_error("RunningStateManager worker is MISSING! Running will not work.")
	else:
		running_state_manager.input_reader = input_reader
		# Load config from GameBalance
		if GameBalance != null:
			running_state_manager.stamina_drain_rate = GameBalance.get_stamina_drain_rate()
			running_state_manager.min_stamina_to_run = GameBalance.get_min_stamina_to_run()
			walk_speed = GameBalance.get_walk_speed()
			run_speed = GameBalance.get_run_speed()
		else:
			# Fallback to defaults
			running_state_manager.stamina_drain_rate = stamina_drain_rate
			running_state_manager.min_stamina_to_run = min_stamina_to_run
		_logger.log_debug("  ✓ RunningStateManager ready")
	
	# Set up spell selection manager
	if spell_selection_manager == null:
		_log_error("SpellSelectionManager worker is MISSING! Spell selection will not work.")
	else:
		_logger.log_debug("  ✓ SpellSelectionManager ready")
	
	# Set up camera effects worker
	if camera_effects_worker == null:
		_logger.log_debug("  ⚠ CameraEffectsWorker not found (screen shake disabled)")
	else:
		_logger.log_debug("  ✓ CameraEffectsWorker ready")
	_logger.log_info("Player ready! All systems: " + ("GO" if _all_workers_ready() else "SOME MISSING"))


func _get_entity_type() -> String:
	return "player"


func _all_workers_ready() -> bool:
	return mover != null and animator != null and input_reader != null and health_tracker != null and hurtbox != null and spell_spawner != null and running_state_manager != null and spell_caster != null and spell_selection_manager != null


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update spell caster cooldown
	if spell_caster != null:
		spell_caster.update(delta)
	
	# --- READ INPUT ---
	if input_reader == null:
		return
	
	var input_vec := input_reader.get_movement()
	
	# Update running state manager
	if running_state_manager != null:
		running_state_manager.update_running_state(delta, input_vec)
	
	# Determine if player should actually run
	var wants_run: bool = false
	if running_state_manager != null:
		wants_run = running_state_manager.can_run()
	
	# --- HANDLE SPELL SELECTION AND CASTING (1-9, 0) ---
	for i in range(10):
		var action_name := "spell_" + str(i + 1) if i < 9 else "spell_0"
		if input_reader.is_action_just_pressed(action_name):
			# Get current selected index
			var current_selected: int = 0
			if spell_selection_manager != null:
				current_selected = spell_selection_manager.selected_spell_index
			
			# If already selected, cast it; otherwise just select
			if current_selected == i:
				# Cast the spell
				var spell := get_selected_spell()
				if spell != null and spell_caster != null:
					var cast_dir := last_direction
					if input_vec.length() > 0.0:
						cast_dir = DirectionUtils.vector_to_dir8(input_vec, last_direction)
					
					_start_spell_cast(spell, cast_dir)
			else:
				# Select the spell
				if spell_selection_manager != null:
					spell_selection_manager.select_spell(i)
				else:
					_select_spell(i)  # Fallback
			break
	
	# --- HANDLE RUN JUMP ---
	if input_reader.is_action_just_pressed("jump") and wants_run and input_vec.length() > 0.0:
		if animator != null and not animator.is_locked():
			last_direction = DirectionUtils.vector_to_dir8(input_vec, last_direction)
			_logger.log_debug("🦘 Run jump! Direction: " + last_direction)
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
		_logger.log_debug("State: " + current_state)
		_last_logged_state = current_state
	
	# Don't change animation if one-shot is playing (but movement still works)
	if not animator.is_locked():
		if input_vec.length() > 0.0:
			last_direction = DirectionUtils.vector_to_dir8(input_vec, last_direction)
			var anim_type := "run" if wants_run else "walk"
			animator.play(anim_type, last_direction)
		else:
			animator.play("idle", last_direction)


func _start_spell_cast(spell: SpellData, direction: String) -> void:
	"""Starts casting a spell.
	
	Args:
		spell: The spell to cast
		direction: Direction to cast (8-direction string)
	"""
	if spell_caster == null:
		_log_error("Cannot cast spell - SpellCaster is null!")
		return
	
	# Z-index: below player when facing north, above when facing south/sides
	var z_index_value := 2
	if DirectionUtils.is_facing_north(direction):
		z_index_value = 1
	
	# Try to cast (checks cooldown, mana, etc.)
	if not spell_caster.try_cast(spell, direction, global_position, z_index_value):
		return  # Cannot cast (cooldown, no mana, etc.)
	
	# Play cast animation
	spell_caster.start_cast_animation(spell, direction, animator)
	
	# Spawn spell after delay
	var cast_delay := spell.cooldown * 0.583  # fireball_cast_delay ratio (0.35 / 0.6)
	get_tree().create_timer(cast_delay).timeout.connect(
		_spawn_spell.bind(spell, direction, z_index_value)
	)


func _spawn_spell(spell: SpellData, direction: String, z_index_value: int) -> void:
	"""Spawns the spell projectile after cast delay.
	
	Args:
		spell: The spell to spawn
		direction: Direction to cast
		z_index_value: Z-index for projectile
	"""
	if spell_caster == null:
		return
	
	var projectile := spell_caster.spawn_spell(spell, direction, global_position, z_index_value)
	if projectile == null:
		_log_error("Failed to spawn spell projectile!")






func get_selected_spell() -> SpellData:
	"""Returns the currently selected spell - delegates to SpellSelectionManager."""
	if spell_selection_manager != null:
		return spell_selection_manager.get_selected_spell()
	# Fallback for backwards compatibility
	return null


func _select_spell(index: int) -> void:
	"""Selects a spell slot (0-9) - delegates to SpellSelectionManager."""
	if spell_selection_manager != null:
		spell_selection_manager.select_spell(index)


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
	_logger.log_info("💀 PLAYER DIED!")
	is_dead = true
	
	# Disable input
	if input_reader != null:
		input_reader.disable()
		_logger.log_debug("   Input disabled")
	
	# Stop movement
	if mover != null:
		mover.stop()
		_logger.log_debug("   Movement stopped")
	
	# Disable hurtbox (can't take more damage)
	if hurtbox != null:
		hurtbox.disable()
		_logger.log_debug("   Hurtbox disabled")
	
	# Play death animation
	if animator != null:
		animator.force_stop_one_shot()  # Stop any current one-shot animation
		animator.play_one_shot("death", "down")  # Death animation is non-directional
		_logger.log_debug("   Playing death animation: death")
	else:
		_log_error("Cannot play death animation - Animator is null!")
		# If no animator, respawn immediately
		call_deferred("_respawn")
	
	player_died.emit()
	entity_died.emit(self)  # Also emit BaseEntity signal


func _on_hurt(damage: int, knockback: Vector2, attacker: Node) -> void:
	_logger.log_debug("💥 PLAYER HIT! Damage: " + str(damage) + " from " + (str(attacker.name) if attacker != null else "unknown"))
	_logger.log_debug("   Knockback: " + str(knockback))
	
	# SCREEN SHAKE! - delegates to CameraEffectsWorker
	if camera_effects_worker != null:
		camera_effects_worker.screen_shake(8.0, 0.2)
	else:
		_logger.log_warning("CameraEffectsWorker not available - screen shake disabled")
	
	# Apply knockback
	if mover != null:
		mover.apply_knockback(knockback * 0.5)
		_logger.log_debug("   Applied knockback")
	
	# Apply damage to PlayerStats (global system) - this will emit health_changed signal
	# HealthTracker will be synced automatically via _sync_health_tracker_from_stats()
	PlayerStats.take_damage(damage)


func _on_animation_finished(anim_name: String) -> void:
	# _log("🎬 Animation finished: " + anim_name)  # Will use DEBUG level in Phase 4
	
	# Death animation finished - respawn
	if anim_name.begins_with("death"):
		# _log("   Death animation complete - respawning...")  # Will use DEBUG level in Phase 4
		call_deferred("_respawn")
		return
	
	# Cast animation finished - notify spell caster
	if spell_caster != null and anim_name.begins_with("fireball"):
		spell_caster.on_animation_finished(anim_name)


## Respawn the player after death
func _respawn() -> void:
	_logger.log_info("🔄 RESPAWNING PLAYER...")
	
	# Reset position to spawn point
	global_position = spawn_position
	_logger.log_debug("   Position reset to " + str(spawn_position))
	
	# Reset death state
	is_dead = false
	
	# Reset health, mana, stamina to full (levels/XP are preserved)
	PlayerStats.set_health(PlayerStats.get_max_health())
	PlayerStats.set_mana(PlayerStats.get_max_mana())
	PlayerStats.set_stamina(PlayerStats.get_max_stamina())
	_logger.log_info("   Health/Mana/Stamina reset to full")
	
	# HealthTracker will be synced automatically via _sync_health_tracker_from_stats() signal
	# Just ensure it's marked as not dead
	if health_tracker != null:
		health_tracker.max_health = PlayerStats.get_max_health()
		health_tracker.current_health = PlayerStats.health
		health_tracker.is_dead = false
		_logger.log_debug("   HealthTracker reset")
	
	# Re-enable input
	if input_reader != null:
		input_reader.enable()
		_logger.log_debug("   Input re-enabled")
	
	# Re-enable hurtbox
	if hurtbox != null:
		hurtbox.enable()
		_logger.log_debug("   Hurtbox re-enabled")
	
	# Reset casting and running state
	if spell_caster != null:
		spell_caster.reset()
	if running_state_manager != null:
		running_state_manager.reset()
	
	_logger.log_info("✅ Player respawned successfully!")


# --- PUBLIC API ---

func take_damage(amount: int, _source: Node = null) -> void:
	# Use PlayerStats as the source of truth - it will sync HealthTracker automatically
	PlayerStats.take_damage(amount)


func get_health() -> int:
	if health_tracker != null:
		return health_tracker.current_health
	return 0
