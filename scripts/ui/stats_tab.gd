extends Control
## Stats Tab - Base stats and element levels with XP bars

const LOG_PREFIX := "[STATS_TAB] "

# Base stat rows
@onready var resilience_row: Control = $VBoxContainer/BaseStatsSection/VBoxContainer/StrRow  # Node name unchanged for scene compatibility
@onready var agility_row: Control = $VBoxContainer/BaseStatsSection/VBoxContainer/DexRow  # Node name unchanged for scene compatibility
@onready var int_row: Control = $VBoxContainer/BaseStatsSection/VBoxContainer/IntRow
@onready var vit_row: Control = $VBoxContainer/BaseStatsSection/VBoxContainer/VitRow

# Element stat rows
@onready var fire_row: Control = $VBoxContainer/MagicSkillsSection/VBoxContainer/FireRow
@onready var water_row: Control = $VBoxContainer/MagicSkillsSection/VBoxContainer/WaterRow
@onready var earth_row: Control = $VBoxContainer/MagicSkillsSection/VBoxContainer/EarthRow
@onready var air_row: Control = $VBoxContainer/MagicSkillsSection/VBoxContainer/AirRow


func _ready() -> void:
	print(LOG_PREFIX + "Stats tab ready")
	
	# Connect to stat change signals
	if PlayerStats != null:
		PlayerStats.stat_changed.connect(_on_stat_changed)
	
	# Connect to XP/leveling signals from PlayerStats
	if PlayerStats != null:
		PlayerStats.base_stat_xp_gained.connect(_on_base_stat_xp_gained)
		PlayerStats.base_stat_leveled_up.connect(_on_base_stat_leveled_up)
	
	if SpellSystem != null:
		SpellSystem.xp_gained.connect(_on_xp_gained)
		SpellSystem.element_leveled_up.connect(_on_element_leveled_up)
	
	_update_all_stats()


func _update_all_stats() -> void:
	_update_base_stats()
	_update_element_stats()


func _update_base_stats() -> void:
	if PlayerStats == null:
		return
	
	# Stat configuration array (DRY principle - iterate instead of repeating)
	var stat_configs: Array[Dictionary] = [
		{"name": StatConstants.STAT_RESILIENCE, "row": resilience_row, "icon": "res://assets/ui/icons/skills/stat_str.png"},
		{"name": StatConstants.STAT_AGILITY, "row": agility_row, "icon": "res://assets/ui/icons/skills/stat_dex.png"},
		{"name": StatConstants.STAT_INT, "row": int_row, "icon": "res://assets/ui/icons/skills/stat_int.png"},
		{"name": StatConstants.STAT_VIT, "row": vit_row, "icon": "res://assets/ui/icons/skills/stat_vit.png"}
	]
	
	# Update each stat row using display data from model layer (separation of concerns)
	for config in stat_configs:
		var row: Control = config.row
		var stat_name: String = config.name
		var display_name: String = StatConstants.BASE_STAT_DISPLAY_NAMES[stat_name]
		
		if row == null:
			continue
		
		# Initialize stat row with icon on first update
		if row.has_method("setup") and not row.get("_initialized"):
			row.setup(display_name, config.icon)
		
		# Get display data from model layer (no calculations in UI)
		var display_data: Dictionary = PlayerStats.get_stat_display_data(stat_name)
		
		# Update row with display data
		if row.has_method("update_stat_with_xp"):
			row.update_stat_with_xp(display_name, display_data.level, display_data.xp_in_level, display_data.xp_needed)
		elif row.has_method("update_stat"):
			# Fallback for rows without XP display
			var total_stat: int = 0
			match stat_name:
				StatConstants.STAT_RESILIENCE:
					total_stat = PlayerStats.get_total_resilience()
				StatConstants.STAT_AGILITY:
					total_stat = PlayerStats.get_total_agility()
				StatConstants.STAT_INT:
					total_stat = PlayerStats.get_total_int()
				StatConstants.STAT_VIT:
					total_stat = PlayerStats.get_total_vit()
			row.update_stat(display_name, total_stat)


func _update_element_stats() -> void:
	if SpellSystem == null:
		return
	
	# Initialize element rows on first update
	var elements: Array[String] = ["fire", "water", "earth", "air"]
	var rows: Array[Control] = [fire_row, water_row, earth_row, air_row]
	
	for i in range(elements.size()):
		var element: String = elements[i]
		var row: Control = rows[i]
		
		# Setup on first update
		if row.has_method("setup") and not row.get("_initialized"):
			row.setup(element)
		
		# Update element stats
		if row.has_method("update_element"):
			var level: int = SpellSystem.get_level(element)
			var total_xp: int = SpellSystem.get_xp(element)
			var xp_for_current: int = SpellSystem.get_xp_for_current_level(element)
			var xp_for_next: int = SpellSystem.get_xp_for_next_level(element)
			var xp_in_level: int = max(0, total_xp - xp_for_current)  # Clamp to 0 to prevent negatives
			var xp_needed_in_level: int = max(1, xp_for_next - xp_for_current)  # Ensure at least 1 to prevent division by zero
			row.update_element(element, level, xp_in_level, xp_needed_in_level)


func _on_stat_changed(_stat_name: String, _new_value: int) -> void:
	_update_base_stats()


func _on_base_stat_xp_gained(_stat_name: String, _amount: int, _total: int) -> void:
	_update_base_stats()


func _on_base_stat_leveled_up(_stat_name: String, _new_level: int) -> void:
	_update_base_stats()


func _on_xp_gained(_element: String, _amount: int, _total: int) -> void:
	_update_element_stats()


func _on_element_leveled_up(_element: String, _new_level: int) -> void:
	_update_element_stats()
