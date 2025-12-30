extends Control
## Enhanced Inventory Tab - Shows inventory grid in the player panel sidebar
## Handles drag/drop, double-click, right-click context menu, and item highlighting

const LOG_PREFIX := "[INVENTORY_TAB] "
const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")

@onready var slot_grid: GridContainer = $VBoxContainer/GridContainer

var slots: Array[Control] = []
var context_menu: PopupMenu = null
var drag_source_slot: int = -1


func _ready() -> void:
	print(LOG_PREFIX + "Inventory tab ready")
	_create_context_menu()
	_create_slots()
	_update_slots()
	
	# Connect to inventory changes
	if InventorySystem != null:
		InventorySystem.inventory_changed.connect(_on_inventory_changed)


func _create_context_menu() -> void:
	# Create context menu
	context_menu = PopupMenu.new()
	context_menu.name = "ContextMenu"
	add_child(context_menu)
	context_menu.id_pressed.connect(_on_context_menu_selected)


func _create_slots() -> void:
	if slot_grid == null:
		push_error(LOG_PREFIX + "slot_grid is null!")
		return
	
	# Create inventory slots (4 columns as defined in scene)
	var num_slots: int = InventorySystem.capacity if InventorySystem != null else 28
	
	# Clear existing slots
	for slot in slots:
		if is_instance_valid(slot):
			slot_grid.remove_child(slot)
			slot.queue_free()
	slots.clear()
	
	for i in range(num_slots):
		var slot: Control = SLOT_SCENE.instantiate()
		slot_grid.add_child(slot)
		slots.append(slot)
		
		# Connect all signals
		if slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(_on_slot_clicked)
		if slot.has_signal("slot_double_clicked"):
			slot.slot_double_clicked.connect(_on_slot_double_clicked)
		if slot.has_signal("slot_right_clicked"):
			slot.slot_right_clicked.connect(_on_slot_right_clicked)
		if slot.has_signal("drag_started"):
			slot.drag_started.connect(_on_drag_started)
		if slot.has_signal("drag_ended"):
			slot.drag_ended.connect(_on_drag_ended)
		if slot.has_signal("item_dropped"):
			slot.item_dropped.connect(_on_item_dropped)
		
		if slot.has_method("setup"):
			slot.setup(i, null, 0)


func _update_slots() -> void:
	if InventorySystem == null:
		return
	
	for i in range(min(slots.size(), InventorySystem.capacity)):
		var inventory_slot: Dictionary = InventorySystem.get_slot(i)
		var slot: Control = slots[i]
		
		if slot.has_method("setup"):
			slot.setup(i, inventory_slot.get("item"), inventory_slot.get("count", 0))


func _on_inventory_changed() -> void:
	_update_slots()


func _on_slot_clicked(slot_index: int) -> void:
	# Handle single click - just select/highlight
	_clear_highlights()
	if slot_index < slots.size():
		var slot = slots[slot_index]
		if slot.has_method("set_highlighted"):
			slot.set_highlighted(true)


func _on_slot_double_clicked(slot_index: int) -> void:
	# Use item on double-click
	_use_item(slot_index)


func _on_slot_right_clicked(slot_index: int, menu_position: Vector2) -> void:
	# Show context menu
	var slot_data: Dictionary = InventorySystem.get_slot(slot_index)
	var item: ItemData = slot_data.get("item")
	
	if item != null and context_menu != null:
		context_menu.clear()
		
		# Add menu items based on item type
		if item is PotionData or item.item_type == "consumable":
			context_menu.add_item("Use", 0)
		
		if item is EquipmentData:
			context_menu.add_item("Equip", 1)
		
		context_menu.add_separator()
		context_menu.add_item("Examine", 2)
		context_menu.add_item("Drop", 3)
		
		# Store slot index for context menu callback
		context_menu.set_meta("slot_index", slot_index)
		
		# Show menu at mouse position
		context_menu.popup_on_parent(Rect2(menu_position, Vector2(150, 0)))


func _on_context_menu_selected(id: int) -> void:
	var slot_index: int = context_menu.get_meta("slot_index", -1)
	if slot_index < 0:
		return
	
	match id:
		0:  # Use
			_use_item(slot_index)
		1:  # Equip
			_equip_item(slot_index)
		2:  # Examine
			_examine_item(slot_index)
		3:  # Drop
			_drop_item(slot_index)


func _on_drag_started(slot_index: int) -> void:
	drag_source_slot = slot_index


func _on_drag_ended() -> void:
	# Reset drag state
	drag_source_slot = -1


func _on_item_dropped(from_slot: int, to_slot: int) -> void:
	# Handle drag-and-drop item swap
	_handle_item_move(from_slot, to_slot)
	drag_source_slot = -1


func _handle_item_move(from_slot: int, to_slot: int) -> void:
	# Swap items between slots
	if InventorySystem == null:
		return
	
	var from_data: Dictionary = InventorySystem.get_slot(from_slot)
	var to_data: Dictionary = InventorySystem.get_slot(to_slot)
	
	var from_item: ItemData = from_data.get("item")
	var from_count: int = from_data.get("count", 0)
	var to_item: ItemData = to_data.get("item")
	var to_count: int = to_data.get("count", 0)
	
	# If same item and stackable, try to stack
	if from_item == to_item and from_item != null and from_item.stackable:
		var max_stack: int = from_item.max_stack
		var total: int = from_count + to_count
		if total <= max_stack:
			# Can stack completely
			InventorySystem.set_slot(to_slot, from_item, total)
			InventorySystem.set_slot(from_slot, null, 0)
			return
	
	# Otherwise swap
	InventorySystem.set_slot(from_slot, to_item, to_count)
	InventorySystem.set_slot(to_slot, from_item, from_count)


func _use_item(slot_index: int) -> void:
	# Use item through InventorySystem (convenience method)
	if InventorySystem.use_item_at_slot(slot_index):
		_update_slots()


func _equip_item(slot_index: int) -> void:
	var result := InventoryUIHandler.equip_slot(slot_index)
	if result["success"]:
		_update_slots()


func _examine_item(slot_index: int) -> void:
	var slot_data: Dictionary = InventorySystem.get_slot(slot_index)
	var item: ItemData = slot_data.get("item")
	
	if item != null:
		# Show item details (could open a tooltip or info panel)
		print("Examining: ", item.display_name)
		print("  Description: ", item.description)
		if item is PotionData:
			var potion: PotionData = item as PotionData
			print("  Effect: ", potion.effect)
			print("  Potency: ", potion.potency)


func _drop_item(slot_index: int) -> void:
	# TODO: Implement item dropping (remove from inventory, spawn in world)
	var slot_data: Dictionary = InventorySystem.get_slot(slot_index)
	var item: ItemData = slot_data.get("item")
	var count: int = slot_data.get("count", 0)
	
	if item != null:
		# For now, just remove from inventory
		InventorySystem.remove_item(item, count)
		print("Dropped: ", item.display_name, " x", count)


func _clear_highlights() -> void:
	for slot in slots:
		if slot.has_method("set_highlighted"):
			slot.set_highlighted(false)
