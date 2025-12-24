class_name EquipmentData
extends ItemData
## Equipment items that can be worn in equipment slots.
## Provides stat bonuses when equipped.

@export_enum("head", "body", "gloves", "boots", "weapon", "shield", "ring") var slot: String = "weapon"
@export var str_bonus: int = 0
@export var dex_bonus: int = 0
@export var int_bonus: int = 0
@export var vit_bonus: int = 0


func _init() -> void:
	item_type = "equipment"
	stackable = false
	max_stack = 1

