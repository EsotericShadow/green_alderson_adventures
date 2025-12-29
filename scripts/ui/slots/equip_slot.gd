extends PanelContainer
## Equipment slot UI component.
## Displays equipped item icon, handles click events for unequipping.

signal slot_clicked(slot_name: String)

var slot_name: String = ""

@onready var icon: TextureRect = $TextureRect
@onready var tooltip_label: Label = $TooltipLabel


func setup(equip_slot_name: String, item: EquipmentData) -> void:
	slot_name = equip_slot_name
	print("[EquipSlot] setup() called for slot: ", equip_slot_name, ", item: ", item)
	
	if icon == null:
		push_error("[EquipSlot] icon is null!")
		return
	if tooltip_label == null:
		push_error("[EquipSlot] tooltip_label is null!")
		return
	
	print("[EquipSlot] Nodes ready, icon: ", icon, ", tooltip_label: ", tooltip_label)
	
	# Set tooltip label text (e.g., "Head", "Weapon")
	# Special case: ring1 displays as "Ring"
	var display_name: String = equip_slot_name.capitalize()
	if equip_slot_name == "ring1":
		display_name = "Ring"
	tooltip_label.text = display_name
	tooltip_label.visible = false  # Hidden by default, shown on hover
	
	if item == null:
		# Empty slot - show slot icon (50% size)
		print("[EquipSlot] Empty slot, loading slot icon...")
		_load_slot_icon(equip_slot_name)
		icon.modulate = Color(1, 1, 1, 0.5)  # 50% transparent
		# Set to 50% size (32x32)
		icon.set_deferred("offset_left", -16.0)
		icon.set_deferred("offset_top", -16.0)
		icon.set_deferred("offset_right", 16.0)
		icon.set_deferred("offset_bottom", 16.0)
		icon.scale = Vector2(1.0, 1.0)
		icon.visible = true
		print("[EquipSlot] Icon visible: ", icon.visible, ", texture: ", icon.texture != null, ", modulate: ", icon.modulate)
	else:
		# Slot with equipment - show item icon (full size)
		icon.texture = item.icon
		icon.modulate = Color(1, 1, 1, 1.0)  # Full opacity when equipped
		# Resize to fill slot for equipped items
		icon.set_deferred("offset_left", -32.0)
		icon.set_deferred("offset_top", -32.0)
		icon.set_deferred("offset_right", 32.0)
		icon.set_deferred("offset_bottom", 32.0)
		icon.scale = Vector2(1.0, 1.0)
		icon.visible = true


func _load_slot_icon(equip_slot_name: String) -> void:
	# Map slot names to icon file names
	var icon_filename: String = ""
	match equip_slot_name:
		"head":
			icon_filename = "head.png"
		"body":
			icon_filename = "body.png"
		"gloves":
			icon_filename = "gloves.png"
		"boots":
			icon_filename = "boots.png"
		"weapon":
			icon_filename = "weapon.png"
		"ring1", "ring2":
			icon_filename = "ring.png"
		"book":
			icon_filename = "book.png"
		"legs":
			icon_filename = "legs.png"
		"amulet":
			icon_filename = "amulet.png"
		_:
			icon.texture = null
			return
	
	var icon_path: String = "res://resources/assets/uiicons/" + icon_filename
	var texture: Texture2D = load(icon_path) as Texture2D
	if texture != null:
		icon.texture = texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.visible = true
		print("[EquipSlot] ✓ Loaded slot icon for ", equip_slot_name, " from ", icon_path)
	else:
		icon.texture = null
		icon.visible = false
		push_error("[EquipSlot] ❌ Failed to load slot icon: " + icon_path)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			slot_clicked.emit(slot_name)


func _on_mouse_entered() -> void:
	# Show tooltip on hover
	if tooltip_label != null:
		tooltip_label.visible = true


func _on_mouse_exited() -> void:
	# Hide tooltip when mouse leaves
	if tooltip_label != null:
		tooltip_label.visible = false


func _ready() -> void:
	# Connect mouse enter/exit signals for tooltip
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
