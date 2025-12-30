extends Node
## Global carry weight system (autoload singleton).
## Manages player carry weight calculations and weight-based effects.

# Logging
var _logger = GameLogger.create("[CarryWeightSystem] ")


func _ready() -> void:
	_logger.log_info("CarryWeightSystem initialized")


## Returns maximum carry weight in kg based on resilience.
## 
## Args:
##   resilience: Total resilience stat value
## 
## Returns: Maximum carry weight in kg
func get_max_carry_weight(resilience: int) -> float:
	return StatFormulas.calculate_max_carry_weight(resilience)


## Calculates current total weight of all items in inventory and equipment.
## 
## Returns: Current total weight in kg
func get_current_carry_weight() -> float:
	if InventorySystem == null:
		return 0.0
	
	var total_weight: float = 0.0
	
	# Count inventory items
	for i in range(InventorySystem.capacity):
		var slot: Dictionary = InventorySystem.get_slot(i)
		var item: ItemData = slot.get("item")
		var count: int = slot.get("count", 0)
		if item != null and count > 0:
			total_weight += item.weight * count
	
	# Also count equipped items
	if EquipmentSystem != null:
		for slot_name in EquipmentSystem.equipment:
			var item: EquipmentData = EquipmentSystem.equipment[slot_name]
			if item != null:
				total_weight += item.weight
	
	return total_weight


## Checks if player can carry additional items.
## 
## Args:
##   item: ItemData to check
##   count: Number of items to check
##   resilience: Total resilience stat value
## 
## Returns: True if player can carry the items
func can_carry_item(item: ItemData, count: int, resilience: int) -> bool:
	if item == null:
		return false
	
	var current_weight: float = get_current_carry_weight()
	var additional_weight: float = item.weight * count
	var max_weight: float = get_max_carry_weight(resilience)
	
	return (current_weight + additional_weight) <= max_weight


## Returns movement speed multiplier when carrying heavy load (85%+ weight).
## 
## Args:
##   resilience: Total resilience stat value
## 
## Returns: Speed multiplier (0.1 to 1.0)
func get_carry_weight_slow_multiplier(resilience: int) -> float:
	var current_weight: float = get_current_carry_weight()
	var max_weight: float = get_max_carry_weight(resilience)
	return StatFormulas.calculate_carry_weight_slow_multiplier(current_weight, max_weight)

