extends PanelContainer
## Individual quick belt slot component

signal slot_clicked(slot_index: int)

var slot_index: int = -1
var inventory_slot_index: int = -1  # Which inventory slot this maps to (0-4)

@onready var icon: TextureRect = $MarginContainer/Icon
@onready var count_label: Label = $MarginContainer/CountLabel
@onready var key_label: Label = $MarginContainer/KeyLabel


func setup(slot_idx: int, inv_slot_idx: int) -> void:
	slot_index = slot_idx
	inventory_slot_index = inv_slot_idx
	
	# Set key label (F1-F5)
	key_label.text = "F" + str(slot_idx + 1)
	
	update_item(null, 0)


func update_item(item: ItemData, count: int) -> void:
	if item == null or count <= 0:
		icon.texture = null
		icon.visible = false
		count_label.visible = false
		return
	
	# Show item icon
	if item.icon != null:
		icon.texture = item.icon
		icon.visible = true
	else:
		icon.texture = null
		icon.visible = false
	
	# Show count if stackable and count > 1
	if item.stackable and count > 1:
		count_label.text = str(count)
		count_label.visible = true
	else:
		count_label.visible = false


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(slot_index)

