class_name PotionData
extends ItemData
## Consumable potions with instant or timed effects.
## Restore effects are instant (duration = 0), buffs have duration > 0.

@export_enum("restore_health", "restore_mana", "restore_stamina", "buff_speed", "buff_strength", "buff_defense") var effect: String = "restore_health"
@export var potency: int = 50
@export var duration: float = 0.0


func _init() -> void:
	item_type = "consumable"
	stackable = true

