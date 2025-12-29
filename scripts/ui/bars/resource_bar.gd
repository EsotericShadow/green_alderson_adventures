extends Control
## Reusable resource bar component (mana/stamina)
## Two-tone gradient fill with white border and rounded edges

@export var bar_color: Color = Color.BLUE  # Set to blue for mana, green for stamina
@export var signal_name: String = "mana_changed"  # Which PlayerStats signal to listen to
@export var fill_offset_x: float = 0.0  # Horizontal offset for the fill bar (positive = right, negative = left)
@export var fill_offset_y: float = 0.0  # Vertical offset for the fill bar (positive = down, negative = up)
@export var fill_scale: float = 1.0  # Scale factor for the fill bar (1.0 = normal, 1.25 = 25% larger)
@export var fill_width_adjustment: float = 0.0  # Additional width adjustment in pixels (positive = wider, negative = narrower)
@export var fill_height_adjustment: float = 0.0  # Additional height adjustment in pixels (positive = taller, negative = shorter)
@export var show_border: bool = true  # Whether to show the white border

@onready var border_panel: Panel = $BorderPanel
@onready var fill_container: Control = $FillContainer
@onready var fill_background: Panel = get_node_or_null("FillContainer/Background")
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
		"health_changed":
			current_value = PlayerStats.health
			max_value = PlayerStats.get_max_health()
	call_deferred("_update_bar")


func _setup_style() -> void:
	# Setup border with rounded corners using StyleBoxFlat (only if show_border is true)
	if show_border:
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
	else:
		# Hide the border panel if border is disabled
		border_panel.visible = false
	
	# Setup background panel (dark grey/black) for fill container
	if fill_background != null:
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)  # Dark grey background
		bg_style.corner_radius_top_left = 4
		bg_style.corner_radius_top_right = 4
		bg_style.corner_radius_bottom_left = 4
		bg_style.corner_radius_bottom_right = 4
		fill_background.add_theme_stylebox_override("panel", bg_style)
	
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
		"health_changed":
			PlayerStats.health_changed.connect(_on_value_changed)
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
	
	# Calculate full bar dimensions (for background)
	var full_width: float = (size.x - 2.0) * fill_scale + fill_width_adjustment
	full_width = max(0.0, full_width)
	var scaled_height: float = (size.y * fill_scale) + fill_height_adjustment
	
	# Apply scale factor to fill width (current health portion)
	fill_width *= fill_scale
	fill_width += fill_width_adjustment  # Apply width adjustment
	fill_width = max(0.0, fill_width)  # Ensure width doesn't go negative
	
	# FillContainer should be full width to show background, but we'll clip the fill bars
	fill_container.size.x = full_width
	fill_container.size.y = scaled_height  # Scaled height with adjustment
	fill_container.position = Vector2(1.0 + fill_offset_x, fill_offset_y)  # Offset horizontally by border + custom offset, vertical offset applied
	
	# Update background to show full width (empty portion)
	if fill_background != null:
		fill_background.size = Vector2(full_width, scaled_height)
		fill_background.position = Vector2(0.0, 0.0)
	
	# Update fill heights for two-tone effect
	# Light fill takes top 60%, dark fill takes bottom 40%
	# Make bars extend fully to bottom to cover any gaps
	var bar_height: float = scaled_height  # Use scaled height
	fill_light.size = Vector2(fill_width, bar_height * 0.6)
	fill_light.position = Vector2(0.0, 0.0)
	
	# Dark fill extends to the very bottom to eliminate transparent gap
	var dark_fill_height: float = bar_height - (bar_height * 0.6)  # Remaining height
	fill_dark.size = Vector2(fill_width, dark_fill_height + 0.5)  # Add small buffer to cover gap
	fill_dark.position = Vector2(0.0, bar_height * 0.6)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_bar()
