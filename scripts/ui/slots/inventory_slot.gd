extends PanelContainer
## Inventory slot UI component.
## Displays item icon and count, handles click events.

signal slot_clicked(slot_index: int)

var slot_index: int = -1

@onready var icon: TextureRect = $TextureRect
@onready var count_label: Label = $Label


func setup(index: int, item: ItemData, count: int) -> void:
	slot_index = index
	
	if icon == null or count_label == null:
		return  # Nodes not ready yet
	
	if item == null or count <= 0:
		# Empty slot
		icon.texture = null
		count_label.text = ""
		count_label.visible = false
	else:
		# Slot with item
		icon.texture = item.icon
		if count > 1 and item.stackable:
			count_label.text = str(count)
			count_label.visible = true
		else:
			count_label.text = ""
			count_label.visible = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			slot_clicked.emit(slot_index)
