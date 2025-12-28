extends RefCounted
## Base Stat Constants (replaces magic strings)
## Centralized constants for base stat names to improve type safety and maintainability

class_name StatConstants

# Base stat name constants
const STAT_RESILIENCE: String = "resilience"
const STAT_AGILITY: String = "agility"
const STAT_INT: String = "int"
const STAT_VIT: String = "vit"

# Array of all base stats (for iteration)
const BASE_STATS: Array[String] = [STAT_RESILIENCE, STAT_AGILITY, STAT_INT, STAT_VIT]

# Display names for UI
const BASE_STAT_DISPLAY_NAMES: Dictionary = {
	STAT_RESILIENCE: "Resilience",
	STAT_AGILITY: "Agility",
	STAT_INT: "INT",
	STAT_VIT: "VIT"
}

