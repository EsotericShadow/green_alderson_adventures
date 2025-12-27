class_name SpellData
extends Resource
## Defines a spell's properties including element, damage, cost, and visual hue.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export_enum("fire", "water", "earth", "air") var element: String = "fire"
@export var base_damage: int = 10
@export var mana_cost: int = 10
@export var cooldown: float = 0.5
@export var hue_shift: float = 0.0
@export var projectile_speed: float = 300.0
@export var unlock_level: int = 1  # Element level required to unlock this spell

