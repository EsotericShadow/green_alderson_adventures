extends Control
## Base stat row (STR, DEX, INT, VIT) display

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var value_label: Label = $HBoxContainer/ValueLabel

var stat_name: String = ""
var _initialized: bool = false


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
	
	_initialized = true


func update_stat(stat: String, value: int) -> void:
	if stat != stat_name:
		return
	
	if value_label != null:
		value_label.text = str(value)

