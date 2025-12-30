extends Node
## Item usage handler for inventory system.
## Handles consumption of consumable items (potions, etc.).

# Logging
var _logger = GameLogger.create("[ItemUsageHandler] ")

# Potion consumption handler
var _potion_handler: PotionConsumptionHandler = PotionConsumptionHandler.new()


func _ready() -> void:
	_logger.log_info("ItemUsageHandler initialized")
	
	# Connect potion handler signals
	_potion_handler.potion_consumed.connect(_on_potion_consumed)
	
	# Set scene tree reference for area effects
	_potion_handler.set_scene_tree(get_tree())


func _on_potion_consumed(potion: PotionData, success: bool) -> void:
	"""Signal handler for potion consumption."""
	if success:
		_logger.log("Potion consumed successfully: " + potion.display_name)
	else:
		_logger.log("Failed to consume potion: " + potion.display_name)


## Uses a consumable item from inventory.
## 
## Args:
##   item: The ItemData to use
##   count: Number of items to use (default 1)
## 
## Returns: True if item was used successfully, false otherwise
func use_item(item: ItemData, count: int = 1) -> bool:
	if item == null:
		_logger.log_error("use_item() called with null item")
		return false
	
	# Only handle consumables
	if item.item_type != "consumable":
		_logger.log("use_item() called on non-consumable: " + item.display_name)
		return false
	
	# Check if player has the item
	if InventorySystem == null:
		_logger.log_error("InventorySystem not available")
		return false
	
	if not InventorySystem.has_item(item, count):
		_logger.log("use_item() called but player doesn't have enough: " + item.display_name + " x" + str(count))
		return false
	
	# Handle potions
	if item is PotionData:
		var potion: PotionData = item as PotionData
		var success: bool = _potion_handler.consume_potion(potion)
		if success:
			# Remove one potion from inventory
			InventorySystem.remove_item(potion, 1)
			# Emit EventBus signal
			if EventBus != null:
				EventBus.item_used.emit(potion)
		return success
	
	# Other consumables (future)
	_logger.log("use_item() called on unsupported consumable type: " + item.display_name)
	return false


## Uses an item at a specific slot index.
## 
## Args:
##   slot_index: Index of the slot containing the item to use
## 
## Returns: True if item was used successfully, false otherwise
func use_item_at_slot(slot_index: int) -> bool:
	if InventorySystem == null:
		_logger.log_error("InventorySystem not available")
		return false
	
	if slot_index < 0 or slot_index >= InventorySystem.capacity:
		_logger.log_error("use_item_at_slot() called with invalid slot index: " + str(slot_index))
		return false
	
	var slot: Dictionary = InventorySystem.get_slot(slot_index)
	var item: ItemData = slot.get("item")
	if item == null:
		return false
	
	return use_item(item, 1)

