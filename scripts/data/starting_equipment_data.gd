class_name StartingEquipmentData
extends Resource
## Data resource for defining starting equipment.
## Used to configure initial player equipment without hardcoding in scripts.

@export var equipment: Array[Dictionary] = []
## Array of dictionaries with format: { "slot": String, "equipment_id": String }
## Example: { "slot": "weapon", "equipment_id": "dark_wizard_corrupt_staff" }
## 
## Valid slots: "head", "body", "gloves", "boots", "weapon", "book", "ring1", "ring2", "legs", "amulet"
## For ring items, use "ring" as slot and the system will auto-assign to ring1 or ring2

