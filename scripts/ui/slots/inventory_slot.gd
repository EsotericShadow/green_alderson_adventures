extends PanelContainer
## Enhanced inventory slot UI component.
## Displays item icon and count, handles click events, drag/drop, double-click, right-click context menu, and highlighting.
## For potions, displays animated sprites using SubViewport.

# Logging
var _logger = GameLogger.create("[InventorySlot] ")

signal slot_clicked(slot_index: int)
signal slot_double_clicked(slot_index: int)
signal slot_right_clicked(slot_index: int, position: Vector2)
signal drag_started(slot_index: int)
signal drag_ended()
signal item_dropped(from_slot: int, to_slot: int)

var slot_index: int = -1
var item: ItemData = null
var count: int = 0
var is_dragging: bool = false
var is_highlighted: bool = false
var last_click_time: float = 0.0
const DOUBLE_CLICK_TIME: float = 0.3  # Seconds between clicks for double-click

@onready var icon_container: Control = $IconContainer
@onready var icon: TextureRect = $IconContainer/TextureRect
@onready var animated_container: Control = $IconContainer/AnimatedSpriteContainer
@onready var animated_viewport: SubViewport = $IconContainer/AnimatedSpriteContainer/AnimatedSpriteViewport
@onready var viewport_texture_rect: TextureRect = $IconContainer/AnimatedSpriteContainer/ViewportTextureRect
@onready var count_label: Label = $Label
@onready var highlight_overlay: ColorRect = $HighlightOverlay

# Mapping of potion IDs to their animated scene paths
const POTION_SCENE_MAP: Dictionary = {
	"health_potion": "res://scenes/potions/health_potion_red.tscn",
	"test_health_potion": "res://scenes/potions/health_potion_red.tscn",
	"greater_health_potion": "res://scenes/potions/health_potion_red.tscn",
	"mana_potion": "res://scenes/potions/mana_potion_blue.tscn",
	"greater_mana_potion": "res://scenes/potions/mana_potion_blue.tscn",
	"water_filled_elixir_vial": "res://scenes/potions/mana_potion_blue.tscn",
	"deepwater_script": "res://scenes/potions/mana_potion_blue.tscn",
	"stamina_potion": "res://scenes/potions/stamina_potion_green.tscn",
	"speed_potion": "res://scenes/potions/speed_potion_yellow.tscn",
	"psychotropic_filled_elixir_vial": "res://scenes/potions/speed_potion_yellow.tscn",
	"stormlink_sigil": "res://scenes/potions/speed_potion_yellow.tscn",
	"strength_potion": "res://scenes/potions/strength_potion_orange.tscn",
	"ashpulse_knot": "res://scenes/potions/strength_potion_orange.tscn",
	"dark_matter_filled_elixir_vial": "res://scenes/potions/strength_potion_orange.tscn",
	"defense_potion": "res://scenes/potions/resilience_potion_black.tscn",
	"stoneward_seal": "res://scenes/potions/resilience_potion_black.tscn",
	"voidward_glyph": "res://scenes/potions/resilience_potion_black.tscn",
	"spectral_fluid_filled_elixir_vial": "res://scenes/potions/resilience_potion_black.tscn",
	"intelligence_boost_potion": "res://scenes/potions/intelligence_potion_cyan.tscn",
	"wisdom_filled_elixir_vial": "res://scenes/potions/intelligence_potion_cyan.tscn",
	"sigil_of_still_air": "res://scenes/potions/intelligence_potion_cyan.tscn",
	"gold_potion": "res://scenes/potions/gold_potion.tscn",
	"ether_filled_elixir_vial": "res://scenes/potions/gold_potion.tscn",
	"sunflare_disk": "res://scenes/potions/gold_potion.tscn",
	"moonphase_token": "res://scenes/potions/moonphase_token_purple.tscn",
	"blood_filled_elixir_vial": "res://scenes/potions/health_potion_red.tscn",
}

# Style references for highlighting
var _normal_style: StyleBoxFlat
var _highlight_style: StyleBoxFlat
var _drag_style: StyleBoxFlat


