class_name ItemData
extends Resource
## Base class for all items in the game.
## Defines common properties like name, description, icon, and stacking behavior.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var stackable: bool = true
@export var max_stack: int = 99
@export_enum("consumable", "equipment", "material", "key") var item_type: String = "material"
@export var weight: float = 0.0  # Weight in kg for carry weight system

