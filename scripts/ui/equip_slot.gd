extends PanelContainer
## Equipment slot UI component.
## Displays equipped item icon, handles click events for unequipping.

signal slot_clicked(slot_name: String)

var slot_name: String = ""

@onready var icon: TextureRect = $VBoxContainer/TextureRect
@onready var label: Label = $VBoxContainer/Label


func setup(equip_slot_name: String, item: EquipmentData) -> void:
	slot_name = equip_slot_name
	
	if icon == null or label == null:
		return  # Nodes not ready yet
	
	# Set slot label (e.g., "Head", "Weapon")
	label.text = equip_slot_name.capitalize()
	
	if item == null:
		# Empty slot
		icon.texture = null
		icon.modulate = Color(1, 1, 1, 0.3)  # Dimmed when empty
	else:
		# Slot with equipment
		icon.texture = item.icon
		icon.modulate = Color(1, 1, 1, 1.0)  # Full opacity when equipped


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			slot_clicked.emit(slot_name)

