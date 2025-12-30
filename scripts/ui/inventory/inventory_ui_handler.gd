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
		var equip_item: EquipmentData = slot_data["item"] as EquipmentData
		if EquipmentSystem != null and EquipmentSystem.equip(equip_item):
			return {"success": true, "message": "Equipped: " + equip_item.display_name}
		else:
			return {"success": false, "message": "Failed to equip item"}
	
	return {"success": false, "message": "Item is not equipment"}

