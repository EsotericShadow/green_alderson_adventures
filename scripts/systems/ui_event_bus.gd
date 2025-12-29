extends Node
## UI Event Bus - handles all UI-related signals (inventory, crafting, merchant, pause menu).

# Logging
var _logger = GameLogger.create("[UIEventBus] ")

# UI Signals (LOCKED NAMES per SPEC.md)
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


func _ready() -> void:
	_logger.log("UIEventBus initialized")

