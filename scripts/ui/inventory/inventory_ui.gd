extends CanvasLayer
## Inventory UI panel.
## Displays inventory grid and handles input toggling.

# Logging
var _logger = GameLogger.create("[InventoryUI] ")

@onready var control: Control = $Control
@onready var slot_grid: GridContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/InventoryPanel/CenterContainer/GridContainer
@onready var currency_row: Control = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/InventoryPanel/CurrencyRow
@onready var equip_container: VBoxContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EquipmentPanel/VBoxContainer
@onready var close_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/Button

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")
const EQUIP_SLOT_SCENE: PackedScene = preload("res://scenes/ui/equip_slot.tscn")

var _equip_slot_nodes: Dictionary = {}


func _ready() -> void:
	_logger.log("_ready() called")
	
	# Check if nodes exist
	if slot_grid == null:
		_logger.log_error("slot_grid is null!")
		return
	if equip_container == null:
		_logger.log_error("equip_container is null!")
		return
	if close_button == null:
		_logger.log_error("close_button is null!")
		return
	
	_logger.log("All nodes found")
	
	# Connect to inventory system signals
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null!")
		return
	
	_logger.log("InventorySystem found, connecting signals...")
	InventorySystem.inventory_changed.connect(_refresh_slots)
	InventorySystem.equipment_changed.connect(_refresh_equipment_slots)
	
	# Connect close button (if it exists - main inventory UI still has close button)
	if close_button != null:
		close_button.pressed.connect(close)
	
	# Initial refresh (call directly, await is safe in _ready for first frame)
	_logger.log("Refreshing slots...")
	_refresh_slots()
	_refresh_equipment_slots()
	if currency_row != null:
		currency_row.visible = false
	
	# Start hidden (this is the full-screen modal inventory, sidebar inventory is separate)
	if control != null:
		control.visible = false
		_logger.log("Initialized (control.visible = false)")
	else:
		_logger.log_error("control node is null!")


# Input handling removed - inventory is now always visible in sidebar
# func _input(event: InputEvent) -> void:
# 	if event.is_action_pressed("open_inventory"):
# 		_log("Input detected: open_inventory pressed")
# 		var ui_visible: bool = control.visible if control != null else false
# 		if ui_visible:
# 			_log("Currently visible, closing...")
# 			close()
# 		else:
# 			_log("Currently hidden, opening...")
# 			open()


func open() -> void:
	_logger.log("open() called")
	if control != null:
		control.visible = true
		_logger.log("Set control.visible = true")
	else:
		_logger.log_error("control is null!")
		return
	_refresh_slots()
	_refresh_equipment_slots()
	if EventBus != null:
		EventBus.inventory_opened.emit()
		_logger.log("Emitted inventory_opened signal")
	else:
		_logger.log("WARNING: EventBus is null!")


func close() -> void:
	_logger.log("close() called")
	if control != null:
		control.visible = false
		_logger.log("Set control.visible = false")
	else:
		_logger.log_error("control is null!")
	if EventBus != null:
		EventBus.inventory_closed.emit()
		_logger.log("Emitted inventory_closed signal")
	else:
		_logger.log("WARNING: EventBus is null!")


func _refresh_slots() -> void:
	_logger.log("_refresh_slots() called")
	
	if slot_grid == null:
		_logger.log_error("slot_grid is null in _refresh_slots!")
		return
	
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null in _refresh_slots!")
		return
	
	var existing_count: int = slot_grid.get_child_count()
	_logger.log("Clearing existing slots (count: " + str(existing_count) + ")")
	# Clear existing slots immediately (remove_child is immediate, queue_free is deferred)
	for child in slot_grid.get_children():
		slot_grid.remove_child(child)
		child.queue_free()
	
	# Wait one frame to ensure nodes are fully removed
	await get_tree().process_frame
	
	_logger.log("Creating slots for capacity: " + str(InventorySystem.capacity))
	# Create slots for current capacity
	for i in range(InventorySystem.capacity):
		var slot: PanelContainer = SLOT_SCENE.instantiate()
		if slot == null:
			_logger.log_error("Failed to instantiate slot at index " + str(i))
			continue
		
		# Add to scene tree first so @onready vars can be initialized
		slot_grid.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		
		# Setup after adding to tree (nodes will be ready)
		var slot_data: Dictionary = InventorySystem.get_slot(i)
		slot.setup(i, slot_data["item"], slot_data["count"])
	
	_logger.log("Created " + str(slot_grid.get_child_count()) + " slots")


func _on_slot_clicked(slot_index: int) -> void:
	# Handle slot click via InventoryUIHandler
	var result = InventoryUIHandler.handle_slot_click(slot_index)
	if result["success"]:
		_refresh_slots()
	else:
		var slot_data: Dictionary = InventorySystem.get_slot(slot_index)
		if slot_data["item"] != null:
			print("Clicked slot ", slot_index, ": ", slot_data["item"].display_name, " x", slot_data["count"])


func _refresh_equipment_slots(slot_name: String = "") -> void:
	if equip_container == null or InventorySystem == null:
		return
	if _equip_slot_nodes.is_empty():
		_build_equipment_slots()
	if slot_name == "":
		for slot_key in _equip_slot_nodes.keys():
			_update_equip_slot(slot_key)
	else:
		_update_equip_slot(slot_name)


func _build_equipment_slots() -> void:
	if equip_container == null:
		return
	_equip_slot_nodes.clear()
	var rows: Array = []
	for child in equip_container.get_children():
		if child is HBoxContainer:
			var row := child as HBoxContainer
			for slot_child in row.get_children():
				row.remove_child(slot_child)
				slot_child.queue_free()
			rows.append(row)
	if rows.is_empty():
		return
	var layout := [
		["head"],
		["book", "body", "weapon"],
		["ring1", "ring2", "legs", "gloves"],
		["amulet", "boots"]
	]
	for i in range(layout.size()):
		if i >= rows.size():
			break
		for slot_name in layout[i]:
			_create_equip_slot(slot_name, rows[i])


func _update_equip_slot(slot_name: String) -> void:
	if InventorySystem == null:
		return
	var equip_slot: PanelContainer = _equip_slot_nodes.get(slot_name)
	if equip_slot == null:
		return
	var equipped_item: EquipmentData = InventorySystem.get_equipped(slot_name)
	equip_slot.setup(slot_name, equipped_item)


func _create_equip_slot(slot_name: String, parent: HBoxContainer) -> void:
	var equip_slot: PanelContainer = EQUIP_SLOT_SCENE.instantiate()
	if equip_slot == null:
		return

	parent.add_child(equip_slot)
	equip_slot.slot_clicked.connect(_on_equip_slot_clicked)
	_equip_slot_nodes[slot_name] = equip_slot
	_update_equip_slot(slot_name)


func _on_equip_slot_clicked(slot_name: String) -> void:
	var result := InventoryUIHandler.unequip_slot(slot_name)
	if result["success"]:
		_refresh_slots()
