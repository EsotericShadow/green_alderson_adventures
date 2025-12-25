extends Control
## Inventory Tab - Shows inventory grid in the player panel sidebar

const LOG_PREFIX := "[INVENTORY_TAB] "
const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")

@onready var slot_grid: GridContainer = $VBoxContainer/GridContainer

var slots: Array[Control] = []


func _ready() -> void:
	print(LOG_PREFIX + "Inventory tab ready")
	_create_slots()
	_update_slots()
	
	# Connect to inventory changes
	if InventorySystem != null:
		InventorySystem.inventory_changed.connect(_on_inventory_changed)


func _create_slots() -> void:
	if slot_grid == null:
		push_error(LOG_PREFIX + "slot_grid is null!")
		return
	
	# Create inventory slots (4 columns as defined in scene)
	var num_slots: int = InventorySystem.capacity if InventorySystem != null else 30
	
	for i in range(num_slots):
		var slot: Control = SLOT_SCENE.instantiate()
		slot_grid.add_child(slot)
		slots.append(slot)
		if slot.has_method("setup"):
			slot.setup(i, null, 0)


func _update_slots() -> void:
	if InventorySystem == null:
		return
	
	for i in range(min(slots.size(), InventorySystem.capacity)):
		var inventory_slot: Dictionary = InventorySystem.get_slot(i)
		var slot: Control = slots[i]
		
		if slot.has_method("setup"):
			slot.setup(i, inventory_slot.get("item"), inventory_slot.get("count", 0))


func _on_inventory_changed() -> void:
	_update_slots()
