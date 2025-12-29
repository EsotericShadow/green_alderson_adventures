extends Area2D
class_name BaseAreaWorker

## Base class for Area2D-based worker nodes.
## Provides consistent interface and initialization pattern similar to BaseWorker.

# Logging
var _logger: GameLogger.GameLoggerInstance

# Owner reference (the coordinator that owns this worker)
var owner_node: Node2D = null

# Signals
signal initialized
signal cleanup_requested

# State
var _is_initialized: bool = false


func _ready() -> void:
	# Create logger with parent name
	_logger = GameLogger.create("[" + get_parent().name + "/" + get_script().get_path().get_file().get_basename() + "] ")
	# Initialize worker
	_initialize()


func _initialize() -> void:
	"""Initializes the worker. Override in subclasses for custom initialization."""
	if _is_initialized:
		return
	
	owner_node = get_parent() as Node2D
	_on_initialize()
	_is_initialized = true
	initialized.emit()
	_logger.log_debug("Worker initialized")


func cleanup() -> void:
	"""Cleans up the worker. Override _on_cleanup() in subclasses."""
	if not _is_initialized:
		return
	_on_cleanup()
	cleanup_requested.emit()
	_is_initialized = false
	_logger.log_debug("Worker cleaned up")


# Virtual methods - override in subclasses

func _on_initialize() -> void:
	"""Called during initialization. Override for custom initialization logic."""
	pass


func _on_cleanup() -> void:
	"""Called during cleanup. Override for custom cleanup logic."""
	pass


# Utility methods

func is_initialized() -> bool:
	"""Returns true if the worker has been initialized."""
	return _is_initialized


func get_owner_node() -> Node2D:
	"""Returns the owner node (coordinator)."""
	return owner_node


func log(message: String) -> void:
	"""Convenience method for logging. Use _logger directly for more control."""
	if _logger != null:
		_logger.log(message)


func log_error(message: String) -> void:
	"""Convenience method for error logging."""
	if _logger != null:
		_logger.log_error(message)

