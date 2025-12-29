extends RefCounted
class_name DamageCalculator
## Utility class for calculating damage with various modifiers.
## Handles base damage, level bonuses, equipment bonuses (flat + percentage).

## Calculates spell damage with all modifiers.
## Formula: (base + level_bonus + flat_bonus) * (1 + percentage_bonus)
## 
## Args:
##   base_damage: Base damage from spell/item
##   level: Element/stat level for level bonus calculation
##   level_bonus_per_level: Damage bonus per level (default: 5)
##   flat_bonus: Flat damage bonus from equipment (default: 0)
##   percentage_bonus: Percentage damage bonus from equipment (default: 0.0)
## 
## Returns: Final calculated damage
static func calculate_spell_damage(
	base_damage: int,
	level: int,
	level_bonus_per_level: int = 5,
	flat_bonus: int = 0,
	percentage_bonus: float = 0.0
) -> int:
	# Level bonus: (level - 1) * bonus_per_level
	var level_bonus: int = (level - 1) * level_bonus_per_level
	
	# Calculate: (base + level + flat) * (1 + percentage)
	var base_with_bonuses: int = base_damage + level_bonus + flat_bonus
	var total_damage: int = int(base_with_bonuses * (1.0 + percentage_bonus))
	
	return total_damage


## Calculates damage with flat and percentage bonuses only (no level bonus).
## Useful for non-spell damage sources.
## 
## Args:
##   base_damage: Base damage
##   flat_bonus: Flat damage bonus (default: 0)
##   percentage_bonus: Percentage damage bonus (default: 0.0)
## 
## Returns: Final calculated damage
static func calculate_damage_with_bonuses(
	base_damage: int,
	flat_bonus: int = 0,
	percentage_bonus: float = 0.0
) -> int:
	var base_with_bonuses: int = base_damage + flat_bonus
	var total_damage: int = int(base_with_bonuses * (1.0 + percentage_bonus))
	return total_damage

