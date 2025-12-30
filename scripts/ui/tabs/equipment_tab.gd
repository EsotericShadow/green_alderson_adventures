extends Control
## Equipment Tab - Shows equipment slots in the player panel sidebar

const LOG_PREFIX := "[EQUIPMENT_TAB] "
const EQUIP_SLOT_SCENE: PackedScene = preload("res://scenes/ui/equip_slot.tscn")

@onready var equip_container: VBoxContainer = $VBoxContainer/EquipContainer

var slots: Dictionary = {}


func _ready() -> void:
	print(LOG_PREFIX + "Equipment tab ready")
	_create_slots()
	# Defer update to ensure all slots are ready with @onready vars initialized
	call_deferred("_update_slots")
	
	# Connect to equipment changes
	if InventorySystem != null:
		InventorySystem.equipment_changed.connect(_on_equipment_changed)


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


func _on_slot_clicked(slot_name: String) -> void:
	var result := InventoryUIHandler.unequip_slot(slot_name)
	if result["success"]:
		_update_slots(slot_name)
