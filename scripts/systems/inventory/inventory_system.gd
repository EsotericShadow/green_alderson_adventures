extends Node
## Global inventory system (autoload singleton) - FACADE.
## Manages slot-based inventory. Delegates equipment to EquipmentSystem.
## Delegates item usage to ItemUsageHandler.

# Logging
var _logger = GameLogger.create("[InventorySystem] ")

# Constants (LOCKED per SPEC.md)
const DEFAULT_CAPACITY: int = 28  # 7 rows of 4 slots
const MAX_CAPACITY: int = 48

# Signals (LOCKED NAMES per SPEC.md)
signal inventory_changed
signal item_added(item: ItemData, count: int, slot_index: int)
signal item_removed(item: ItemData, count: int, slot_index: int)
signal equipment_changed(slot_name: String)

# Inventory Slots (LOCKED STRUCTURE per SPEC.md)
# Each slot is: { "item": ItemData or null, "count": int }
var slots: Array[Dictionary] = []
var capacity: int = DEFAULT_CAPACITY

func _ready() -> void:
	_logger.log("InventorySystem initialized")
	_logger.log("  Capacity: " + str(capacity))
	_init_slots()
	_logger.log("  Initialized " + str(slots.size()) + " inventory slots")
	
	# Connect to EquipmentSystem signals and forward them
	if EquipmentSystem != null:
		EquipmentSystem.equipment_changed.connect(_on_equipment_changed)
	else:
		_logger.log_warning("EquipmentSystem not available - equipment features will not work")
	
	# Load starting inventory from data file
	_load_starting_inventory()
	
	# Load starting equipment from data file (delegates to EquipmentSystem)
	_load_starting_equipment()


func _on_equipment_changed(slot_name: String) -> void:
	"""Forwards equipment_changed signal from EquipmentSystem."""
	equipment_changed.emit(slot_name)


func _init_slots() -> void:
	# Initialize all slots as empty
	slots.clear()
	for i in range(capacity):
		slots.append({ "item": null, "count": 0 })


# Inventory Methods (LOCKED SIGNATURES per SPEC.md)

func add_item(item: ItemData, count: int = 1) -> int:
	# Returns leftover count (items that couldn't be added)
	if item == null:
		_logger.log_error("add_item() called with null item")
		return count
	
	_logger.log("Adding item: " + item.display_name + " x" + str(count))
	var remaining: int = count
	
	# If item is stackable, try to add to existing stack first
	if item.stackable:
		var existing_slot: int = find_item_slot(item)
		if existing_slot != -1:
			var slot: Dictionary = slots[existing_slot]
			var space_available: int = item.max_stack - slot["count"]
			if space_available > 0:
				var to_add: int = min(space_available, remaining)
				slot["count"] += to_add
				remaining -= to_add
				_logger.log("  Added " + str(to_add) + " to existing stack in slot " + str(existing_slot))
				item_added.emit(item, to_add, existing_slot)
				inventory_changed.emit()
	
	# Add remaining items to new slots
	while remaining > 0:
		var empty_slot: int = find_empty_slot()
		if empty_slot == -1:
			# Inventory full
			_logger.log("  Inventory full! " + str(remaining) + " items could not be added")
			break
		
		var slot: Dictionary = slots[empty_slot]
		var to_add: int = min(item.max_stack, remaining) if item.stackable else 1
		slot["item"] = item
		slot["count"] = to_add
		remaining -= to_add
		_logger.log("  Added " + str(to_add) + " to new slot " + str(empty_slot))
		item_added.emit(item, to_add, empty_slot)
		inventory_changed.emit()
	
	if remaining > 0:
		_logger.log("  ⚠️ " + str(remaining) + " items could not be added (inventory full)")
	
	return remaining


func remove_item(item: ItemData, count: int = 1) -> bool:
	# Returns true if all items were removed, false otherwise
	if item == null:
		_logger.log_error("remove_item() called with null item")
		return false
	
	_logger.log("Removing item: " + item.display_name + " x" + str(count))
	var remaining: int = count
	
	# Find all slots with this item
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if slot["item"] == item and slot["count"] > 0:
			var to_remove: int = min(slot["count"], remaining)
			slot["count"] -= to_remove
			remaining -= to_remove
			
			_logger.log("  Removed " + str(to_remove) + " from slot " + str(i))
			
			if slot["count"] <= 0:
				slot["item"] = null
				slot["count"] = 0
			
			item_removed.emit(item, to_remove, i)
			inventory_changed.emit()
			
			if remaining <= 0:
				break
	
	if remaining > 0:
		_logger.log("  ⚠️ Could not remove " + str(remaining) + " items (not enough in inventory)")
	
	return remaining <= 0


