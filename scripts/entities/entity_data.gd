extends Resource
class_name EntityData
## Serializable entity state data.
## Can be saved to disk, synced over network, or stored in database.
## Base class for all entity data (player, enemy, NPC).

@export var entity_id: String = ""  # Unique identifier (UUID or network ID)
@export var entity_type: String = "unknown"  # "player", "enemy", "npc"
@export var position: Vector2 = Vector2.ZERO
@export var direction: String = "down"
@export var is_dead: bool = false

## Converts entity data to dictionary for serialization.
func to_dict() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_type": entity_type,
		"position": {"x": position.x, "y": position.y},
		"direction": direction,
		"is_dead": is_dead
	}


## Loads entity data from dictionary.
func from_dict(data: Dictionary) -> void:
	entity_id = data.get("entity_id", "")
	entity_type = data.get("entity_type", "unknown")
	var pos_data = data.get("position", {})
	position = Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
	direction = data.get("direction", "down")
	is_dead = data.get("is_dead", false)

