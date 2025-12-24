extends Control
## Health bar component using AnimatedSprite2D with 8 frames
## Frame 0 = full health, Frame 7 = empty health

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const TOTAL_FRAMES: int = 8  # 0-7 frames in health_depletion animation


func _ready() -> void:
	# Connect to PlayerStats health changes
	PlayerStats.health_changed.connect(_on_health_changed)
	# Set initial frame based on current health
	_update_frame()


func _on_health_changed(_current: int, _maximum: int) -> void:
	_update_frame()


func _update_frame() -> void:
	if animated_sprite == null:
		return
	
	var max_health: int = PlayerStats.get_max_health()
	var current_health: int = PlayerStats.health
	
	if max_health <= 0:
		animated_sprite.frame = TOTAL_FRAMES - 1  # Show empty (frame 7)
		return
	
	# Calculate health percentage (0.0 to 1.0)
	var health_percent: float = float(current_health) / float(max_health)
	
	# Map percentage to frame (0 = full, 7 = empty)
	# We want: 100% = frame 0, 0% = frame 7
	# Formula: frame = (1.0 - health_percent) * (TOTAL_FRAMES - 1)
	var frame_index: int = int((1.0 - health_percent) * (TOTAL_FRAMES - 1))
	frame_index = clampi(frame_index, 0, TOTAL_FRAMES - 1)
	
	# Set the frame directly (don't play animation, just show the correct frame)
	animated_sprite.frame = frame_index
