extends RefCounted
class_name StatCalculator
## Utility class for calculating total stats (base stat + equipment bonuses).
## Breaks circular dependencies by taking equipment dictionary as parameter.
## Uses EquipmentStatCalculator internally.

## Calculates total stat value (base stat + equipment bonuses).
## 
## Args:
##   base_stat: Base stat value (from XPLevelingSystem)
##   equipment: Dictionary of equipped items (from InventorySystem.get_all_equipped())
##   stat_name: Stat constant (StatConstants.STAT_RESILIENCE, STAT_AGILITY, STAT_INT, STAT_VIT)
## 
## Returns: Total stat value (base + equipment bonus)
static func calculate_total_stat(base_stat: int, equipment: Dictionary, stat_name: String) -> int:
	var bonus: int = EquipmentStatCalculator.get_total_stat_bonus(equipment, stat_name)
	return base_stat + bonus

