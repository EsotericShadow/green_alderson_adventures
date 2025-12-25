extends CanvasLayer
## Tool Belt UI - 5 quick item slots (F1-F5) displayed below spell hotbar

const LOG_PREFIX := "[TOOL_BELT] "
const NUM_SLOTS: int = 5

@onready var slot_container: HBoxContainer = $Control/HBoxContainer

var slots: Array[Control] = []

const QUICK_BELT_SLOT_SCENE: PackedScene = preload("res://scenes/ui/quick_belt_slot.tscn")


func _ready() -> void:
	layer = 19  # Same layer as spell hotbar
	print(LOG_PREFIX + "Tool belt ready")
	_create_slots()
	_update_slots()
	
	# Connect to inventory changes
	if InventorySystem != null:
		InventorySystem.inventory_changed.connect(_on_inventory_changed)


func _create_slots() -> void:
	# Create 5 quick belt slots
	for i in range(NUM_SLOTS):
		var slot: Control = QUICK_BELT_SLOT_SCENE.instantiate()
		slot_container.add_child(slot)
		slots.append(slot)
		if slot.has_method("setup"):
			slot.setup(i, i)  # slot_index, inventory_slot_index


func _update_slots() -> void:
	# Sync with inventory slots 0-4
	if InventorySystem == null:
		return
	
	for i in range(min(slots.size(), NUM_SLOTS)):
		var inventory_slot: Dictionary = InventorySystem.get_slot(i)
		var slot: Control = slots[i]
		
		if slot.has_method("update_item"):
			slot.update_item(inventory_slot.get("item"), inventory_slot.get("count", 0))


func _on_inventory_changed() -> void:
	_update_slots()


func use_slot(index: int) -> bool:
	# Called when player presses F1-F5 to use quick belt item
	if index < 0 or index >= slots.size():
		return false
	
	var inventory_slot: Dictionary = InventorySystem.get_slot(index)
	var item: ItemData = inventory_slot.get("item")
	
	if item == null:
		print(LOG_PREFIX + "Slot ", index, " is empty")
		return false
	
	# TODO: Implement item usage logic (consumables, potions, etc.)
	# For now, just remove one item
	if item.item_type == "consumable":
		InventorySystem.remove_item(item, 1)
		print(LOG_PREFIX + "Used item: ", item.display_name)
		return true
	
	return false

