extends CanvasLayer
## Merchant UI panel.
## Displays merchant stock and player inventory for buying/selling.

# Logging
var _logger = GameLogger.create("[MerchantUI] ")

@onready var control: Control = $Control
@onready var merchant_name: Label = $Control/PanelContainer/MarginContainer/VBoxContainer/MerchantName
@onready var greeting: Label = $Control/PanelContainer/MarginContainer/VBoxContainer/Greeting
@onready var stock_list: ItemList = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/StockPanel/StockList
@onready var inventory_list: ItemList = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/InventoryPanel/InventoryList
@onready var buy_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/TransactionContainer/BuyButton
@onready var sell_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/TransactionContainer/SellButton
@onready var gold_display: Label = $Control/PanelContainer/MarginContainer/VBoxContainer/TransactionContainer/GoldDisplay
@onready var close_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/CloseButton

var current_merchant: MerchantData = null
var selected_stock_index: int = -1
var selected_inventory_index: int = -1


func _ready() -> void:
	_logger.log("MerchantUI initialized")
	
	# Connect to EventBus
	if EventBus != null:
		EventBus.merchant_opened.connect(open_merchant)
		EventBus.merchant_closed.connect(close_merchant)
	
	# Connect UI signals
	if stock_list != null:
		stock_list.item_selected.connect(_on_stock_item_selected)
	if inventory_list != null:
		inventory_list.item_selected.connect(_on_inventory_item_selected)
	if buy_button != null:
		buy_button.pressed.connect(_on_buy_button_pressed)
	if sell_button != null:
		sell_button.pressed.connect(_on_sell_button_pressed)
	if close_button != null:
		close_button.pressed.connect(close_merchant)
	
	# Connect to inventory changes
	if InventorySystem != null:
		InventorySystem.inventory_changed.connect(_refresh_displays)
	
	# Connect to gold changes
	if PlayerStats != null:
		PlayerStats.gold_changed.connect(_update_gold_display)
	
	# Start hidden
	if control != null:
		control.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		if control != null and control.visible:
			close_merchant()


func open_merchant(merchant_data: MerchantData) -> void:
	_logger.log("open_merchant() called: " + (merchant_data.display_name if merchant_data != null else "null"))
	
	if merchant_data == null:
		_logger.log_error("merchant_data is null")
		return
	
	current_merchant = merchant_data
	
	# Update merchant name and greeting
	if merchant_name != null:
		merchant_name.text = merchant_data.display_name
	if greeting != null:
		greeting.text = merchant_data.greeting
	
	if control != null:
		control.visible = true
		_refresh_displays()
	else:
		_logger.log_error("control is null!")


func close_merchant() -> void:
	_logger.log("close_merchant() called")
	
	# Don't do anything if already closed
	if control != null and not control.visible:
		return
	
	current_merchant = null
	selected_stock_index = -1
	selected_inventory_index = -1
	
	if control != null:
		control.visible = false
		if EventBus != null:
			EventBus.merchant_closed.emit()
	else:
		_logger.log_error("control is null!")


func _on_stock_item_selected(index: int) -> void:
	selected_stock_index = index
	selected_inventory_index = -1
	if inventory_list != null:
		inventory_list.deselect_all()


func _on_inventory_item_selected(index: int) -> void:
	selected_inventory_index = index
	selected_stock_index = -1
	if stock_list != null:
		stock_list.deselect_all()


func _on_buy_button_pressed() -> void:
	if current_merchant == null:
		_logger.log_error("No merchant open")
		return
	
	if selected_stock_index < 0 or selected_stock_index >= current_merchant.stock.size():
		_logger.log("No stock item selected")
		return
	
	var item: ItemData = current_merchant.stock[selected_stock_index]
	var price: int = current_merchant.prices[selected_stock_index]
	
	if item == null:
		_logger.log_error("Selected stock item is null")
		return
	
	# Execute transaction via MerchantTransactionHandler
	var result = MerchantTransactionHandler.buy_item(item, price)
	if result["success"]:
		_logger.log(result["message"])
		_refresh_displays()
	else:
		_logger.log(result["message"])


func _on_sell_button_pressed() -> void:
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null")
		return
	
	if selected_inventory_index < 0:
		_logger.log("No inventory item selected")
		return
	
	# Get item from inventory
	var slot_data: Dictionary = InventorySystem.get_slot(selected_inventory_index)
	var item: ItemData = slot_data["item"]
	var count: int = slot_data["count"]
	
	if item == null:
		_logger.log("Selected inventory slot is empty")
		return
	
	# Execute transaction via MerchantTransactionHandler
	var result = MerchantTransactionHandler.sell_item(item, count, current_merchant)
	if result["success"]:
		_logger.log(result["message"])
		_refresh_displays()
	else:
		_logger.log_error(result["message"])


func _update_stock_display() -> void:
	if stock_list == null or current_merchant == null:
		return
	
	stock_list.clear()
	
	# Validate arrays match
	if current_merchant.stock.size() != current_merchant.prices.size():
		_logger.log_error("Merchant stock and prices arrays do not match")
		return
	
	for i in range(current_merchant.stock.size()):
		var item: ItemData = current_merchant.stock[i]
		var price: int = current_merchant.prices[i]
		
		if item == null:
			continue
		
		var display_text: String = item.display_name + " - " + str(price) + " gold"
		stock_list.add_item(display_text)


func _update_inventory_display() -> void:
	if inventory_list == null or InventorySystem == null:
		return
	
	inventory_list.clear()
	
	for i in range(InventorySystem.capacity):
		var slot_data: Dictionary = InventorySystem.get_slot(i)
		var item: ItemData = slot_data["item"]
		var count: int = slot_data["count"]
		
		if item == null:
			inventory_list.add_item("(Empty)")
			inventory_list.set_item_custom_fg_color(i, Color.GRAY)
		else:
			var display_text: String = item.display_name
			if count > 1:
				display_text += " x" + str(count)
			inventory_list.add_item(display_text)


func _update_gold_display() -> void:
	if gold_display != null and PlayerStats != null:
		gold_display.text = "Gold: " + str(PlayerStats.gold)


func _refresh_displays() -> void:
	_update_stock_display()
	_update_inventory_display()
	_update_gold_display()
