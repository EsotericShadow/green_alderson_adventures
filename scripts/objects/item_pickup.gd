extends Area2D
## Generic world pickup for an ItemData + count.

var _logger = GameLogger.create("[ItemPickup] ")

@export var item: ItemData = null
@export var count: int = 1

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if count < 1:
		count = 1
	
	_refresh_visuals()
	body_entered.connect(_on_body_entered)
	z_index = 5


func _refresh_visuals() -> void:
	if sprite == null or item == null:
		return
	sprite.texture = item.icon


func _on_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group(GameConstants.GROUP_PLAYER):
		return
	
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null, cannot pick up item")
		return
	
	var leftover: int = InventorySystem.add_item(item, count)
	var picked_up: int = count - leftover
	if picked_up <= 0:
		_logger.log_warning("Inventory full: could not pick up " + (item.display_name if item != null else "item"))
		return
	
	if EventBus != null:
		EventBus.item_picked_up.emit(item, picked_up)
	
	# If partially picked up, keep the pickup with remaining count.
	if leftover > 0:
		count = leftover
		_refresh_visuals()
		return
	
	queue_free()


