class_name PotionData
extends ItemData
## Defines potion properties including effect type, potency, and duration.

@export_enum("restore_health", "restore_mana", "restore_stamina", "buff_speed", "buff_strength", "buff_defense") var effect: String = "restore_health"
@export var potency: int = 50
@export var duration: float = 0.0

