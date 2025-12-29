extends Node
## Global currency system (autoload singleton).
## Manages player gold.

# Logging
var _logger = GameLogger.create("[CurrencySystem] ")

# Signals (LOCKED NAMES per SPEC.md)
signal gold_changed(amount: int)

# Current gold value
var gold: int = 0


func _ready() -> void:
	_logger.log_info("CurrencySystem initialized")
	_logger.log_info("Initial gold: " + str(gold))


## Adds gold to player.
## 
## Args:
##   amount: Amount of gold to add (must be >= 0)
func add_gold(amount: int) -> void:
	if amount < 0:
		_logger.log_error("add_gold() called with negative amount: " + str(amount))
		return
	gold += amount
	_logger.log("Gold added: +" + str(amount) + " (total: " + str(gold) + ")")
	gold_changed.emit(gold)


## Spends gold from player.
## 
## Args:
##   amount: Amount of gold to spend (must be >= 0)
## 
## Returns: True if gold was spent, false if insufficient gold
func spend_gold(amount: int) -> bool:
	if amount < 0:
		_logger.log_error("spend_gold() called with negative amount: " + str(amount))
		return false
	if not has_gold(amount):
		_logger.log("Failed to spend " + str(amount) + " gold (insufficient)")
		return false
	gold -= amount
	_logger.log("Gold spent: -" + str(amount) + " (total: " + str(gold) + ")")
	gold_changed.emit(gold)
	return true


## Checks if player has enough gold.
## 
## Args:
##   amount: Amount of gold to check
## 
## Returns: True if player has at least the specified amount
func has_gold(amount: int) -> bool:
	return gold >= amount

