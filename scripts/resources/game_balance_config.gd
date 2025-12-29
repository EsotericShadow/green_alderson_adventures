extends Resource
class_name GameBalanceConfig

## Configuration resource for game balance values.
## All magic numbers and tunable game parameters should be defined here.

# Movement
@export_group("Movement")
@export var walk_speed: float = 120.0
@export var run_speed: float = 220.0
@export var stamina_drain_rate: float = 20.0  # Stamina per second while running
@export var min_stamina_to_run: int = 5  # Minimum stamina required to run

# Regeneration
@export_group("Regeneration")
@export var base_mana_regen: float = 5.0  # Base mana per second
@export var base_stamina_regen: float = 3.0  # Base stamina per second
@export var base_health_regen: float = 0.5  # Base health per second

# Stat Formulas
@export_group("Stat Formulas")
@export var health_per_vit: int = 20
@export var mana_per_int: int = 15
@export var stamina_per_agility: int = 10

# XP and Leveling
@export_group("XP & Leveling")
@export var max_base_stat_level: int = 110
@export var max_element_level: int = 110
@export var vitality_xp_ratio: int = 8  # 1 VIT XP per N XP in other stats

# Heavy Carry (MovementTracker)
@export_group("Heavy Carry")
@export var heavy_carry_threshold: float = 0.90  # 90% weight for XP gain
@export var heavy_carry_xp_per_meter: float = 0.1  # XP per meter moved

# Combat
@export_group("Combat")
@export var spell_cast_delay_ratio: float = 0.583  # Cast delay ratio (0.35 / 0.6) for spell spawn timing
@export var spell_xp_damage_ratio: float = 2.0  # XP gain = damage / this ratio (half damage = XP)

