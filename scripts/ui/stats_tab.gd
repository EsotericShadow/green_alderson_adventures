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
	
	# Connect to XP/leveling signals from BaseStatLeveling
	if BaseStatLeveling != null:
		BaseStatLeveling.base_stat_xp_gained.connect(_on_base_stat_xp_gained)
		BaseStatLeveling.base_stat_leveled_up.connect(_on_base_stat_leveled_up)
	
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
	if resilience_row.has_method("setup") and not resilience_row.get("_initialized"):
		resilience_row.setup("Resilience", "res://assets/ui/icons/skills/stat_str.png")  # Using same icon for now
	if agility_row.has_method("setup") and not agility_row.get("_initialized"):
		agility_row.setup("Agility", "res://assets/ui/icons/skills/stat_dex.png")  # Using same icon for now
	if int_row.has_method("setup") and not int_row.get("_initialized"):
		int_row.setup("INT", "res://assets/ui/icons/skills/stat_int.png")
	if vit_row.has_method("setup") and not vit_row.get("_initialized"):
		vit_row.setup("VIT", "res://assets/ui/icons/skills/stat_vit.png")
	
	# Update base stat rows with XP information
	if resilience_row.has_method("update_stat_with_xp"):
		var level: int = PlayerStats.base_resilience
		var total_xp: int = PlayerStats.get_base_stat_xp("resilience")
		var xp_for_current: int = BaseStatLeveling.get_base_stat_xp_for_current_level("resilience") if BaseStatLeveling != null else 0
		var xp_for_next: int = PlayerStats.get_base_stat_xp_for_next_level("resilience")
		var xp_in_level: int = total_xp - xp_for_current
		var xp_needed_in_level: int = xp_for_next - xp_for_current
		resilience_row.update_stat_with_xp("Resilience", level, xp_in_level, xp_needed_in_level)
	elif resilience_row.has_method("update_stat"):
		resilience_row.update_stat("Resilience", PlayerStats.get_total_resilience())
	
	if agility_row.has_method("update_stat_with_xp"):
		var level: int = PlayerStats.base_agility
		var total_xp: int = PlayerStats.get_base_stat_xp("agility")
		var xp_for_current: int = BaseStatLeveling.get_base_stat_xp_for_current_level("agility") if BaseStatLeveling != null else 0
		var xp_for_next: int = PlayerStats.get_base_stat_xp_for_next_level("agility")
		var xp_in_level: int = total_xp - xp_for_current
		var xp_needed_in_level: int = xp_for_next - xp_for_current
		agility_row.update_stat_with_xp("Agility", level, xp_in_level, xp_needed_in_level)
	elif agility_row.has_method("update_stat"):
		agility_row.update_stat("Agility", PlayerStats.get_total_agility())
	
	if int_row.has_method("update_stat_with_xp"):
		var level: int = PlayerStats.base_int
		var total_xp: int = PlayerStats.get_base_stat_xp("int")
		var xp_for_current: int = BaseStatLeveling.get_base_stat_xp_for_current_level("int") if BaseStatLeveling != null else 0
		var xp_for_next: int = PlayerStats.get_base_stat_xp_for_next_level("int")
		var xp_in_level: int = total_xp - xp_for_current
		var xp_needed_in_level: int = xp_for_next - xp_for_current
		int_row.update_stat_with_xp("INT", level, xp_in_level, xp_needed_in_level)
	elif int_row.has_method("update_stat"):
		int_row.update_stat("INT", PlayerStats.get_total_int())
	
	if vit_row.has_method("update_stat_with_xp"):
		var level: int = PlayerStats.base_vit
		var total_xp: int = PlayerStats.get_base_stat_xp("vit")
		var xp_for_current: int = BaseStatLeveling.get_base_stat_xp_for_current_level("vit") if BaseStatLeveling != null else 0
		var xp_for_next: int = PlayerStats.get_base_stat_xp_for_next_level("vit")
		var xp_in_level: int = total_xp - xp_for_current
		var xp_needed_in_level: int = xp_for_next - xp_for_current
		vit_row.update_stat_with_xp("VIT", level, xp_in_level, xp_needed_in_level)
	elif vit_row.has_method("update_stat"):
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


func _on_base_stat_xp_gained(_stat_name: String, _amount: int, _total: int) -> void:
	_update_base_stats()


func _on_base_stat_leveled_up(_stat_name: String, _new_level: int) -> void:
	_update_base_stats()


func _on_xp_gained(_element: String, _amount: int, _total: int) -> void:
	_update_element_stats()


func _on_element_leveled_up(_element: String, _new_level: int) -> void:
	_update_element_stats()
