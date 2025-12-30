extends Node
class_name GoldVisuals
## Helper for mapping a gold amount to the correct coin icon/texture.
## Uses the labeled assets under res://resources/assets/gold_pieces/.

static func get_gold_icon_path(amount: int) -> String:
	# Clamp negatives to 0 for safety.
	var a: int = max(amount, 0)
	
	if a <= 1:
		return "res://resources/assets/gold_pieces/1_coin.png"
	elif a == 2:
		return "res://resources/assets/gold_pieces/2_coins.png"
	elif a == 3:
		return "res://resources/assets/gold_pieces/3_coins.png"
	elif a == 4:
		return "res://resources/assets/gold_pieces/4_coins.png"
	elif a == 5:
		return "res://resources/assets/gold_pieces/5_coins.png"
	elif a == 6:
		return "res://resources/assets/gold_pieces/6_coins.png"
	elif a >= 7 and a <= 9:
		return "res://resources/assets/gold_pieces/7-9_coins.png"
	elif a >= 10 and a <= 19:
		# No dedicated 10-19 icon; use the closest small pile.
		return "res://resources/assets/gold_pieces/7-9_coins.png"
	elif a >= 20 and a <= 49:
		return "res://resources/assets/gold_pieces/20-50_coins.png"
	elif a >= 50 and a <= 99:
		return "res://resources/assets/gold_pieces/50-99_coins.png"
	else:  # a >= 100
		return "res://resources/assets/gold_pieces/100+_coins.png"


static func load_gold_texture(amount: int) -> Texture2D:
	var path := get_gold_icon_path(amount)
	return load(path) as Texture2D