func has_item(item: ItemData, count: int = 1) -> bool:
	if item == null:
		return false
	
	var total_count: int = 0
	for slot in slots:
		if slot["item"] == item:
			total_count += slot["count"]
			if total_count >= count:
				return true
	
	return false


func use_item(item: ItemData, count: int = 1) -> bool:
	"""Uses a consumable item from inventory - delegates to ItemUsageHandler."""
	if ItemUsageHandler != null:
		return ItemUsageHandler.use_item(item, count)
	_logger.log_error("ItemUsageHandler autoload not available")
	return false


func use_item_at_slot(slot_index: int) -> bool:
	"""Uses an item at a specific slot - delegates to ItemUsageHandler."""
	if ItemUsageHandler != null:
		return ItemUsageHandler.use_item_at_slot(slot_index)
	_logger.log_error("ItemUsageHandler autoload not available")
	return false


func get_item_count(item: ItemData) -> int:
	if item == null:
		return 0
	
	var total: int = 0
	for slot in slots:
		if slot["item"] == item:
			total += slot["count"]
	
	return total


func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return { "item": null, "count": 0 }
	return slots[index]


func set_slot(index: int, item: ItemData, count: int) -> void:
	if index < 0 or index >= slots.size():
		return
	
	var slot: Dictionary = slots[index]
	var old_item: ItemData = slot["item"]
	var old_count: int = slot["count"]
	
	slot["item"] = item
	slot["count"] = count
	
	# Emit signals if changed
	if old_item != item or old_count != count:
		if old_item != null:
			item_removed.emit(old_item, old_count, index)
		if item != null:
			item_added.emit(item, count, index)
		inventory_changed.emit()


