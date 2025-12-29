extends RefCounted
class_name DirectionUtils
## Utility class for direction conversions between Vector2 and direction strings.
## Supports both 4-directional and 8-directional systems.

## Converts a Vector2 to an 8-directional string.
## Returns: "up", "down", "left", "right", "ne", "nw", "se", "sw"
## 
## Args:
##   v: Input vector (will be normalized)
##   fallback: Direction to return if vector is too small (default: "down")
## 
## Returns: Direction string
static func vector_to_dir8(v: Vector2, fallback: String = "down") -> String:
	if v.length() < 0.1:
		return fallback
	
	var deg := rad_to_deg(atan2(v.y, v.x))
	deg = fposmod(deg + 22.5, 360.0)
	
	if deg < 45.0: return "right"
	elif deg < 90.0: return "se"
	elif deg < 135.0: return "down"
	elif deg < 180.0: return "sw"
	elif deg < 225.0: return "left"
	elif deg < 270.0: return "nw"
	elif deg < 315.0: return "up"
	else: return "ne"


## Converts a Vector2 to a 4-directional string.
## Returns: "up", "down", "left", "right"
## 
## Args:
##   v: Input vector (will be normalized)
##   fallback: Direction to return if vector is too small (default: "down")
## 
## Returns: Direction string
static func vector_to_dir4(v: Vector2, fallback: String = "down") -> String:
	if v.length() < 0.1:
		return fallback
	
	var deg := rad_to_deg(atan2(v.y, v.x))
	deg = fposmod(deg + 45.0, 360.0)
	
	if deg < 90.0: return "right"
	elif deg < 180.0: return "down"
	elif deg < 270.0: return "left"
	else: return "up"


## Converts a direction string to a normalized Vector2.
## Supports both 4 and 8-directional strings.
## 
## Args:
##   d: Direction string ("up", "down", "left", "right", "ne", "nw", "se", "sw")
## 
## Returns: Normalized Vector2 (defaults to Vector2.DOWN if invalid)
static func dir_to_vector(d: String) -> Vector2:
	match d:
		"right": return Vector2.RIGHT
		"left": return Vector2.LEFT
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"ne": return Vector2(1, -1).normalized()
		"nw": return Vector2(-1, -1).normalized()
		"se": return Vector2(1, 1).normalized()
		"sw": return Vector2(-1, 1).normalized()
		_: return Vector2.DOWN


## Converts an 8-directional string to a 4-directional string.
## Useful for fallback when 8-dir animations aren't available.
## 
## Args:
##   dir8: 8-directional string ("up", "down", "left", "right", "ne", "nw", "se", "sw")
## 
## Returns: 4-directional string (defaults to "down" if invalid)
static func dir8_to_dir4(dir8: String) -> String:
	match dir8:
		"up", "ne", "nw": return "up"
		"down", "se", "sw": return "down"
		"left": return "left"
		"right": return "right"
		_: return "down"


## Checks if a direction string is valid (4 or 8-directional).
## 
## Args:
##   dir: Direction string to validate
## 
## Returns: true if valid, false otherwise
static func is_valid_direction(dir: String) -> bool:
	match dir:
		"up", "down", "left", "right", "ne", "nw", "se", "sw":
			return true
		_:
			return false


## Checks if a direction is facing north (up, ne, nw).
## 
## Args:
##   dir: Direction string
## 
## Returns: true if facing north
static func is_facing_north(dir: String) -> bool:
	return dir == "up" or dir == "ne" or dir == "nw"

