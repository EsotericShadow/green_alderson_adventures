extends RefCounted
## RuneScape-style XP formula calculator
## Formula: XP for level L = floor(sum from i=1 to L-1 of floor(i + 300 * 2^(i/7)) / 4)

class_name XPFormula

## Calculate total XP required to reach a given level using RuneScape formula
## Level 1 = 0 XP, Level 2 = 83 XP, Level 3 = 174 XP, etc.
static func get_xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	
	var total_xp: float = 0.0
	for i in range(1, level):
		var term: float = float(i) + 300.0 * pow(2.0, float(i) / 7.0)
		total_xp += floor(term)
	
	return int(floor(total_xp / 4.0))


## Calculate XP needed for the current level (minimum XP required)
## Returns the total XP required to be at this level
static func get_xp_for_current_level(level: int) -> int:
	return get_xp_for_level(level)


## Calculate XP needed to reach the next level
## Returns the total XP required to reach level+1
static func get_xp_for_next_level(level: int) -> int:
	return get_xp_for_level(level + 1)


## Calculate what level a player should be at given their total XP
## Returns the highest level where XP >= get_xp_for_level(level)
## Supports up to level 110 (max level for this game)
static func get_level_from_xp(total_xp: int) -> int:
	if total_xp < 0:
		return 1
	
	# Binary search for efficiency (check up to level 110)
	var min_level: int = 1
	var max_level: int = 110
	
	while min_level <= max_level:
		var mid_level: int = (min_level + max_level) >> 1  # Integer division using bit shift
		var xp_for_mid: int = get_xp_for_level(mid_level)
		
		if xp_for_mid <= total_xp:
			# Can be this level or higher
			var xp_for_next: int = get_xp_for_level(mid_level + 1)
			if xp_for_next > total_xp:
				return mid_level
			min_level = mid_level + 1
		else:
			# Too high, search lower
			max_level = mid_level - 1
	
	# If we get here, XP exceeds max level
	return max_level


## Get XP difference between two levels (XP needed to go from level1 to level2)
static func get_xp_difference(level1: int, level2: int) -> int:
	if level2 <= level1:
		return 0
	var xp1: int = get_xp_for_level(level1)
	var xp2: int = get_xp_for_level(level2)
	return xp2 - xp1
