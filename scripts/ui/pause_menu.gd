extends CanvasLayer
## Pause menu overlay.
## Pauses game and provides resume/settings/quit options.

# Logging
var _logger = GameLogger.create("[PauseMenu] ")

@onready var control: Control = $Control
@onready var resume_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/QuitButton


func _ready() -> void:
	_logger.log("PauseMenu initialized")
	
	# Connect buttons
	if resume_button != null:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button != null:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Start hidden
	if control != null:
		control.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var ui_visible: bool = control.visible if control != null else false
		if ui_visible:
			close()
		else:
			open()


func open() -> void:
	_logger.log("open() called")
	if control != null:
		control.visible = true
		get_tree().paused = true
		if EventBus != null:
			EventBus.pause_menu_opened.emit()
	else:
		_logger.log_error("control is null!")


func close() -> void:
	_logger.log("close() called")
	if control != null:
		control.visible = false
		get_tree().paused = false
		if EventBus != null:
			EventBus.pause_menu_closed.emit()
	else:
		_logger.log_error("control is null!")


func _on_resume_pressed() -> void:
	close()


func _on_settings_pressed() -> void:
	_logger.log("Settings button pressed (placeholder)")


func _on_quit_pressed() -> void:
	_logger.log("Quit button pressed")
	get_tree().quit()

