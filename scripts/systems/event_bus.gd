extends Node
## Central signal hub for decoupled communication between game systems.
## All UI and game events are broadcast through this singleton.

# UI Signals (LOCKED NAMES per SPEC.md)
# These signals are declared for future use - warnings suppressed
@warning_ignore("unused_signal")
signal inventory_opened
@warning_ignore("unused_signal")
signal inventory_closed
@warning_ignore("unused_signal")
signal crafting_opened
@warning_ignore("unused_signal")
signal crafting_closed
@warning_ignore("unused_signal")
signal merchant_opened(merchant_data: MerchantData)
@warning_ignore("unused_signal")
signal merchant_closed
@warning_ignore("unused_signal")
signal pause_menu_opened
@warning_ignore("unused_signal")
signal pause_menu_closed

# Game Events (LOCKED NAMES per SPEC.md)
# These signals are declared for future use - warnings suppressed
@warning_ignore("unused_signal")
signal item_picked_up(item: ItemData, count: int)
@warning_ignore("unused_signal")
signal item_used(item: ItemData)
@warning_ignore("unused_signal")
signal chest_opened(chest_position: Vector2)
@warning_ignore("unused_signal")
signal enemy_killed(enemy_name: String, position: Vector2)
@warning_ignore("unused_signal")
signal spell_cast(spell: SpellData)
@warning_ignore("unused_signal")
signal level_up(element: String, new_level: int)
