extends Control
## Element stat row (Fire, Water, Earth, Air) with level and XP bar

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var level_label: Label = $HBoxContainer/VBoxContainer/LevelLabel
@onready var xp_bar: ProgressBar = $HBoxContainer/VBoxContainer/XPBar
@onready var xp_label: Label = $HBoxContainer/VBoxContainer/XPLabel

var element: String = ""
var _initialized: bool = false

# Element colors (matching spell system)
const ELEMENT_COLORS: Dictionary = {
	"fire": Color(1.0, 0.27, 0.27),      # Red #FF4444
	"water": Color(0.27, 0.67, 1.0),     # Cyan #44AAFF
	"earth": Color(0.27, 0.67, 0.27),    # Green #44AA44
	"air": Color(0.53, 0.8, 1.0)         # Light Blue #88CCFF
}


func setup(element_name: String) -> void:
	element = element_name
	
	# Capitalize element name
	var display_name: String = element.capitalize()
	if name_label != null:
		name_label.text = display_name
	
	# Load spell icon (smaller size)
	var icon_filename: String = "spell_icon_lvl_1(blue).png"
	match element:
		"fire":
			icon_filename = "spell_icon_lvl_1(fire).png"
		"water":
			icon_filename = "spell_icon_lvl_1(water).png"
		"earth":
			icon_filename = "spell_icon_lvl_1(earth).png"
		"air":
			icon_filename = "spell_icon_lvl_1(air).png"
	
	var icon_path: String = "res://resources/assets/animations/UI/spell_hotbar_icons/spell_ball_blast/" + icon_filename
	var texture: Texture2D = load(icon_path) as Texture2D
	if texture != null:
		if icon != null:
			icon.texture = texture
			icon.custom_minimum_size = Vector2(24, 24)  # Smaller than spell hotbar icons
			icon.visible = true
	else:
		if icon != null:
			icon.visible = false
		push_error("[ElementStatRow] Failed to load icon: " + icon_path)
	
	# Set XP bar color
	if xp_bar != null and ELEMENT_COLORS.has(element):
		var style_box: StyleBoxFlat = xp_bar.get_theme_stylebox("fill")
		if style_box != null:
			style_box = style_box.duplicate() as StyleBoxFlat
			if style_box != null:
				style_box.bg_color = ELEMENT_COLORS[element]
				xp_bar.add_theme_stylebox_override("fill", style_box)
	
	_initialized = true


func update_element(element_name: String, level: int, current_xp: int, xp_needed: int) -> void:
	if element_name != element:
		return
	
	if level_label != null:
		level_label.text = "Lv. " + str(level)
	
	# Update XP bar
	if xp_bar != null:
		xp_bar.max_value = xp_needed
		xp_bar.value = current_xp
		xp_bar.show_percentage = false
	
	# Update XP label
	if xp_label != null:
		xp_label.text = str(current_xp) + " / " + str(xp_needed)

