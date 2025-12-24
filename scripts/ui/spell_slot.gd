extends PanelContainer
## Spell slot UI component.
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
		return  # Nodes not ready yet
	
	# Set key label (1-9, 0)
	if index < 9:
		key_label.text = str(index + 1)
	else:
		key_label.text = "0"
	
	if spell == null:
		# Empty slot
		icon.texture = null
		icon.modulate = Color.WHITE
		key_label.text = ""
	else:
		# Load spell icon and apply hue shift
		_load_spell_icon(spell)
		key_label.visible = true
	
	# Reset cooldown overlay
	if cooldown_overlay != null:
		cooldown_overlay.visible = false
		cooldown_overlay.color = Color(0, 0, 0, 0.5)


func _load_spell_icon(spell: SpellData) -> void:
	# Load the blue spell icon
	var icon_path := "res://assets/animations/UI/spell_hotbar_icons/spell_ball_blast/spell_icon_lvl_1(blue).png"
	var base_icon := load(icon_path) as Texture2D
	
	if base_icon == null:
		push_error("[SpellSlot] Failed to load spell icon: " + icon_path)
		icon.texture = null
		return
	
	icon.texture = base_icon
	
	# Apply hue shift based on element
	# Fire: 0.0 (red), Water: 0.55 (cyan), Earth: 0.3 (brown/green), Air: 0.75 (light blue)
	var hue: float = spell.hue_shift
	var color := Color.from_hsv(hue, 1.0, 1.0)
	icon.modulate = color


func set_selected(is_selected: bool) -> void:
	# Highlight selected slot with border color change
	if not theme_override_styles.has("panel"):
		return
	
	var style := theme_override_styles["panel"] as StyleBoxFlat
	if style == null:
		return
	
	if is_selected:
		style.border_color = Color(1.0, 0.8, 0.0, 1.0)  # Gold
	else:
		style.border_color = Color(0.4, 0.3, 0.25, 1)  # Default brown


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

