extends Node
## Global inventory and equipment system (autoload singleton).
## Manages slot-based inventory and equipment slots with stat bonuses.

# Logging
var _logger = GameLogger.create("[InventorySystem] ")

# Constants (LOCKED per SPEC.md)
const DEFAULT_CAPACITY: int = 12
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

# Equipment Slots (LOCKED NAMES per SPEC.md)
var equipment: Dictionary = {
	"head": null,
	"body": null,
	"gloves": null,
	"boots": null,
	"weapon": null,
	"book": null,  # Off-hand spellbook (replaces shield)
	"ring1": null,
	"ring2": null,
	"legs": null,  # Leg armor
	"amulet": null  # Necklace/amulet
}


func _ready() -> void:
	_logger.log("InventorySystem initialized")
	_logger.log("  Capacity: " + str(capacity))
	_logger.log("  Equipment slots: " + str(equipment.keys()))
	_init_slots()
	_logger.log("  Initialized " + str(slots.size()) + " inventory slots")


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


# Equipment Methods (LOCKED SIGNATURES per SPEC.md)

func equip(item: EquipmentData) -> bool:
	# Returns false if wrong slot type or inventory full when unequipping
	if item == null:
		_logger.log_error("equip() called with null item")
		return false
	
	_logger.log("Equipping: " + item.display_name + " (slot: " + item.slot + ")")
	var slot_name: String = item.slot
	
	# Handle ring slots (ring1 or ring2)
	if item.slot == "ring":
		# Try ring1 first, then ring2
		if equipment["ring1"] == null:
			slot_name = "ring1"
		elif equipment["ring2"] == null:
			slot_name = "ring2"
		else:
			# Both rings full, unequip ring1
			_logger.log("  Both ring slots full, unequipping ring1")
			var unequipped: EquipmentData = unequip("ring1")
			if unequipped == null:
				_logger.log_error("  Failed to unequip ring1 (inventory full)")
				return false  # Failed to unequip (inventory full)
			slot_name = "ring1"
	else:
		# For non-ring items, slot_name must match item.slot
		slot_name = item.slot
	
	# Validate slot type (for non-ring items, slot_name should equal item.slot)
	# For ring items, slot_name will be "ring1" or "ring2" and item.slot will be "ring"
	if item.slot != "ring" and slot_name != item.slot:
		_logger.log_error("  Invalid slot type: " + item.slot + " != " + slot_name)
		return false
	
	# Unequip existing item if any
	var old_item: EquipmentData = equipment[slot_name]
	if old_item != null:
		_logger.log("  Unequipping existing item: " + old_item.display_name)
		var unequipped: EquipmentData = unequip(slot_name)
		if unequipped == null:
			_logger.log_error("  Failed to unequip existing item (inventory full)")
			return false  # Failed to unequip (inventory full)
	
	# Equip new item
	equipment[slot_name] = item
	_logger.log("  ✓ Equipped " + item.display_name + " to " + slot_name)
	equipment_changed.emit(slot_name)
	return true


func unequip(slot_name: String) -> EquipmentData:
	# Returns unequipped item or null if slot empty or inventory full
	if not equipment.has(slot_name):
		_logger.log_error("unequip() called with invalid slot: " + slot_name)
		return null
	
	var item: EquipmentData = equipment[slot_name]
	if item == null:
		_logger.log("  Slot " + slot_name + " is already empty")
		return null
	
	_logger.log("Unequipping: " + item.display_name + " from " + slot_name)
	
	# Try to add to inventory
	var leftover: int = add_item(item, 1)
	if leftover > 0:
		# Inventory full, can't unequip
		_logger.log_error("  Failed to unequip (inventory full)")
		return null
	
	# Remove from equipment slot
	equipment[slot_name] = null
	_logger.log("  ✓ Unequipped " + item.display_name)
	equipment_changed.emit(slot_name)
	return item


func get_equipped(slot_name: String) -> EquipmentData:
	if not equipment.has(slot_name):
		return null
	return equipment[slot_name]


func get_total_stat_bonus(stat_name: String) -> int:
	# Returns sum of stat bonuses from all equipped items
	# stat_name: StatConstants.STAT_RESILIENCE, STAT_AGILITY, STAT_INT, or STAT_VIT (also supports "str"/"dex" for backwards compat)
	var total: int = 0
	
	for slot_name in equipment:
		var item: EquipmentData = equipment[slot_name]
		if item != null:
			match stat_name:
				StatConstants.STAT_RESILIENCE, "str":  # Support both for backwards compatibility
					total += item.resilience_bonus
				StatConstants.STAT_AGILITY, "dex":  # Support both for backwards compatibility
					total += item.agility_bonus
				StatConstants.STAT_INT:
					total += item.int_bonus
				StatConstants.STAT_VIT:
					total += item.vit_bonus
	
	return total


func get_total_damage_bonus() -> int:
	"""Returns sum of flat damage bonuses from all equipped items."""
	var total: int = 0
	for slot_name in equipment:
		var item: EquipmentData = equipment[slot_name]
		if item != null:
			total += item.flat_damage_bonus
	return total


func get_total_damage_percentage() -> float:
	"""Returns sum of percentage damage bonuses from all equipped items."""
	var total: float = 0.0
	for slot_name in equipment:
		var item: EquipmentData = equipment[slot_name]
		if item != null:
			total += item.damage_percentage_bonus
	return total
