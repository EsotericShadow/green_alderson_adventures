extends RefCounted
## Character level calculator
## Combines base stats (Resilience, Agility, Intelligence, Vitality) and magic elements (Fire, Water, Earth, Air)
## Uses a weighted average approach where each stat contributes to overall character level

class_name CharacterLevel

## Calculate character level based on all stats
## Formula: Average of all 8 skills (4 base stats + 4 elements), with some weighting
## This gives a balanced character level that reflects overall progression
static func calculate_character_level(
	resilience: int,
	agility: int,
	intelligence: int,
	vitality: int,
	fire_level: int,
	water_level: int,
	earth_level: int,
	air_level: int
) -> Dictionary:
	# Sum all skill levels (base stats + elements)
	var total_levels: int = resilience + agility + intelligence + vitality + fire_level + water_level + earth_level + air_level
	
	# Character level is the average of all 8 skills
	# This gives a balanced representation of overall character power
	var character_level: float = float(total_levels) / 8.0
	
	# Round to nearest integer (or floor - player's choice, but round makes more sense)
	var character_level_int: int = int(round(character_level))
	
	# For next level calculation, we need to know how much total levels are needed
	var current_total: int = total_levels
	var target_total_for_next: int = (character_level_int + 1) * 8
	var levels_needed_for_next: int = target_total_for_next - current_total
	
	return {
		"character_level": character_level_int,
		"total_skill_levels": total_levels,
		"average_skill_level": character_level,
		"levels_needed_for_next": levels_needed_for_next
	}


## Get character level only (simpler interface)
static func get_character_level(
	resilience: int,
	agility: int,
	intelligence: int,
	vitality: int,
	fire_level: int,
	water_level: int,
	earth_level: int,
	air_level: int
) -> int:
	var result: Dictionary = calculate_character_level(
		resilience, agility, intelligence, vitality,
		fire_level, water_level, earth_level, air_level
	)
	return result["character_level"]


