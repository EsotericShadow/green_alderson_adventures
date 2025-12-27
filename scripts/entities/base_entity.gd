extends CharacterBody2D
class_name BaseEntity
## Base class for all entities (player, enemy, NPC).
## Provides common functionality and prepares for network synchronization.

signal entity_died(entity: BaseEntity)
signal entity_state_changed(entity: BaseEntity)

# Entity data (serializable state)
var entity_data: EntityData = EntityData.new()

# Network ID (for multiplayer)
var network_id: int = -1  # -1 = local only

# Authority (who controls this entity)
enum Authority { LOCAL, SERVER, CLIENT }
var authority: Authority = Authority.LOCAL

# Worker references (common to all entities)
var mover: Mover = null
var animator: Animator = null
var health_tracker: HealthTracker = null
var hurtbox: Hurtbox = null

# Logging
var _logger: GameLogger.GameLoggerInstance


func _ready() -> void:
	_logger = GameLogger.create("[" + name + "/Entity] ")
	entity_data.entity_id = _generate_entity_id()
	entity_data.entity_type = _get_entity_type()
	_setup_workers()


func _generate_entity_id() -> String:
	# Generate unique ID (UUID format)
	# In multiplayer, server will assign network IDs
	return str(get_instance_id()) + "_" + str(Time.get_ticks_msec())


func _get_entity_type() -> String:
	# Override in subclasses
	return "unknown"


func _setup_workers() -> void:
	# Override in subclasses to set up worker references
	pass


## Gets serializable entity data.
func get_entity_data() -> EntityData:
	entity_data.position = global_position
	return entity_data


## Loads entity data (for deserialization/network sync).
func load_entity_data(data: EntityData) -> void:
	entity_data = data
	global_position = data.position
	# Subclasses should handle other state loading


## Converts entity to dictionary for serialization.
func to_dict() -> Dictionary:
	return entity_data.to_dict()


## Loads entity from dictionary.
func from_dict(data: Dictionary) -> void:
	entity_data.from_dict(data)
	load_entity_data(entity_data)


## Checks if this entity is controlled by server.
func is_server_authority() -> bool:
	return authority == Authority.SERVER


## Checks if this entity is controlled by local client.
func is_local_authority() -> bool:
	return authority == Authority.LOCAL


func _log(msg: String) -> void:
	_logger.log(msg)


func _log_error(msg: String) -> void:
	_logger.log_error(msg)

