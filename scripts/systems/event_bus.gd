extends Node
## Central signal hub for decoupled communication between game systems.
## All UI and game events are broadcast through this singleton.

# UI Signals (LOCKED NAMES per SPEC.md)
signal inventory_opened
signal inventory_closed
signal crafting_opened
signal crafting_closed
signal merchant_opened(merchant_data: MerchantData)
signal merchant_closed
signal pause_menu_opened
signal pause_menu_closed

# Game Events (LOCKED NAMES per SPEC.md)
signal item_picked_up(item: ItemData, count: int)
signal item_used(item: ItemData)
signal chest_opened(chest_position: Vector2)
signal enemy_killed(enemy_name: String, position: Vector2)
signal spell_cast(spell: SpellData)
signal level_up(element: String, new_level: int)

