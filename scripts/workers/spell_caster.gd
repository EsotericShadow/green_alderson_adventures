extends BaseWorker
class_name SpellCaster

## WORKER: Manages spell casting cooldowns and state
## Does ONE thing: manages spell casting state and cooldowns
## Does NOT: decide when to cast, handle spell spawning directly

# References (set by coordinator)
var spell_spawner: SpellSpawner = null

# State
var cooldown_timer: float = 0.0
var is_casting: bool = false


func _on_initialize() -> void:
	"""Initialize spell caster."""
	# No additional initialization needed - BaseWorker handles logging
	pass


func update(delta: float) -> void:
	"""Updates cooldown timer.
	
	Args:
		delta: Frame delta time
	"""
	if cooldown_timer > 0.0:
		cooldown_timer -= delta


func can_cast() -> bool:
	"""Returns true if a spell can currently be cast (no cooldown, not already casting)."""
	return cooldown_timer <= 0.0 and not is_casting


func try_cast(spell: SpellData, direction: String, _spawn_position: Vector2, _z_index_value: int) -> bool:
	"""Attempts to cast a spell.
	
	Args:
		spell: The spell data to cast
		direction: Direction to cast (8-direction string)
		spawn_position: Position to spawn the spell
		z_index_value: Z-index for the projectile
		
	Returns:
		True if spell was cast successfully, false otherwise
	"""
	if spell == null:
		_logger.log_error("try_cast() called with null spell")
		return false
	
	# Check if we can cast (cooldown and casting state)
	if not can_cast():
		return false
	
	# Check mana cost via SpellSystem
	if SpellSystem != null and not SpellSystem.can_cast(spell):
		return false
	
	# Consume mana
	if not PlayerStats.consume_mana(spell.mana_cost):
		_logger.log_error("Failed to consume mana for spell cast!")
		return false
	
	# Set cooldown and casting state
	cooldown_timer = spell.cooldown
	is_casting = true
	
	_logger.log_debug("🔥 Starting spell cast: " + spell.display_name + " facing " + direction)
	
	return true


func start_cast_animation(_spell: SpellData, direction: String, animator: Animator) -> void:
	"""Starts the cast animation.
	
	Args:
		spell: The spell being cast
		direction: Direction to cast
		animator: Animator worker to play animation
	"""
	if animator == null:
		_logger.log_error("Cannot play cast animation - Animator is null!")
		return
	
	# Play cast animation (one-shot, but doesn't lock movement)
	animator.play_one_shot("fireball", direction)


func spawn_spell(spell: SpellData, direction: String, spawn_position: Vector2, z_index_value: int) -> Node:
	"""Spawns the spell projectile.
	
	Args:
		spell: The spell data
		direction: Direction to cast
		spawn_position: Position to spawn
		z_index_value: Z-index for projectile
		
	Returns:
		The spawned projectile node, or null if failed
	"""
	if spell_spawner == null:
		_logger.log_error("Cannot spawn spell - SpellSpawner is null!")
		return null
	
	is_casting = false
	
	var projectile := spell_spawner.spawn_fireball(direction, spawn_position, z_index_value, spell)
	if projectile == null:
		_logger.log_error("SpellSpawner.spawn_fireball returned null!")
	
	return projectile


func on_animation_finished(_anim_name: String) -> void:
	"""Called when cast animation finishes.
	
	Args:
		_anim_name: Name of the finished animation
	"""
	# Cast animation finished
	if is_casting:
		is_casting = false
		_logger.log_debug("   Cast animation complete, is_casting = false")


func reset() -> void:
	"""Resets casting state (used for respawn, death, etc.)."""
	is_casting = false
	cooldown_timer = 0.0


func get_cooldown_remaining() -> float:
	"""Returns remaining cooldown time."""
	return cooldown_timer


func get_is_casting() -> bool:
	"""Returns true if currently casting."""
	return is_casting