func _ready() -> void:
	# Get base style from theme
	var base_style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	if base_style == null:
		# Fallback: create default style
		base_style = StyleBoxFlat.new()
		base_style.bg_color = Color(0.2, 0.2, 0.2, 0.7)
		base_style.border_color = Color(0.4, 0.3, 0.25, 1)
		base_style.border_width_left = 2
		base_style.border_width_top = 2
		base_style.border_width_right = 2
		base_style.border_width_bottom = 2
	
	# Create style variants for highlighting
	_normal_style = base_style.duplicate() as StyleBoxFlat
	_highlight_style = base_style.duplicate() as StyleBoxFlat
	_drag_style = base_style.duplicate() as StyleBoxFlat
	
	# Configure highlight style (brighter border)
	_highlight_style.border_color = Color(0.8, 0.7, 0.5, 1.0)
	_highlight_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	
	# Configure drag style (semi-transparent)
	_drag_style.border_color = Color(0.6, 0.5, 0.4, 0.8)
	_drag_style.bg_color = Color(0.25, 0.25, 0.25, 0.6)
	
	# Ensure highlight overlay exists
	if highlight_overlay == null:
		highlight_overlay = ColorRect.new()
		highlight_overlay.name = "HighlightOverlay"
		highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_overlay.color = Color(1.0, 1.0, 0.5, 0.2)  # Yellow highlight
		highlight_overlay.visible = false
		highlight_overlay.z_index = 0  # Behind icons
		add_child(highlight_overlay)
		highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Set Z-index for icons and labels to appear above overlays
	if icon_container != null:
		icon_container.z_index = 1
	if animated_container != null:
		animated_container.z_index = 100  # Animated potions above sidebar and everything else
	if count_label != null:
		count_label.z_index = 101  # Count label above everything including potions
	
	# Set initial style
	add_theme_stylebox_override("panel", _normal_style)


func setup(index: int, item_data: ItemData, item_count: int) -> void:
	slot_index = index
	item = item_data
	count = item_count
	
	if icon == null or count_label == null or icon_container == null:
		return  # Nodes not ready yet
	
	if item == null or count <= 0:
		# Empty slot
		_clear_icon()
		count_label.text = ""
		count_label.visible = false
		tooltip_text = ""
	else:
		# Slot with item - check if it's a potion for animation
		if item is PotionData:
			_setup_potion_animation(item as PotionData)
		else:
			_setup_static_icon(item.icon)
		
		if count > 1 and item.stackable:
			count_label.text = str(count)
			count_label.visible = true
		else:
			count_label.text = ""
			count_label.visible = false
		
		# Set tooltip
		var tooltip: String = item.display_name
		if item.description != "":
			tooltip += "\n" + item.description
		if count > 1:
			tooltip += "\nCount: " + str(count)
		tooltip_text = tooltip


func _setup_potion_animation(potion: PotionData) -> void:
	# Hide static icon
	icon.visible = false
	
	# Check if we have a scene for this potion
	var scene_path: String = POTION_SCENE_MAP.get(potion.id, "")
	if scene_path.is_empty():
		# Fallback to static icon if no animation scene
		_setup_static_icon(potion.icon)
		return
	
	# Load and instantiate the animated scene
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		_logger.log_warning("Failed to load potion scene: " + scene_path)
		_setup_static_icon(potion.icon)
		return
	
	# Clear existing animated sprite
	for child in animated_viewport.get_children():
		child.queue_free()
	
	# Instantiate the animated scene
	var animated_instance = scene.instantiate()
	if animated_instance == null:
		_logger.log_warning("Failed to instantiate potion scene: " + scene_path)
		_setup_static_icon(potion.icon)
		return
	
	# Add to viewport first
	animated_viewport.add_child(animated_instance)
	
	# Find and configure the AnimatedSprite2D
	var animated_sprite: AnimatedSprite2D = animated_instance.get_node_or_null("AnimatedSprite2D")
	if animated_sprite == null:
		_logger.log_warning("AnimatedSprite2D not found in potion scene: " + scene_path)
		_setup_static_icon(potion.icon)
		return
	
	# Center the sprite in the 48x48 viewport (sprite is 15x30)
	# Position the root Node2D so the sprite center aligns with viewport center
	animated_instance.position = Vector2(24, 24)
	
	# Add a Camera2D to the viewport for proper 2D rendering
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(24, 24)  # Center of 48x48 viewport
	camera.name = "Camera2D"
	animated_viewport.add_child(camera)
	camera.make_current()  # Make it the active camera
	
	# Ensure animation is playing
	if not animated_sprite.is_playing():
		animated_sprite.play()
	
	# CRITICAL: Assign the viewport texture to the TextureRect to display it
	viewport_texture_rect.texture = animated_viewport.get_texture()
	
	# Debug logging
	_logger.log_debug("Potion animation setup: " + potion.id + " at position " + str(animated_instance.position))
	_logger.log_debug("Viewport texture assigned: " + str(viewport_texture_rect.texture != null))
	
	# Show the animated container
	animated_container.visible = true


