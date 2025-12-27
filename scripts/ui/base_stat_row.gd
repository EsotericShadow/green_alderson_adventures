extends Control
## Base stat row (Resilience, Agility, INT, VIT) display with XP bar

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var value_label: Label = $HBoxContainer/ValueLabel
# XP elements (optional - may not exist in scene yet)
var vbox_container: VBoxContainer = null
var level_label: Label = null
var xp_bar: ProgressBar = null
var xp_label: Label = null

var stat_name: String = ""
var _initialized: bool = false


func _ready() -> void:
	# Try to find XP elements (they may not exist in the scene yet)
	vbox_container = get_node_or_null("HBoxContainer/VBoxContainer")
	if vbox_container != null:
		level_label = vbox_container.get_node_or_null("LevelLabel")
		xp_bar = vbox_container.get_node_or_null("XPBar")
		xp_label = vbox_container.get_node_or_null("XPLabel")


# Base stat colors
const STAT_COLORS: Dictionary = {
	"Resilience": Color(0.8, 0.4, 0.2),      # Brown/Orange
	"Agility": Color(0.2, 0.8, 0.4),         # Green
	"INT": Color(0.4, 0.6, 1.0),             # Blue
	"VIT": Color(1.0, 0.3, 0.3)              # Red
}


func setup(stat: String, icon_path: String) -> void:
	stat_name = stat
	if name_label != null:
		name_label.text = stat
	
	# Load icon
	var texture: Texture2D = load(icon_path) as Texture2D
	if texture != null:
		if icon != null:
			icon.texture = texture
			icon.visible = true
	else:
		if icon != null:
			icon.visible = false
		push_error("[BaseStatRow] Failed to load icon: " + icon_path)
	
	# Set XP bar color
	if xp_bar != null and STAT_COLORS.has(stat):
		var style_box: StyleBoxFlat = xp_bar.get_theme_stylebox("fill")
		if style_box != null:
			style_box = style_box.duplicate() as StyleBoxFlat
			if style_box != null:
				style_box.bg_color = STAT_COLORS[stat]
				xp_bar.add_theme_stylebox_override("fill", style_box)
	
	_initialized = true


func update_stat(stat: String, value: int) -> void:
	if stat != stat_name:
		return
	
	# Update level label if it exists, otherwise update value label
	if level_label != null:
		level_label.text = "Lv. " + str(value)
	elif value_label != null:
		value_label.text = str(value)


func update_stat_with_xp(stat: String, level: int, current_xp: int, xp_needed: int) -> void:
	"""Updates stat display with level and XP information."""
	if stat != stat_name:
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
