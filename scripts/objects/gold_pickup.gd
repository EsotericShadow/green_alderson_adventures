extends Area2D
## World pickup for gold.
## Uses the coin pile sprites (amount-based) and adds gold to CurrencySystem on pickup.

var _logger = GameLogger.create("[GoldPickup] ")

@export var amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if amount < 1:
		amount = 1
	
	_refresh_visuals()
	body_entered.connect(_on_body_entered)
	
	# Ensure it renders above most world sprites
	z_index = 5


func _refresh_visuals() -> void:
	if sprite == null:
		return
	
	var tex: Texture2D = GoldVisuals.load_gold_texture(amount)
	if tex == null:
		_logger.log_warning("Failed to load gold texture for amount: " + str(amount))
		return
	sprite.texture = tex


func _on_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group(GameConstants.GROUP_PLAYER):
		return
	
	if CurrencySystem == null:
		_logger.log_error("CurrencySystem is null, cannot pick up gold")
		return
	
	var previous_total: int = CurrencySystem.gold if CurrencySystem != null else (PlayerStats.gold if PlayerStats != null else 0)
	CurrencySystem.add_gold(amount)
	var current_total: int = CurrencySystem.gold if CurrencySystem != null else (PlayerStats.gold if PlayerStats != null else previous_total)
	var added: int = clampi(current_total - previous_total, 0, amount)
	var leftover: int = amount - added

	if added > 0 and EventBus != null:
		var gold_item: ItemData = ResourceManager.load_item("gold_coins") if ResourceManager != null else null
		EventBus.item_picked_up.emit(gold_item, added)

	if leftover > 0:
		amount = leftover
		_refresh_visuals()
		return

	queue_free()

