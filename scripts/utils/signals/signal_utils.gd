extends RefCounted
class_name SignalUtils
## Utility class for safe signal connections

## Safely connects a signal, checking for duplicates and null.
## Use this instead of direct .connect() to prevent duplicate connections.
static func connect_safe(signal_obj: Signal, method: Callable, logger: GameLogger.GameLoggerInstance = null) -> void:
	if signal_obj == null:
		if logger != null:
			logger.log_error("Cannot connect signal - signal is null")
		else:
			push_error("SignalUtils.connect_safe: Cannot connect signal - signal is null")
		return
	if not signal_obj.is_connected(method):
		signal_obj.connect(method)

