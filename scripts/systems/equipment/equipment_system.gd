extends Node
## Global equipment system (autoload singleton).
## Manages equipment slots and equipping/unequipping logic.

# Logging
var _logger = GameLogger.create("[EquipmentSystem] ")

# Signals (LOCKED NAMES per SPEC.md)
signal equipment_changed(slot_name: String)

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
	_logger.log_info("EquipmentSystem initialized")
	_logger.log_info("  Equipment slots: " + str(equipment.keys()))


## Equips an item to the appropriate slot.
## 
## Args:
##   item: EquipmentData to equip
## 
## Returns: True if equipped successfully, false otherwise
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


## Unequips an item from a slot.
## 
## Args:
##   slot_name: Slot to unequip from
## 
## Returns: Unequipped item or null if slot empty or inventory full
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
	if InventorySystem != null:
		var leftover: int = InventorySystem.add_item(item, 1)
		if leftover > 0:
			# Inventory full, can't unequip
			_logger.log_error("  Failed to unequip (inventory full)")
			return null
	else:
		_logger.log_error("InventorySystem not available - cannot unequip")
		return null
	
	# Remove from equipment slot
	equipment[slot_name] = null
	_logger.log("  ✓ Unequipped " + item.display_name)
	equipment_changed.emit(slot_name)
	return item


## Gets equipped item from a slot.
## 
## Args:
##   slot_name: Slot to check
## 
## Returns: Equipped EquipmentData or null
func get_equipped(slot_name: String) -> EquipmentData:
	if not equipment.has(slot_name):
		return null
	return equipment[slot_name]


## Returns sum of stat bonuses from all equipped items.
## 
## Args:
##   stat_name: StatConstants.STAT_RESILIENCE, STAT_AGILITY, STAT_INT, or STAT_VIT
## 
## Returns: Total stat bonus from all equipped items
func get_total_stat_bonus(stat_name: String) -> int:
	return EquipmentStatCalculator.get_total_stat_bonus(equipment, stat_name)


## Returns sum of flat damage bonuses from all equipped items.
## 
## Returns: Total flat damage bonus
func get_total_damage_bonus() -> int:
	return EquipmentStatCalculator.get_total_damage_bonus(equipment)


## Returns sum of percentage damage bonuses from all equipped items.
## 
## Returns: Total percentage damage bonus (as float, e.g., 0.1 = 10%)
func get_total_damage_percentage() -> float:
	return EquipmentStatCalculator.get_total_damage_percentage(equipment)

