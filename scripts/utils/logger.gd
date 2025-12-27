extends RefCounted
class_name GameLogger
## Centralized logging utility for consistent logging across the codebase.
## Supports prefix-based logging with optional error handling.

## Logs a message with a prefix.
## 
## Args:
##   prefix: Log prefix (e.g., "[PLAYER] ", "[ENEMY] ")
##   message: Message to log
static func log(prefix: String, message: String) -> void:
	print(prefix + message)


## Logs an error message with a prefix.
## Also calls push_error() for Godot's error system.
## 
## Args:
##   prefix: Log prefix (e.g., "[PLAYER] ", "[ENEMY] ")
##   message: Error message to log
static func log_error(prefix: String, message: String) -> void:
	var full_message: String = prefix + "ERROR: " + message
	push_error(full_message)
	print(full_message)


## Creates a logger instance for a specific context.
## Useful for classes that want to maintain their own prefix.
## 
## Example:
##   var logger = GameLogger.create("[PLAYER] ")
##   logger.log("Player spawned")
##   logger.log_error("Failed to load")
class GameLoggerInstance:
	var prefix: String
	
	func _init(p: String) -> void:
		prefix = p
	
	func log(message: String) -> void:
		GameLogger.log(prefix, message)
	
	func log_error(message: String) -> void:
		GameLogger.log_error(prefix, message)


## Creates a logger instance with a specific prefix.
## 
## Args:
##   prefix: Log prefix (e.g., "[PLAYER] ", "[ENEMY] ")
## 
## Returns: GameLoggerInstance for convenient logging
static func create(prefix: String) -> GameLoggerInstance:
	return GameLoggerInstance.new(prefix)
