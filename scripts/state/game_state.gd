extends Node
class_name GameState
## Central game state container.
## Wraps existing systems and provides serialization interface.
## Prepares for server-authoritative state management.

# State data (serializable)
var player_state: PlayerState = PlayerState.new()

# References to existing systems (for backward compatibility)
var player_stats: Node = null
var inventory_system: Node = null
var spell_system: Node = null
var base_stat_leveling: Node = null


func _ready() -> void:
	# Get references to existing autoloads
	player_stats = get_node_or_null("/root/PlayerStats")
	inventory_system = get_node_or_null("/root/InventorySystem")
	spell_system = get_node_or_null("/root/SpellSystem")
	base_stat_leveling = get_node_or_null("/root/BaseStatLeveling")
	
	# Sync initial state from existing systems
	sync_from_systems()


## Syncs state from existing autoload systems.
## Call this periodically or after state changes.
func sync_from_systems() -> void:
	if player_stats == null:
		return
	
	# Sync base stats
	player_state.base_resilience = player_stats.base_resilience
	player_state.base_agility = player_stats.base_agility
	player_state.base_int = player_stats.base_int
	player_state.base_vit = player_stats.base_vit
	
	# Sync current values
	player_state.health = player_stats.health
	player_state.mana = player_stats.mana
	player_state.stamina = player_stats.stamina
	player_state.gold = player_stats.gold
	
	# Sync base stat XP
	if base_stat_leveling != null:
		player_state.base_stat_xp = base_stat_leveling.base_stat_xp.duplicate()
	
	# Sync element levels and XP
	if spell_system != null:
		player_state.element_levels = spell_system.element_levels.duplicate()
		player_state.element_xp = spell_system.element_xp.duplicate()
	
	# Sync inventory (if needed)
	if inventory_system != null:
		# TODO: Sync inventory slots and equipment
		pass


## Syncs state to existing autoload systems.
## Call this when loading from save/network.
func sync_to_systems() -> void:
	if player_stats == null:
		return
	
	# Sync base stats
	player_stats.base_resilience = player_state.base_resilience
	player_stats.base_agility = player_state.base_agility
	player_stats.base_int = player_state.base_int
	player_stats.base_vit = player_state.base_vit
	
	# Sync current values
	player_stats.set_health(player_state.health)
	player_stats.set_mana(player_state.mana)
	player_stats.set_stamina(player_state.stamina)
	player_stats.gold = player_state.gold
	
	# Sync base stat XP
	if base_stat_leveling != null:
		base_stat_leveling.base_stat_xp = player_state.base_stat_xp.duplicate()
	
	# Sync element levels and XP
	if spell_system != null:
		spell_system.element_levels = player_state.element_levels.duplicate()
		spell_system.element_xp = player_state.element_xp.duplicate()


## Serializes entire game state to dictionary.
func to_dict() -> Dictionary:
	sync_from_systems()
	return {
		"player_state": player_state.to_dict(),
		"version": 1  # For future compatibility
	}


## Loads game state from dictionary.
func from_dict(data: Dictionary) -> void:
	var version = data.get("version", 1)
	var player_data = data.get("player_state", {})
	
	player_state.from_dict(player_data)
	sync_to_systems()


## Saves game state to JSON file.
func save_to_file(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	
	var json_string = JSON.stringify(to_dict())
	file.store_string(json_string)
	file.close()
	return true


## Loads game state from JSON file.
func load_from_file(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return false
	
	var data = json.data as Dictionary
	from_dict(data)
	return true

