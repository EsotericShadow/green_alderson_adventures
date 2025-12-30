extends PopupMenu
## Context menu for inventory items.
## Shows actions like Use, Drop, Examine, etc.

signal use_item(slot_index: int)
signal drop_item(slot_index: int)
signal examine_item(slot_index: int)

var target_slot_index: int = -1


func _ready() -> void:
	id_pressed.connect(_on_id_pressed)


func show_menu(slot_index: int, item: ItemData, position: Vector2) -> void:
	target_slot_index = slot_index
	clear()
	
	if item == null:
		return
	
	# Add menu items based on item type
	if item is PotionData or item.item_type == "consumable":
		add_item("Use", 0)
	
	if item is EquipmentData:
		add_item("Equip", 1)
	
	add_separator()
	add_item("Examine", 2)
	add_item("Drop", 3)
	
	# Show at mouse position
	popup_on_parent(Rect2(position, Vector2(150, 0)))


func _on_id_pressed(id: int) -> void:
	match id:
		0:  # Use
			use_item.emit(target_slot_index)
		1:  # Equip
			use_item.emit(target_slot_index)  # Equip is handled as "use" for equipment
		2:  # Examine
			examine_item.emit(target_slot_index)
		3:  # Drop
			drop_item.emit(target_slot_index)


