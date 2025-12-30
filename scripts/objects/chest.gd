extends Area2D
## Interactable chest that contains loot.
## Opens when player interacts while in range.

# Logging
var _logger = GameLogger.create("[Chest] ")

signal opened

@export var loot: Array[ItemData] = []
@export var loot_counts: Array[int] = []

var is_opened: bool = false
var player_in_range: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_logger.log("Chest initialized at " + str(global_position))
	
	# Validate loot arrays match
	if loot.size() != loot_counts.size():
		_logger.log_error("loot and loot_counts arrays do not match in size!")
	
	# Connect body entered/exited signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Start with closed animation
	if sprite != null:
		sprite.play("closed")


func _input(event: InputEvent) -> void:
	# Check for interact action when player is in range
	if event.is_action_pressed("interact") and player_in_range and not is_opened:
		open()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		player_in_range = true
		_logger.log("Player entered chest range")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		player_in_range = false
		_logger.log("Player left chest range")


func open() -> void:
	if is_opened:
		_logger.log("Chest already opened")
		return
	
	is_opened = true
	_logger.log("Opening chest...")
	
	# Play opening animation
	_play_open_animation()
	
	# Transfer loot to inventory
	_transfer_loot()
	
	# Emit signals
	opened.emit()
	EventBus.chest_opened.emit(global_position)


func _transfer_loot() -> void:
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null, cannot transfer loot")
		return
	
	# Validate arrays match
	if loot.size() != loot_counts.size():
		_logger.log_error("loot and loot_counts arrays do not match, skipping transfer")
		return
	
	# Transfer each item
	for i in range(loot.size()):
		var item: ItemData = loot[i]
		var count: int = loot_counts[i]
		
		if item == null:
			_logger.log_error("Null item at index " + str(i) + ", skipping")
			continue
		
		if count <= 0:
			_logger.log_error("Invalid count (" + str(count) + ") at index " + str(i) + ", skipping")
			continue
		
		# Add item to inventory
		var leftover: int = InventorySystem.add_item(item, count)
		if leftover > 0:
			_logger.log_warning("Inventory full: " + str(leftover) + "x " + item.display_name + " could not be added")
		else:
			_logger.log("Transferred " + str(count) + "x " + item.display_name + " to inventory")


func _play_open_animation() -> void:
	if sprite != null:
		sprite.play("opening")
		# After opening animation, switch to open state
		await sprite.animation_finished
		sprite.play("open")
	else:
		_logger.log_warning("AnimatedSprite2D is null, cannot play opening animation")