func _setup_static_icon(texture: Texture2D) -> void:
	# Hide animated container
	animated_container.visible = false
	
	# Clear animated sprite
	for child in animated_viewport.get_children():
		child.queue_free()
	
	# Show static icon
	icon.texture = texture
	icon.visible = true


func _clear_icon() -> void:
	# Clear static icon
	icon.texture = null
	icon.visible = false
	
	# Hide animated container
	animated_container.visible = false
	
	# Clear animated sprite
	for child in animated_viewport.get_children():
		child.queue_free()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Check for double-click
				var current_time: float = Time.get_ticks_msec() / 1000.0
				if current_time - last_click_time < DOUBLE_CLICK_TIME:
					# Double-click detected
					last_click_time = 0.0  # Reset to prevent triple-click
					slot_double_clicked.emit(slot_index)
					get_viewport().set_input_as_handled()
					return
				else:
					last_click_time = current_time
				
				# Single click (drag will be handled by _get_drag_data)
				slot_clicked.emit(slot_index)
				get_viewport().set_input_as_handled()
		
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			# Right-click for context menu
			if item != null:
				slot_right_clicked.emit(slot_index, mouse_event.global_position)
				get_viewport().set_input_as_handled()


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	# Allow dropping items into this slot (always allow, even if same slot - will be ignored)
	return data is Dictionary and data.has("slot_index")


func _drop_data(_position: Vector2, data: Variant) -> void:
	# Handle drop - data should contain source slot index
	if data is Dictionary and data.has("slot_index"):
		var source_slot: int = data["slot_index"]
		if source_slot != slot_index:
			# Emit signal for parent to handle the swap/move
			item_dropped.emit(source_slot, slot_index)
	
	# Reset drag state
	if is_dragging:
		is_dragging = false
		add_theme_stylebox_override("panel", _normal_style)
		drag_ended.emit()


func _get_drag_data(_position: Vector2) -> Variant:
	# Return data for drag operation
	if item == null:
		return null
	
	# Set drag visual state
	is_dragging = true
	add_theme_stylebox_override("panel", _drag_style)
	drag_started.emit(slot_index)
	
	# Create drag preview - use item icon (works for both static and animated)
	var preview: Control = Control.new()
	var preview_icon: TextureRect = TextureRect.new()
	if item != null and item.icon != null:
		preview_icon.texture = item.icon
	else:
		preview_icon.texture = icon.texture  # Fallback
	preview_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.custom_minimum_size = Vector2(48, 48)
	preview.add_child(preview_icon)
	set_drag_preview(preview)
	
	# Return drag data
	return {
		"slot_index": slot_index,
		"item": item,
		"count": count
	}


func set_highlighted(value: bool) -> void:
	is_highlighted = value
	if highlight_overlay != null:
		highlight_overlay.visible = value
	if value:
		add_theme_stylebox_override("panel", _highlight_style)
	else:
		add_theme_stylebox_override("panel", _normal_style)


func _mouse_enter() -> void:
	if item != null:
		set_highlighted(true)


func _mouse_exit() -> void:
	set_highlighted(false)


func _notification(what: int) -> void:
	# Handle drag cancellation (when drag ends without dropping)
	if what == NOTIFICATION_DRAG_END:
		if is_dragging:
			is_dragging = false
			add_theme_stylebox_override("panel", _normal_style)
			drag_ended.emit()
