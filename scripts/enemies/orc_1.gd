extends BaseEnemy
class_name Orc1

## ⚠️⚠️⚠️ LOCKED COMBAT VALUES - DO NOT ALTER ⚠️⚠️⚠️
##
## These values have been carefully tuned to work with the locked combat logic in BaseEnemy.
## The combination of these values prevents:
## - Lock-on spam attacks
## - Unavoidable damage chains
## - Player being unable to escape
##
## CRITICAL VALUES (DO NOT CHANGE):
## - separation_distance: 30.0 (must be >= 25.0, prevents getting too close)
## - post_attack_backoff_time: 0.4 (must be >= 0.3, prevents spam attacks)
## - attack_cooldown: 1.1 (works with backoff to prevent rapid attacks)
##
## If you need to adjust difficulty, consider:
## - attack_damage (how much damage per hit)
## - max_health (how many hits to kill)
## - move_speed (how fast it chases)
## DO NOT modify the anti-spam values above without extensive testing!
##
## Orc enemy - melee fighter
## Just sets orc-specific stats, all behavior is in BaseEnemy


func _ready() -> void:
	# ⚠️ LOCKED: Orc-specific stats - TUNED FOR BALANCED COMBAT (prevents spam, allows engagement)
	max_health = 80
	move_speed = 70.0          # Slightly faster chase
	attack_damage = 15
	attack_range = 45.0        # Slightly longer reach
	detection_range = 200.0    # Notices player sooner
	attack_cooldown = 1.1      # ⚠️ LOCKED: Reasonable cooldown to prevent spam (was 0.9) - DO NOT REDUCE BELOW 1.0
	hurt_duration = 0.2        # Recovers faster
	attack_hit_delay = 0.2     # Faster wind-up
	attack_hit_duration = 0.18 # Wider hit window
	separation_distance = 30.0  # ⚠️ LOCKED: Maintain minimum distance (prevents getting too close) - DO NOT REDUCE BELOW 30
	post_attack_backoff_time = 1.0  # ⚠️ LOCKED: Pause after attack before can attack again (prevents spam) - DO NOT REDUCE BELOW 1.0
	
	# Call parent ready
	super._ready()
