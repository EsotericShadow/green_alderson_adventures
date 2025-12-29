extends RefCounted
class_name EquipmentStatCalculator
## Utility class for calculating stat bonuses and damage bonuses from equipment.
## Pure calculation functions with no state - takes equipment dictionary as parameter.

## Calculates total stat bonus from all equipped items.
## 
## Args:
##   equipment: Dictionary of equipped items (slot_name -> EquipmentData)
##   stat_name: Stat constant (StatConstants.STAT_RESILIENCE, STAT_AGILITY, STAT_INT, STAT_VIT)
## 
## Returns: Total stat bonus from all equipped items
static func get_total_stat_bonus(equipment: Dictionary, stat_name: String) -> int:
	var total: int = 0
	
	for slot_name in equipment:
		var item: EquipmentData = equipment.get(slot_name)
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


## Calculates total flat damage bonus from all equipped items.
## 
## Args:
##   equipment: Dictionary of equipped items (slot_name -> EquipmentData)
## 
## Returns: Total flat damage bonus
static func get_total_damage_bonus(equipment: Dictionary) -> int:
	var total: int = 0
	for slot_name in equipment:
		var item: EquipmentData = equipment.get(slot_name)
		if item != null:
			total += item.flat_damage_bonus
	return total


## Calculates total percentage damage bonus from all equipped items.
## 
## Args:
##   equipment: Dictionary of equipped items (slot_name -> EquipmentData)
## 
## Returns: Total percentage damage bonus (as float, e.g., 0.1 = 10%)
static func get_total_damage_percentage(equipment: Dictionary) -> float:
	var total: float = 0.0
	for slot_name in equipment:
		var item: EquipmentData = equipment.get(slot_name)
		if item != null:
			total += item.damage_percentage_bonus
	return total

