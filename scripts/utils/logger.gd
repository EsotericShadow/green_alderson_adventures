extends RefCounted
class_name GameLogger
## Centralized logging utility for consistent logging across the codebase.
## Supports prefix-based logging with log levels (DEBUG, INFO, WARNING, ERROR).

## Log levels (in order of severity)
enum LogLevel {
	DEBUG = 0,    # Verbose debug information
	INFO = 1,     # Normal operational messages
	WARNING = 2,  # Warning messages (non-fatal issues)
	ERROR = 3     # Error messages (fatal issues)
}

## Global log level setting - messages below this level will be filtered
static var current_log_level: LogLevel = LogLevel.INFO

## Sets the global log level (filters messages below this level).
## 
## Args:
##   level: Minimum log level to display (DEBUG shows all, ERROR shows only errors)
static func set_log_level(level: LogLevel) -> void:
	current_log_level = level
	print("[GameLogger] Log level set to: " + LogLevel.keys()[level])


## Logs a message with a prefix and log level.
## 
## Args:
##   prefix: Log prefix (e.g., "[PLAYER] ", "[ENEMY] ")
##   message: Message to log
##   level: Log level (defaults to INFO)
static func log(prefix: String, message: String, level: LogLevel = LogLevel.INFO) -> void:
	# Filter by log level
	if level < current_log_level:
		return
	
	var level_prefix: String = ""
	match level:
		LogLevel.DEBUG:
			level_prefix = "[DEBUG] "
		LogLevel.INFO:
			level_prefix = ""  # INFO is the default, no prefix
		LogLevel.WARNING:
			level_prefix = "[WARNING] "
		LogLevel.ERROR:
			level_prefix = "[ERROR] "
	
	print(prefix + level_prefix + message)


## Logs a debug message (verbose debugging information).
static func log_debug(prefix: String, message: String) -> void:
	GameLogger.log(prefix, message, LogLevel.DEBUG)


## Logs an info message (normal operational messages).
static func log_info(prefix: String, message: String) -> void:
	GameLogger.log(prefix, message, LogLevel.INFO)


## Logs a warning message (non-fatal issues).
static func log_warning(prefix: String, message: String) -> void:
	GameLogger.log(prefix, message, LogLevel.WARNING)


## Logs an error message with a prefix.
## Also calls push_error() for Godot's error system.
## 
## Args:
##   prefix: Log prefix (e.g., "[PLAYER] ", "[ENEMY] ")
##   message: Error message to log
static func log_error(prefix: String, message: String) -> void:
	var full_message: String = prefix + "[ERROR] " + message
	push_error(full_message)
	GameLogger.log(prefix, message, LogLevel.ERROR)


## Creates a logger instance for a specific context.
## Useful for classes that want to maintain their own prefix.
## 
## Example:
##   var logger = GameLogger.create("[PLAYER] ")
##   logger.log_debug("Debug info")
##   logger.log_info("Player spawned")
##   logger.log_warning("Low health")
##   logger.log_error("Failed to load")
class GameLoggerInstance:
	var prefix: String
	
	func _init(p: String) -> void:
		prefix = p
	
	## Logs a message at INFO level (for backward compatibility).
	func log(message: String) -> void:
		GameLogger.log_info(prefix, message)
	
	## Logs a debug message (verbose debugging information).
	func log_debug(message: String) -> void:
		GameLogger.log_debug(prefix, message)
	
	## Logs an info message (normal operational messages).
	func log_info(message: String) -> void:
		GameLogger.log_info(prefix, message)
	
	## Logs a warning message (non-fatal issues).
	func log_warning(message: String) -> void:
		GameLogger.log_warning(prefix, message)
	
	## Logs an error message.
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
