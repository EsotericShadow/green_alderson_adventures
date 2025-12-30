extends RefCounted
class_name InventoryUIHandler
## Handler for inventory UI business logic.
## Separates business logic from presentation.

## Handles slot click logic (equipment equipping).
## 
## Args:
##   slot_index: Index of clicked slot
## 
## Returns: Dictionary with "success": bool and "message": String
static func handle_slot_click(slot_index: int) -> Dictionary:
	if InventorySystem == null:
		return {"success": false, "message": "InventorySystem not available"}
	
	var slot_data: Dictionary = InventorySystem.get_slot(slot_index)
	if slot_data["item"] == null:
		return {"success": false, "message": "Slot is empty"}
	
	# If it's equipment, try to equip it
	if slot_data["item"] is EquipmentData:
		return equip_slot(slot_index)
	
	return {"success": false, "message": "Item is not equipment"}


static func equip_slot(slot_index: int) -> Dictionary:
	if InventorySystem == null:
		return {"success": false, "message": "InventorySystem not available"}
	var slot_data: Dictionary = InventorySystem.get_slot(slot_index)
	var equip_item: EquipmentData = slot_data.get("item")
	if equip_item == null or not (equip_item is EquipmentData):
		return {"success": false, "message": "Item is not equipment"}
	if EquipmentSystem == null:
		return {"success": false, "message": "EquipmentSystem not available"}
	if not EquipmentSystem.equip(equip_item):
		return {"success": false, "message": "Failed to equip item"}
	InventorySystem.set_slot(slot_index, null, 0)
	return {"success": true, "message": "Equipped: " + equip_item.display_name}


static func unequip_slot(slot_name: String) -> Dictionary:
	if InventorySystem == null:
		return {"success": false, "message": "InventorySystem not available"}
	var equipped: EquipmentData = InventorySystem.get_equipped(slot_name)
	if equipped == null:
		return {"success": false, "message": "Slot is empty"}
	var result: EquipmentData = InventorySystem.unequip(slot_name)
	if result == null:
		return {"success": false, "message": "Inventory full"}
	return {"success": true, "message": "Unequipped: " + result.display_name}
