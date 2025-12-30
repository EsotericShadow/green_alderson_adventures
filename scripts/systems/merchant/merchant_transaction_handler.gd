extends RefCounted
class_name MerchantTransactionHandler
## Handles merchant buy/sell transaction logic.
## Pure business logic - no UI dependencies.

# Logging
## NOTE: Intentionally no logger here. This class is pure-static helper logic.


## Calculates sell price for an item.
## 
## Args:
##   item: ItemData to sell
##   merchant_data: MerchantData with stock/prices
## 
## Returns: Sell price (50% of buy price if merchant has it, else 10)
static func calculate_sell_price(item: ItemData, merchant_data: MerchantData) -> int:
	if merchant_data == null or item == null:
		return 10  # Default
	
	var stock_index: int = merchant_data.stock.find(item)
	if stock_index >= 0:
		var buy_price: int = merchant_data.prices[stock_index]
		return int(buy_price / 2.0)  # 50% of buy price
	
	# Item not in merchant stock, use default sell price
	return 10


## Checks if player can buy an item (has gold and inventory space).
## 
## Args:
##   item: ItemData to buy
##   price: Buy price
## 
## Returns: Dictionary with "can_buy": bool and "reason": String
static func can_buy_item(item: ItemData, price: int) -> Dictionary:
	if item == null:
		return {"can_buy": false, "reason": "Invalid item"}
	
	# Check gold
	if PlayerStats == null:
		return {"can_buy": false, "reason": "PlayerStats not available"}
	
	if not PlayerStats.has_gold(price):
		return {"can_buy": false, "reason": "Insufficient gold"}
	
	# Check inventory space
	if InventorySystem == null:
		return {"can_buy": false, "reason": "InventorySystem not available"}
	
	var can_add: bool = false
	if item.stackable:
		var existing_slot = InventorySystem.find_item_slot(item)
		if existing_slot != -1:
			var slot = InventorySystem.get_slot(existing_slot)
			var space_available = item.max_stack - slot["count"]
			can_add = space_available > 0
		else:
			# Check if we have any empty slots
			for i in range(InventorySystem.capacity):
				var slot = InventorySystem.get_slot(i)
				if slot["item"] == null:
					can_add = true
					break
	else:
		# Non-stackable: check if we have an empty slot
		for i in range(InventorySystem.capacity):
			var slot = InventorySystem.get_slot(i)
			if slot["item"] == null:
				can_add = true
				break
	
	if not can_add:
		return {"can_buy": false, "reason": "Inventory full"}
	
	return {"can_buy": true, "reason": ""}


## Executes a buy transaction.
## 
## Args:
##   item: ItemData to buy
##   price: Buy price
## 
## Returns: Dictionary with "success": bool and "message": String
static func buy_item(item: ItemData, price: int) -> Dictionary:
	if item == null:
		return {"success": false, "message": "Invalid item"}
	
	# Check if can buy
	var can_buy_result = can_buy_item(item, price)
	if not can_buy_result["can_buy"]:
		return {"success": false, "message": can_buy_result["reason"]}
	
	# Execute transaction
	if PlayerStats.spend_gold(price):
		var leftover: int = InventorySystem.add_item(item, 1)
		if leftover > 0:
			# Refund gold if inventory full (should not happen if can_buy checked)
			PlayerStats.add_gold(price)
			return {"success": false, "message": "Failed to add item to inventory"}
		else:
			return {"success": true, "message": "Bought: " + item.display_name + " for " + str(price) + " gold"}
	else:
		return {"success": false, "message": "Failed to spend gold"}


## Executes a sell transaction.
## 
## Args:
##   item: ItemData to sell
##   count: Number of items to sell
##   merchant_data: MerchantData for price calculation
## 
## Returns: Dictionary with "success": bool and "message": String
static func sell_item(item: ItemData, count: int, merchant_data: MerchantData) -> Dictionary:
	if item == null:
		return {"success": false, "message": "Invalid item"}
	
	if InventorySystem == null:
		return {"success": false, "message": "InventorySystem not available"}
	
	if not InventorySystem.has_item(item, count):
		return {"success": false, "message": "Not enough items to sell"}
	
	# Calculate sell price
	var sell_price: int = calculate_sell_price(item, merchant_data)
	var total_sell_price: int = sell_price * count
	
	# Remove item from inventory
	if InventorySystem.remove_item(item, count):
		# Add gold
		PlayerStats.add_gold(total_sell_price)
		return {"success": true, "message": "Sold: " + item.display_name + " x" + str(count) + " for " + str(total_sell_price) + " gold"}
	else:
		return {"success": false, "message": "Failed to remove item from inventory"}
