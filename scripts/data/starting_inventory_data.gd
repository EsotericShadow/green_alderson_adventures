class_name StartingInventoryData
extends Resource
## Data resource for defining starting inventory items.
## Used to configure initial player inventory without hardcoding in scripts.

@export var items: Array[Dictionary] = []
## Array of dictionaries with format: { "item_id": String, "count": int }
## Example: { "item_id": "stonebloom", "count": 5 }

