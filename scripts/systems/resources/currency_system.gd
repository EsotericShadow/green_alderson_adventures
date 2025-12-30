extends Node
## Global currency system (autoload singleton).
## Manages gold by storing it as an ItemData stack inside the InventorySystem.

var _logger = GameLogger.create("[CurrencySystem] ")

signal gold_changed(amount: int)

const GOLD_ITEM_ID: String = "gold_coins"

var gold: int = 0  # Mirrors inventory gold total for backwards compatibility.
var _gold_item: ItemData = null


func _ready() -> void:
	_logger.log_info("CurrencySystem initialized")
	if ResourceManager != null:
		_gold_item = ResourceManager.load_item(GOLD_ITEM_ID)
	else:
		_logger.log_error("ResourceManager unavailable - cannot load gold item")
	
	if _gold_item == null:
		_logger.log_warning("Gold item data not found; falling back to internal counter")
	
	_ensure_inventory_connection()
	_logger.log_info("Initial gold: " + str(gold))


func _on_inventory_changed() -> void:
	_refresh_gold_total()


func _ensure_inventory_connection() -> void:
	if InventorySystem == null:
		call_deferred("_ensure_inventory_connection")
		return
	if not InventorySystem.inventory_changed.is_connected(_on_inventory_changed):
		InventorySystem.inventory_changed.connect(_on_inventory_changed)
		_refresh_gold_total(true)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	
	if _gold_item != null and InventorySystem != null:
		var leftover: int = InventorySystem.add_item(_gold_item, amount)
		var deposited: int = amount - leftover
		if leftover > 0:
			_logger.log_warning("Inventory full: " + str(leftover) + " gold could not be added")
		if deposited > 0:
			_logger.log("Gold added to inventory: +" + str(deposited))
			_refresh_gold_total()
		return
	
	# Fallback to internal counter if inventory/gold item unavailable
	gold += amount
	_logger.log("Gold added (fallback): +" + str(amount) + " (total: " + str(gold) + ")")
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if amount < 0:
		_logger.log_error("spend_gold() called with negative amount: " + str(amount))
		return false
	if not has_gold(amount):
		_logger.log("Failed to spend " + str(amount) + " gold (insufficient)")
		return false
	
	if _gold_item != null and InventorySystem != null:
		var success: bool = InventorySystem.remove_item(_gold_item, amount)
		if not success:
			_logger.log_warning("InventorySystem failed to remove gold even though it should exist")
			return false
		_logger.log("Gold spent from inventory: -" + str(amount))
		_refresh_gold_total()
		return true
	
	gold -= amount
	_logger.log("Gold spent (fallback): -" + str(amount) + " (total: " + str(gold) + ")")
	gold_changed.emit(gold)
	return true


func has_gold(amount: int) -> bool:
	if _gold_item != null and InventorySystem != null:
		return InventorySystem.get_item_count(_gold_item) >= amount
	return gold >= amount


func _refresh_gold_total(force_emit: bool = false) -> void:
	var new_total: int = _get_inventory_gold_count()
	if force_emit or new_total != gold:
		gold = new_total
		gold_changed.emit(gold)


func _get_inventory_gold_count() -> int:
	if _gold_item == null or InventorySystem == null:
		return gold
	return InventorySystem.get_item_count(_gold_item)
