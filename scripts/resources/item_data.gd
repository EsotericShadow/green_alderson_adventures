class_name ItemData
extends Resource
## Placeholder stub class - inventory system not yet implemented
## TODO: Implement when milestone 4 (Crafting & Chests) is reached

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var stackable: bool = true
@export var max_stack: int = 99
@export_enum("consumable", "equipment", "material", "key") var item_type: String = "material"

