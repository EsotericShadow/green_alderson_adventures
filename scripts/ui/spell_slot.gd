extends PanelContainer
class_name SpellSlot
## Spell slot UI component.

# Logging
var _logger = GameLogger.create("[SpellSlot] ")
## Displays spell icon with hue shift, handles selection highlighting.

signal slot_clicked(slot_index: int)

var slot_index: int = -1
var spell_data: SpellData = null

@onready var icon: TextureRect = $TextureRect
@onready var key_label: Label = $KeyLabel
@onready var cooldown_overlay: ColorRect = $CooldownOverlay


func setup(index: int, spell: SpellData) -> void:
	slot_index = index
	spell_data = spell
	
	if icon == null or key_label == null:
		_logger.log_warning("Slot " + str(index) + ": icon or key_label is null!")
		return  # Nodes not ready yet
	
	# Ensure icon is visible
	icon.visible = true
	
	# Set key label (1-9, 0)
	if index < 9:
		key_label.text = str(index + 1)
	else:
		key_label.text = "0"
	
	if spell == null:
		# Empty slot
		_logger.log_debug("Slot " + str(index) + ": empty (no spell)")
		icon.texture = null
		icon.modulate = Color.WHITE
		key_label.text = ""
		icon.visible = false
	else:
		# Load spell icon and apply hue shift
		_logger.log_debug("Slot " + str(index) + ": setting spell " + spell.display_name)
		_load_spell_icon(spell)
		key_label.visible = true
		icon.visible = true
	
	# Reset cooldown overlay
	if cooldown_overlay != null:
		cooldown_overlay.visible = false
		cooldown_overlay.color = Color(0, 0, 0, 0.5)


func _load_spell_icon(spell: SpellData) -> void:
	# Determine icon path based on element (using the actual filenames you created)
	var icon_filename: String = "spell_icon_lvl_1(blue).png"  # Default
	
	match spell.element:
		"fire":
			icon_filename = "spell_icon_lvl_1(fire).png"
		"water":
			icon_filename = "spell_icon_lvl_1(water).png"
		"earth":
			icon_filename = "spell_icon_lvl_1(earth).png"
		"air":
			icon_filename = "spell_icon_lvl_1(air).png"
		_:
			icon_filename = "spell_icon_lvl_1(blue).png"
	
	var icon_path := "res://assets/animations/UI/spell_hotbar_icons/spell_ball_blast/" + icon_filename
	var base_icon := load(icon_path) as Texture2D
	
	# Fallback to blue icon if element-specific icon doesn't exist
	if base_icon == null:
		_logger.log_warning("Element-specific icon not found (" + icon_filename + "), using blue icon")
		icon_path = "res://assets/animations/UI/spell_hotbar_icons/spell_ball_blast/spell_icon_lvl_1(blue).png"
		base_icon = load(icon_path) as Texture2D
		
		if base_icon == null:
			push_error("[SpellSlot] ❌ Failed to load spell icon: " + icon_path)
			icon.texture = null
			icon.visible = false
			return
		
		# Apply color modulation as fallback only
		var modulate_color: Color
		match spell.element:
			"fire":
				modulate_color = Color(1.0, 0.2, 0.2, 1.0)  # Red
			"water":
				modulate_color = Color.from_hsv(0.5, 1.0, 1.0)  # Cyan
			"earth":
				modulate_color = Color.from_hsv(0.3, 1.0, 1.0)  # Green
			"air":
				modulate_color = Color.from_hsv(0.55, 1.0, 1.0)  # Light blue
			_:
				modulate_color = Color.WHITE
		icon.modulate = modulate_color
		_logger.log_debug("Using fallback modulation: " + str(modulate_color))
	else:
		# Element-specific icon found - use white modulate (icon should already be colored)
		icon.modulate = Color.WHITE
		_logger.log_debug("Element-specific icon loaded: " + icon_filename)
	
	_logger.log_debug("Icon loaded for " + spell.display_name + " (" + spell.element + ")")
	icon.texture = base_icon
	
	# Ensure icon is visible after setting texture
	icon.visible = true
	_logger.log_debug("Icon visible: " + str(icon.visible) + ", texture: " + str(icon.texture != null))


func set_selected(is_selected: bool) -> void:
	# Highlight selected slot with border color change
	# Get existing style or create new one
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		# Create a new style if none exists
		style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.7)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
	else:
		# Duplicate existing style to avoid modifying the original
		style = style.duplicate() as StyleBoxFlat
	
	if style == null:
		return  # Failed to get or create style
	
	if is_selected:
		style.border_color = Color(1.0, 0.8, 0.0, 1.0)  # Gold
	else:
		style.border_color = Color(0.4, 0.3, 0.25, 1)  # Default brown
	
	# Apply the modified style
	add_theme_stylebox_override("panel", style)


func set_cooldown_progress(progress: float) -> void:
	# progress: 0.0 = ready, 1.0 = full cooldown
	if cooldown_overlay == null:
		return
	
	if progress <= 0.0:
		cooldown_overlay.visible = false
	else:
		cooldown_overlay.visible = true
		cooldown_overlay.size.y = size.y * progress
		cooldown_overlay.position.y = size.y - cooldown_overlay.size.y


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			slot_clicked.emit(slot_index)

