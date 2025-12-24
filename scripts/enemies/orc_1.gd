extends BaseEnemy
class_name Orc1

## Orc enemy - melee fighter
## Just sets orc-specific stats, all behavior is in BaseEnemy


func _ready() -> void:
	# Orc-specific stats - TUNED FOR AGGRESSION
	max_health = 80
	move_speed = 70.0          # Slightly faster chase
	attack_damage = 15
	attack_range = 45.0        # Slightly longer reach
	detection_range = 200.0    # Notices player sooner
	attack_cooldown = 0.9      # Attacks more frequently
	hurt_duration = 0.2        # Recovers faster
	attack_hit_delay = 0.2     # Faster wind-up
	attack_hit_duration = 0.18 # Wider hit window
	
	# Call parent ready
	super._ready()
