extends RefCounted
class_name CraftingUIHandler
## Handler for crafting UI business logic.
## Separates validation display logic from presentation.

## Gets ingredient validation display data.
## 
## Args:
##   ingredient: ItemData ingredient
##   required_count: Required count
## 
## Returns: Dictionary with "text": String, "has_enough": bool, "player_count": int
static func get_ingredient_display_data(ingredient: ItemData, required_count: int) -> Dictionary:
	if ingredient == null or InventorySystem == null:
		return {"text": "", "has_enough": false, "player_count": 0}
	
	var has_enough: bool = InventorySystem.has_item(ingredient, required_count)
	var player_count: int = InventorySystem.get_item_count(ingredient)
	
	var text: String = ingredient.display_name + ": " + str(player_count) + "/" + str(required_count)
	if not has_enough:
		text += " (missing)"
	
	return {
		"text": text,
		"has_enough": has_enough,
		"player_count": player_count
	}

