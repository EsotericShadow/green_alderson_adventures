class_name RecipeData
extends Resource
## Defines a crafting recipe: ingredients required and result produced.
## ingredients and ingredient_counts arrays must be same size.

@export var id: String = ""
@export var display_name: String = ""
@export var result: ItemData = null
@export var result_count: int = 1
@export var ingredients: Array[ItemData] = []
@export var ingredient_counts: Array[int] = []

