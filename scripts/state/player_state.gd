extends Resource
class_name PlayerState
## Serializable player state data.
## Contains all player data that needs to be saved/synced.

# Base stats
@export var base_resilience: int = 5
@export var base_agility: int = 5
@export var base_int: int = 5
@export var base_vit: int = 5

# Current values
@export var health: int = 100
@export var mana: int = 75
@export var stamina: int = 50
@export var gold: int = 0

# Base stat XP
@export var base_stat_xp: Dictionary = {
	"resilience": 0,
	"agility": 0,
	"int": 0,
	"vit": 0
}

# Element levels and XP
@export var element_levels: Dictionary = {
	"fire": 1,
	"water": 1,
	"earth": 1,
	"air": 1
}

@export var element_xp: Dictionary = {
	"fire": 0,
	"water": 0,
	"earth": 0,
	"air": 0
}

# Inventory (simplified - full inventory state would be separate)
@export var inventory_slots: Array[Dictionary] = []
@export var equipment: Dictionary = {}

# Spell hotbar
@export var equipped_spells: Array[String] = []  # Spell IDs


## Converts player state to dictionary for serialization.
func to_dict() -> Dictionary:
	return {
		"base_resilience": base_resilience,
		"base_agility": base_agility,
		"base_int": base_int,
		"base_vit": base_vit,
		"health": health,
		"mana": mana,
		"stamina": stamina,
		"gold": gold,
		"base_stat_xp": base_stat_xp.duplicate(),
		"element_levels": element_levels.duplicate(),
		"element_xp": element_xp.duplicate(),
		"inventory_slots": inventory_slots.duplicate(),
		"equipment": equipment.duplicate(),
		"equipped_spells": equipped_spells.duplicate()
	}


## Loads player state from dictionary.
func from_dict(data: Dictionary) -> void:
	base_resilience = data.get("base_resilience", 5)
	base_agility = data.get("base_agility", 5)
	base_int = data.get("base_int", 5)
	base_vit = data.get("base_vit", 5)
	health = data.get("health", 100)
	mana = data.get("mana", 75)
	stamina = data.get("stamina", 50)
	gold = data.get("gold", 0)
	base_stat_xp = data.get("base_stat_xp", {}).duplicate()
	element_levels = data.get("element_levels", {}).duplicate()
	element_xp = data.get("element_xp", {}).duplicate()
	inventory_slots = data.get("inventory_slots", []).duplicate()
	equipment = data.get("equipment", {}).duplicate()
	equipped_spells = data.get("equipped_spells", []).duplicate()