func clear_slot(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	
	var slot: Dictionary = slots[index]
	var old_item: ItemData = slot["item"]
	var old_count: int = slot["count"]
	
	if old_item != null:
		slot["item"] = null
		slot["count"] = 0
		item_removed.emit(old_item, old_count, index)
		inventory_changed.emit()


func find_item_slot(item: ItemData) -> int:
	# Returns index of first slot containing this item, or -1 if not found
	if item == null:
		return -1
	
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if slot["item"] == item:
			return i
	
	return -1


func find_empty_slot() -> int:
	# Returns index of first empty slot, or -1 if inventory full
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if slot["item"] == null:
			return i
	
	return -1


func expand_capacity(additional_slots: int) -> void:
	var new_capacity: int = capacity + additional_slots
	if new_capacity > MAX_CAPACITY:
		new_capacity = MAX_CAPACITY
	
	var slots_to_add: int = new_capacity - capacity
	if slots_to_add <= 0:
		return
	
	# Add new empty slots
	for i in range(slots_to_add):
		slots.append({ "item": null, "count": 0 })
	
	capacity = new_capacity
	inventory_changed.emit()


# Equipment Methods (LOCKED SIGNATURES per SPEC.md) - delegates to EquipmentSystem

func equip(item: EquipmentData) -> bool:
	"""Equips an item - delegates to EquipmentSystem."""
	if EquipmentSystem != null:
		return EquipmentSystem.equip(item)
	_logger.log_error("EquipmentSystem not available")
	return false


func unequip(slot_name: String) -> EquipmentData:
	"""Unequips an item - delegates to EquipmentSystem."""
	if EquipmentSystem != null:
		return EquipmentSystem.unequip(slot_name)
	_logger.log_error("EquipmentSystem not available")
	return null


func get_equipped(slot_name: String) -> EquipmentData:
	"""Gets equipped item - delegates to EquipmentSystem."""
	if EquipmentSystem != null:
		return EquipmentSystem.get_equipped(slot_name)
	return null


func get_total_stat_bonus(stat_name: String) -> int:
	"""Returns sum of stat bonuses from all equipped items - delegates to EquipmentSystem."""
	if EquipmentSystem != null:
		return EquipmentSystem.get_total_stat_bonus(stat_name)
	return 0


func get_total_damage_bonus() -> int:
	"""Returns sum of flat damage bonuses - delegates to EquipmentSystem."""
	if EquipmentSystem != null:
		return EquipmentSystem.get_total_damage_bonus()
	return 0


func get_total_damage_percentage() -> float:
	"""Returns sum of percentage damage bonuses - delegates to EquipmentSystem."""
	if EquipmentSystem != null:
		return EquipmentSystem.get_total_damage_percentage()
	return 0.0


# Backwards compatibility: expose equipment dictionary (read-only access)
var equipment: Dictionary:
	get:
		if EquipmentSystem != null:
			return EquipmentSystem.equipment
		return {}


func get_current_carry_weight() -> float:
	"""Calculates current total weight - delegates to CarryWeightSystem."""
	if CarryWeightSystem != null:
		return CarryWeightSystem.get_current_carry_weight()
	return 0.0


func can_carry_item(item: ItemData, count: int = 1) -> bool:
	"""Checks if player can carry additional items - delegates to CarryWeightSystem."""
	if CarryWeightSystem == null or PlayerStats == null:
		return false
	var resilience: int = PlayerStats.get_total_resilience()
	return CarryWeightSystem.can_carry_item(item, count, resilience)


func _load_starting_inventory() -> void:
	"""Loads starting inventory from data file."""
	var starting_inventory_path: String = "res://resources/config/starting_inventory.tres"
	var starting_data: StartingInventoryData = load(starting_inventory_path) as StartingInventoryData
	
	if starting_data == null:
		_logger.log_warning("Starting inventory data not found at " + starting_inventory_path + " - skipping")
		return
	
	if starting_data.items.is_empty():
		_logger.log("Starting inventory data is empty - skipping")
		return
	
	_logger.log("Loading starting inventory (" + str(starting_data.items.size()) + " item types)...")
	
	for entry in starting_data.items:
		var item_id: String = entry.get("item_id", "")
		var count: int = entry.get("count", 1)
		
		if item_id.is_empty():
			_logger.log_warning("Skipping entry with empty item_id")
			continue
		
		# Try loading as ItemData first (check if file exists to avoid error logs)
		var item: ItemData = null
		var item_path: String = ResourceManager.ITEMS_PATH + item_id + ".tres"
		if ResourceLoader.exists(item_path):
			item = ResourceManager.load_item(item_id)
		
		# If not found, try as PotionData
		if item == null:
			var potion_path: String = ResourceManager.POTIONS_PATH + item_id + ".tres"
			if ResourceLoader.exists(potion_path):
				item = ResourceManager.load_potion(item_id) as ItemData
		
		if item == null:
			_logger.log_warning("Could not load item: " + item_id + " - skipping (not found in items/ or potions/)")
			continue
		
		var added: int = add_item(item, count)
		if added > 0:
			_logger.log_warning("Could not add all " + str(count) + "x " + item.display_name + " (" + str(added) + " remaining)")
		else:
			_logger.log("  Added " + str(count) + "x " + item.display_name)
	
	_logger.log("Starting inventory loaded")


func _load_starting_equipment() -> void:
	"""Loads starting equipment from data file - delegates to EquipmentSystem."""
	if EquipmentSystem == null:
		_logger.log_warning("EquipmentSystem not available - cannot load starting equipment")
		return
	
	var starting_equipment_path: String = "res://resources/config/starting_equipment.tres"
	var starting_data: StartingEquipmentData = load(starting_equipment_path) as StartingEquipmentData
	
	if starting_data == null:
		_logger.log_warning("Starting equipment data not found at " + starting_equipment_path + " - skipping")
		return
	
	if starting_data.equipment.is_empty():
		_logger.log("Starting equipment data is empty - skipping")
		return
	
	_logger.log("Loading starting equipment (" + str(starting_data.equipment.size()) + " items)...")
	
	for entry in starting_data.equipment:
		var expected_slot: String = entry.get("slot", "")
		var equipment_id: String = entry.get("equipment_id", "")
		
		if equipment_id.is_empty():
			_logger.log_warning("Skipping entry with empty equipment_id")
			continue
		
		# Load equipment resource
		var equipment_item: EquipmentData = ResourceManager.load_equipment(equipment_id)
		
		if equipment_item == null:
			_logger.log_warning("Could not load equipment: " + equipment_id + " - skipping")
			continue
		
		# Validate slot matches (optional - slot field is for documentation/validation)
		if not expected_slot.is_empty() and equipment_item.slot != "ring":
			# For non-ring items, slot should match
			if expected_slot != equipment_item.slot:
				_logger.log_warning("  Slot mismatch for " + equipment_id + ": data file says '" + expected_slot + "' but equipment has '" + equipment_item.slot + "'")
		
		# Equip the item via EquipmentSystem
		var success: bool = EquipmentSystem.equip(equipment_item)
		if success:
			var actual_slot: String = equipment_item.slot
			if actual_slot == "ring":
				# Find which ring slot it was equipped to
				if EquipmentSystem.equipment["ring1"] == equipment_item:
					actual_slot = "ring1"
				elif EquipmentSystem.equipment["ring2"] == equipment_item:
					actual_slot = "ring2"
			_logger.log("  Equipped " + equipment_item.display_name + " to " + actual_slot)
		else:
			_logger.log_warning("  Failed to equip " + equipment_item.display_name + " to " + equipment_item.slot)
	
	_logger.log("Starting equipment loaded")
