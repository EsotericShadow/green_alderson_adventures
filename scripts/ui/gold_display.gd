extends HBoxContainer
## Gold display component for HUD.
## Shows current gold amount with dynamic icon based on gold value.

# Logging
var _logger = GameLogger.create("[GoldDisplay] ")

@onready var coin_icon: TextureRect = $CoinIcon
@onready var gold_label: Label = $GoldLabel


func _ready() -> void:
	_logger.log("GoldDisplay initialized")
	
	# Check if nodes exist
	if coin_icon == null:
		_logger.log_error("coin_icon is null!")
		return
	if gold_label == null:
		_logger.log_error("gold_label is null!")
		return
	
	# Connect to PlayerStats gold_changed signal
	if PlayerStats == null:
		_logger.log_error("PlayerStats is null, cannot display gold")
		return
	
	PlayerStats.gold_changed.connect(_on_gold_changed)
	
	# Initialize display with current gold
	_on_gold_changed(PlayerStats.gold)


func _on_gold_changed(amount: int) -> void:
	_update_icon(amount)
	_update_label(amount)


func _update_icon(amount: int) -> void:
	var icon_path: String = get_gold_icon_path(amount)
	var texture: Texture2D = load(icon_path)
	if texture == null:
		_logger.log_error("Failed to load gold icon: " + icon_path)
		return
	
	if coin_icon != null:
		coin_icon.texture = texture


func _update_label(amount: int) -> void:
	if gold_label != null:
		gold_label.text = str(amount)


## Returns the appropriate gold icon path based on gold amount.
## Logic from GOLD_ICONS_GUIDE.md
func get_gold_icon_path(amount: int) -> String:
	if amount <= 1:
		return "res://resources/assets/gold_pieces/1_coin.png"
	elif amount == 2:
		return "res://resources/assets/gold_pieces/2_coins.png"
	elif amount == 3:
		return "res://resources/assets/gold_pieces/3_coins.png"
	elif amount == 4:
		return "res://resources/assets/gold_pieces/4_coins.png"
	elif amount == 5:
		return "res://resources/assets/gold_pieces/5_coins.png"
	elif amount == 6:
		return "res://resources/assets/gold_pieces/6_coins.png"
	elif amount >= 7 and amount <= 9:
		return "res://resources/assets/gold_pieces/7-9_coins.png"
	elif amount >= 10 and amount <= 19:
		# Gap handling: use 7-9 icon as fallback
		return "res://resources/assets/gold_pieces/7-9_coins.png"
	elif amount >= 20 and amount <= 49:
		return "res://resources/assets/gold_pieces/20-50_coins.png"
	elif amount >= 50 and amount <= 99:
		return "res://resources/assets/gold_pieces/50-99_coins.png"
	else:  # amount >= 100
		return "res://resources/assets/gold_pieces/100+_coins.png"

