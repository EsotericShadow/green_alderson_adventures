class_name EquipmentData
extends ItemData
## Equipment items that can be equipped to player slots.
## Automatically sets item_type to "equipment" and stackable to false.

@export_enum("head", "body", "gloves", "boots", "weapon", "shield", "ring") var slot: String = "weapon"
@export var resilience_bonus: int = 0  # Formerly str_bonus
@export var agility_bonus: int = 0  # Formerly dex_bonus
@export var int_bonus: int = 0
@export var vit_bonus: int = 0
@export var flat_damage_bonus: int = 0  # Flat damage added to spells
@export var damage_percentage_bonus: float = 0.0  # Percentage damage multiplier (0.1 = +10%)


func _init() -> void:
	# EquipmentData automatically has item_type = "equipment" and stackable = false
	item_type = "equipment"
	stackable = false

