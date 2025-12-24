extends Control
## Reusable resource bar component (mana/stamina)
## Two-tone gradient fill with white border and rounded edges

@export var bar_color: Color = Color.BLUE  # Set to blue for mana, green for stamina
@export var signal_name: String = "mana_changed"  # Which PlayerStats signal to listen to

@onready var border_panel: Panel = $BorderPanel
@onready var fill_container: Control = $FillContainer
@onready var fill_light: Panel = $FillContainer/LightFill
@onready var fill_dark: Panel = $FillContainer/DarkFill

var max_value: int = 100
var current_value: int = 100


func _ready() -> void:
	_setup_style()
	_connect_signal()
	# Get initial values from PlayerStats
	match signal_name:
		"mana_changed":
			current_value = PlayerStats.mana
			max_value = PlayerStats.get_max_mana()
		"stamina_changed":
			current_value = PlayerStats.stamina
			max_value = PlayerStats.get_max_stamina()
	call_deferred("_update_bar")


func _setup_style() -> void:
	# Setup border with rounded corners using StyleBoxFlat
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)  # Transparent background
	border_style.border_color = Color.WHITE
	border_style.border_width_left = 1
	border_style.border_width_top = 1
	border_style.border_width_right = 1
	border_style.border_width_bottom = 1
	border_style.corner_radius_top_left = 6
	border_style.corner_radius_top_right = 6
	border_style.corner_radius_bottom_left = 6
	border_style.corner_radius_bottom_right = 6
	border_panel.add_theme_stylebox_override("panel", border_style)
	
	# Setup two-tone fill colors with rounded corners
	var light_color: Color = bar_color.lightened(0.4)  # Light tone on top
	var dark_color: Color = bar_color.darkened(0.3)     # Darker mid-value tone on bottom
	
	# Create StyleBoxFlat for light fill with rounded corners
	var light_style = StyleBoxFlat.new()
	light_style.bg_color = light_color
	light_style.corner_radius_top_left = 4
	light_style.corner_radius_top_right = 4
	light_style.corner_radius_bottom_left = 0
	light_style.corner_radius_bottom_right = 0
	fill_light.add_theme_stylebox_override("panel", light_style)
	
	# Create StyleBoxFlat for dark fill with rounded corners
	var dark_style = StyleBoxFlat.new()
	dark_style.bg_color = dark_color
	dark_style.corner_radius_top_left = 0
	dark_style.corner_radius_top_right = 0
	dark_style.corner_radius_bottom_left = 4
	dark_style.corner_radius_bottom_right = 4
	fill_dark.add_theme_stylebox_override("panel", dark_style)


func _connect_signal() -> void:
	match signal_name:
		"mana_changed":
			PlayerStats.mana_changed.connect(_on_value_changed)
		"stamina_changed":
			PlayerStats.stamina_changed.connect(_on_value_changed)
		_:
			push_error("Unknown signal_name: " + signal_name)


func _on_value_changed(current: int, maximum: int) -> void:
	current_value = current
	max_value = maximum
	_update_bar()


func _update_bar() -> void:
	if max_value <= 0:
		fill_container.size.x = 0.0
		fill_light.size.x = 0.0
		fill_dark.size.x = 0.0
		return
	
	var percentage: float = float(current_value) / float(max_value)
	var fill_width: float = (size.x - 2.0) * percentage  # -2 for border padding (1px each side)
	fill_width = max(0.0, fill_width)
	fill_container.size.x = fill_width
	fill_container.size.y = size.y  # Full height to cover border area
	fill_container.position = Vector2(1.0, 0.0)  # Offset horizontally by border, start at top
	
	# Update fill heights for two-tone effect
	# Light fill takes top 60%, dark fill takes bottom 40%
	# Make bars extend fully to bottom to cover any gaps
	var bar_height: float = size.y  # Full height to compensate for thinner border
	fill_light.size = Vector2(fill_width, bar_height * 0.6)
	fill_light.position = Vector2(0.0, 0.0)
	
	# Dark fill extends to the very bottom to eliminate transparent gap
	var dark_fill_height: float = bar_height - (bar_height * 0.6)  # Remaining height
	fill_dark.size = Vector2(fill_width, dark_fill_height + 0.5)  # Add small buffer to cover gap
	fill_dark.position = Vector2(0.0, bar_height * 0.6)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_bar()
