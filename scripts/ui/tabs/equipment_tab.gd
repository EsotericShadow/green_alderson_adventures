extends Control
## Equipment Tab - Shows equipment slots in the player panel sidebar

const LOG_PREFIX := "[EQUIPMENT_TAB] "
const EQUIP_SLOT_SCENE: PackedScene = preload("res://scenes/ui/equip_slot.tscn")
const StatDefs = preload("res://scripts/stat_constants.gd")

const STAT_CONFIG := [
	{
		"id": StatDefs.STAT_RESILIENCE,
		"label": "Resilience",
		"icon": preload("res://resources/assets/skill_icons/stat_str.png")
	},
	{
		"id": StatDefs.STAT_AGILITY,
		"label": "Agility",
		"icon": preload("res://resources/assets/skill_icons/stat_dex.png")
	},
	{
		"id": StatDefs.STAT_INT,
		"label": "Intelligence",
		"icon": preload("res://resources/assets/skill_icons/stat_int.png")
	},
	{
		"id": StatDefs.STAT_VIT,
		"label": "Vitality",
		"icon": preload("res://resources/assets/skill_icons/stat_vit.png")
	}
]

@onready var equip_container: VBoxContainer = $VBoxContainer/EquipContainer
@onready var stats_list: VBoxContainer = $VBoxContainer/EquipmentStats/StatsList

var slots: Dictionary = {}
var _stat_rows: Dictionary = {}


func _ready() -> void:
	print(LOG_PREFIX + "Equipment tab ready")
	_create_slots()
	_build_stat_rows()
	# Defer update to ensure all slots are ready with @onready vars initialized
	call_deferred("_refresh_ui")
	
	# Connect to equipment changes
	if InventorySystem != null:
		InventorySystem.equipment_changed.connect(_on_equipment_changed)
	if PlayerStats != null and not PlayerStats.stat_changed.is_connected(_on_stat_changed):
		PlayerStats.stat_changed.connect(_on_stat_changed)


func _refresh_ui() -> void:
	_update_slots()
	_update_bonus_rows()


func _create_slots() -> void:
	if equip_container == null:
		push_error(LOG_PREFIX + "equip_container is null!")
		return
	
	print(LOG_PREFIX + "Creating equipment slots...")
	
	# Create rows matching inventory UI layout
	var row1: HBoxContainer = HBoxContainer.new()
	row1.alignment = BoxContainer.ALIGNMENT_CENTER
	equip_container.add_child(row1)
	
	var row2: HBoxContainer = HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	equip_container.add_child(row2)
	
	var row3: HBoxContainer = HBoxContainer.new()
	row3.alignment = BoxContainer.ALIGNMENT_CENTER
	equip_container.add_child(row3)
	
	var row4: HBoxContainer = HBoxContainer.new()
	row4.alignment = BoxContainer.ALIGNMENT_CENTER
	equip_container.add_child(row4)
	
	# Row 1: head (centered single column)
	_create_equip_slot("head", row1)
	
	# Row 2: book, body, weapon (3 columns)
	_create_equip_slot("book", row2)
	_create_equip_slot("body", row2)
	_create_equip_slot("weapon", row2)
	
	# Row 3: ring slots + armor (4 columns)
	_create_equip_slot("ring1", row3)
	_create_equip_slot("ring2", row3)
	_create_equip_slot("legs", row3)
	_create_equip_slot("gloves", row3)
	
	# Row 4: amulet, boots (2 columns)
	_create_equip_slot("amulet", row4)
	_create_equip_slot("boots", row4)
	
	print(LOG_PREFIX + "Created ", slots.size(), " equipment slots")


func _create_equip_slot(slot_name: String, parent: HBoxContainer) -> void:
	var slot: Control = EQUIP_SLOT_SCENE.instantiate()
	parent.add_child(slot)
	if slot.has_signal("slot_clicked"):
		slot.slot_clicked.connect(_on_slot_clicked)
	slots[slot_name] = slot
	print(LOG_PREFIX + "Created slot: ", slot_name)


