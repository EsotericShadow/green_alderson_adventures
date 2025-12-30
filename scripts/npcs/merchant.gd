extends CharacterBody2D
## Merchant NPC that opens shop UI when player interacts.

# Logging
var _logger = GameLogger.create("[Merchant] ")

@export var merchant_data: MerchantData

var player_in_range: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_logger.log("Merchant initialized at " + str(global_position))
	
	# Validate merchant_data
	if merchant_data == null:
		_logger.log_error("merchant_data is null!")
		return
	
	# Connect interaction area signals
	if interaction_area == null:
		_logger.log_error("InteractionArea is null!")
		return
	
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)


func _input(event: InputEvent) -> void:
	# Check for interact action when player is in range
	if event.is_action_pressed("interact") and player_in_range:
		open_shop()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		player_in_range = true
		_logger.log("Player entered merchant range")


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		player_in_range = false
		_logger.log("Player left merchant range")


func open_shop() -> void:
	if merchant_data == null:
		_logger.log_error("Cannot open shop - merchant_data is null")
		return
	
	_logger.log("Opening shop: " + merchant_data.display_name)
	
	if EventBus != null:
		EventBus.merchant_opened.emit(merchant_data)
	else:
		_logger.log_error("EventBus is null, cannot open shop")

