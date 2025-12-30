class_name PotionData
extends ItemData
## Defines potion properties including effect type, potency, and duration.

@export_enum("restore_health", "restore_mana", "restore_stamina", "restore_all", "buff_speed", "buff_strength", "buff_defense", "buff_intelligence", "buff_water_spells", "buff_curse_resistance", "area_fire_damage", "buff_random_element", "buff_lightning_chaining", "area_radiant_damage", "area_enemy_slow") var effect: String = "restore_health"
@export var potency: int = 50
@export var duration: float = 0.0