func _update_slots(slot_name: String = "") -> void:
	if InventorySystem == null:
		print(LOG_PREFIX + "InventorySystem is null!")
		return

	if slot_name == "":
		for slot_key in slots.keys():
			_update_slot(slot_key)
	else:
		_update_slot(slot_name)


func _update_slot(slot_name: String) -> void:
	if not slots.has(slot_name):
		return
	var slot: Control = slots[slot_name]
	var equipment: EquipmentData = InventorySystem.get_equipped(slot_name)
	if slot.has_method("setup"):
		slot.setup(slot_name, equipment)
	else:
		push_error(LOG_PREFIX + "Slot ", slot_name, " doesn't have setup() method!")


func _on_equipment_changed(slot_name: String = "") -> void:
	_update_slots(slot_name)
	_update_bonus_rows()


func _on_slot_clicked(slot_name: String) -> void:
	var result := InventoryUIHandler.unequip_slot(slot_name)
	if result["success"]:
		_update_slots(slot_name)
		_update_bonus_rows()


func _on_stat_changed(stat_name: String, _new_value: int) -> void:
	if _stat_rows.has(stat_name):
		_update_bonus_rows(stat_name)


func _build_stat_rows() -> void:
	if stats_list == null:
		return
	for child in stats_list.get_children():
		child.queue_free()
	_stat_rows.clear()
	for config in STAT_CONFIG:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 4)
		header.alignment = BoxContainer.ALIGNMENT_BEGIN
		var icon_rect := TextureRect.new()
		icon_rect.texture = config["icon"]
		icon_rect.custom_minimum_size = Vector2(14, 14)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		header.add_child(icon_rect)
		var title := Label.new()
		title.text = config["label"]
		title.add_theme_font_size_override("font_size", 10)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(title)
		row.add_child(header)
		var base_label := Label.new()
		base_label.add_theme_font_size_override("font_size", 9)
		row.add_child(base_label)
		var equip_label := Label.new()
		equip_label.add_theme_font_size_override("font_size", 9)
		row.add_child(equip_label)
		var total_label := Label.new()
		total_label.add_theme_font_size_override("font_size", 9)
		total_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		row.add_child(total_label)
		stats_list.add_child(row)
		_stat_rows[config["id"]] = {
			"base": base_label,
			"equip": equip_label,
			"total": total_label
		}


func _update_bonus_rows(stat_name: String = "") -> void:
	if _stat_rows.is_empty():
		return
	var targets: Array = []
	if stat_name == "" or not _stat_rows.has(stat_name):
		targets = _stat_rows.keys()
	else:
		targets.append(stat_name)
	for stat_id in targets:
		var labels: Dictionary = _stat_rows.get(stat_id, {})
		if labels.is_empty():
			continue
		var base_value: int = _get_base_stat_value(stat_id)
		var equipment_bonus: int = _get_equipment_bonus(stat_id)
		var total_value: int = _get_total_stat_value(stat_id)
		(labels.get("base") as Label).text = "Base: " + str(base_value)
		(labels.get("equip") as Label).text = "Equipment: " + _format_signed(equipment_bonus)
		(labels.get("total") as Label).text = "Total: " + str(total_value)


func _get_base_stat_value(stat_name: String) -> int:
	if PlayerStats == null:
		return 0
	return PlayerStats.get_base_stat_level(stat_name)


func _get_equipment_bonus(stat_name: String) -> int:
	if InventorySystem == null:
		return 0
	return InventorySystem.get_total_stat_bonus(stat_name)


func _get_total_stat_value(stat_name: String) -> int:
	if PlayerStats == null:
		return 0
	match stat_name:
		StatDefs.STAT_RESILIENCE:
			return PlayerStats.get_total_resilience()
		StatDefs.STAT_AGILITY:
			return PlayerStats.get_total_agility()
		StatDefs.STAT_INT:
			return PlayerStats.get_total_int()
		StatDefs.STAT_VIT:
			return PlayerStats.get_total_vit()
		_:
			return 0


func _format_signed(value: int) -> String:
	if value > 0:
		return "+" + str(value)
	return str(value)
