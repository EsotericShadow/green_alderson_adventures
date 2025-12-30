extends RefCounted
class_name SpellDamageCalculator
## Utility class for calculating spell damage with element buffs.
## Wraps DamageCalculator and adds element multiplier support.

## Calculates spell damage: base + level bonus + equipment modifiers + element buffs.
## 
## Args:
##   spell: SpellData to calculate damage for
##   element_level: Current element level
##   level_bonus_per_level: Damage bonus per level (default 5)
##   flat_bonus: Flat damage bonus from equipment
##   percentage_bonus: Percentage damage bonus from equipment (0.1 = 10%)
##   element_multiplier: Element damage multiplier from buffs (default 1.0)
## 
## Returns: Total spell damage
static func calculate_spell_damage(
	spell: SpellData,
	element_level: int,
	level_bonus_per_level: int = 5,
	flat_bonus: int = 0,
	percentage_bonus: float = 0.0,
	element_multiplier: float = 1.0
) -> int:
	if spell == null:
		return 0
	
	# Use DamageCalculator for base calculation
	var base_damage: int = DamageCalculator.calculate_spell_damage(
		spell.base_damage,
		element_level,
		level_bonus_per_level,
		flat_bonus,
		percentage_bonus
	)
	
	# Apply element damage multiplier (from buffs)
	var final_damage: int = int(base_damage * element_multiplier)
	
	return final_damage

