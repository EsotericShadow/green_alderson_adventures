extends RefCounted
class_name InventorySpaceCalculator
## Utility class for calculating inventory space availability.
## Pure calculation functions with no state.

## Checks if inventory has space for items.
## 
## Args:
##   result: ItemData to check space for
##   result_count: Number of items needed
##   is_potion_recipe: True if this is a potion recipe (scaled potions don't stack)
## 
## Returns: True if inventory has space
static func has_space_for_items(result: ItemData, result_count: int, is_potion_recipe: bool = false) -> bool:
	if result == null or InventorySystem == null:
		return false
	
	if result.stackable and not is_potion_recipe:
		# Stackable: calculate how many items we still need to place after using existing stacks
		var remaining_to_place: int = result_count
		var existing_slot = InventorySystem.find_item_slot(result)
		if existing_slot != -1:
			var slot = InventorySystem.get_slot(existing_slot)
			var space_available = result.max_stack - slot["count"]
			remaining_to_place = max(0, remaining_to_place - space_available)
		
		# If we still need to place items, check if we have enough empty slots
		if remaining_to_place > 0:
			var empty_slots_needed = ceili(float(remaining_to_place) / float(result.max_stack))
			var empty_slots_available = _count_empty_slots()
			return empty_slots_available >= empty_slots_needed
		else:
			# All items fit in existing stack
			return true
	else:
		# Non-stackable or potion recipe: check if we have enough empty slots
		# For potion recipes, scaled potions are new instances, check empty slots only
		var empty_slots_needed = ceili(float(result_count) / float(result.max_stack)) if result.stackable else result_count
		var empty_slots_available = _count_empty_slots()
		return empty_slots_available >= empty_slots_needed


## Counts empty slots in inventory.
## 
## Returns: Number of empty slots
static func _count_empty_slots() -> int:
	if InventorySystem == null:
		return 0
	
	var empty_count: int = 0
	for i in range(InventorySystem.capacity):
		var slot = InventorySystem.get_slot(i)
		if slot["item"] == null:
			empty_count += 1
	
	return empty_count

