extends Control
## Stats Tab - Base stats and element levels with XP bars

const LOG_PREFIX := "[STATS_TAB] "

# Base stat rows
@onready var str_row: Control = $VBoxContainer/BaseStatsSection/VBoxContainer/StrRow
@onready var dex_row: Control = $VBoxContainer/BaseStatsSection/VBoxContainer/DexRow
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
	
	# Initialize stat rows with icons on first update
	if str_row.has_method("setup") and not str_row.get("_initialized"):
		str_row.setup("STR", "res://assets/ui/icons/skills/stat_str.png")
	if dex_row.has_method("setup") and not dex_row.get("_initialized"):
		dex_row.setup("DEX", "res://assets/ui/icons/skills/stat_dex.png")
	if int_row.has_method("setup") and not int_row.get("_initialized"):
		int_row.setup("INT", "res://assets/ui/icons/skills/stat_int.png")
	if vit_row.has_method("setup") and not vit_row.get("_initialized"):
		vit_row.setup("VIT", "res://assets/ui/icons/skills/stat_vit.png")
	
	# Update base stat rows
	if str_row.has_method("update_stat"):
		str_row.update_stat("STR", PlayerStats.get_total_str())
	if dex_row.has_method("update_stat"):
		dex_row.update_stat("DEX", PlayerStats.get_total_dex())
	if int_row.has_method("update_stat"):
		int_row.update_stat("INT", PlayerStats.get_total_int())
	if vit_row.has_method("update_stat"):
		vit_row.update_stat("VIT", PlayerStats.get_total_vit())


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
			var current_xp: int = SpellSystem.get_xp(element)
			var xp_needed: int = SpellSystem.get_xp_for_next_level(element)
			row.update_element(element, level, current_xp, xp_needed)


func _on_stat_changed(_stat_name: String, _new_value: int) -> void:
	_update_base_stats()


func _on_xp_gained(_element: String, _amount: int, _total: int) -> void:
	_update_element_stats()


func _on_element_leveled_up(_element: String, _new_level: int) -> void:
	_update_element_stats()
