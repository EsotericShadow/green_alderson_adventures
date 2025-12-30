extends CanvasLayer
## Inventory UI panel.
## Displays inventory grid and handles input toggling.

# Logging
var _logger = GameLogger.create("[InventoryUI] ")

@onready var control: Control = $Control
@onready var slot_grid: GridContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/InventoryPanel/CenterContainer/GridContainer
@onready var equip_container: VBoxContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EquipmentPanel/VBoxContainer
@onready var close_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/Button

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")
const EQUIP_SLOT_SCENE: PackedScene = preload("res://scenes/ui/equip_slot.tscn")


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
		_refresh_equipment_slots()
	else:
		var slot_data: Dictionary = InventorySystem.get_slot(slot_index)
		if slot_data["item"] != null:
			print("Clicked slot ", slot_index, ": ", slot_data["item"].display_name, " x", slot_data["count"])


func _refresh_equipment_slots() -> void:
	_refresh_equipment_slots_async()


func _refresh_equipment_slots_async() -> void:
	if equip_container == null:
		return
	
	if InventorySystem == null:
		return
	
	# Clear existing equipment slots from all rows
	for row in equip_container.get_children():
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	
	await get_tree().process_frame
	
	# Get row containers
	var row1: HBoxContainer = equip_container.get_child(0) as HBoxContainer  # head
	var row2: HBoxContainer = equip_container.get_child(1) as HBoxContainer  # book, body, weapon
	var row3: HBoxContainer = equip_container.get_child(2) as HBoxContainer  # ring, legs, gloves
	var row4: HBoxContainer = equip_container.get_child(3) as HBoxContainer  # amulet, boots
	
	# Row 1: head (centered single column)
	_create_equip_slot("head", row1)
	
	# Row 2: book, body, weapon (3 columns)
	_create_equip_slot("book", row2)
	_create_equip_slot("body", row2)
	_create_equip_slot("weapon", row2)
	
	# Row 3: ring, legs, gloves (3 columns)
	_create_equip_slot("ring1", row3)  # Using ring1 for "ring"
	_create_equip_slot("legs", row3)
	_create_equip_slot("gloves", row3)
	
	# Row 4: amulet, boots (2 columns)
	_create_equip_slot("amulet", row4)
	_create_equip_slot("boots", row4)


func _create_equip_slot(slot_name: String, parent: HBoxContainer) -> void:
	var equip_slot: PanelContainer = EQUIP_SLOT_SCENE.instantiate()
	if equip_slot == null:
		return
	
	parent.add_child(equip_slot)
	equip_slot.slot_clicked.connect(_on_equip_slot_clicked)
	
	var equipped_item: EquipmentData = InventorySystem.get_equipped(slot_name)
	equip_slot.setup(slot_name, equipped_item)


func _on_equip_slot_clicked(slot_name: String) -> void:
	# Unequip item when clicking equipment slot
	var unequipped: EquipmentData = InventorySystem.unequip(slot_name)
	if unequipped != null:
		_refresh_slots()
		_refresh_equipment_slots()
		print("Unequipped: ", unequipped.display_name)
