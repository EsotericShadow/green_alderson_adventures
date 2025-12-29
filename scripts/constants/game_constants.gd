extends RefCounted
class_name GameConstants
## Non-balance game constants (technical/visual/animation values).
## Balance-related constants should be in GameBalanceConfig.

# Screen shake
const SCREEN_SHAKE_RATE: int = 30  # Shakes per second

# Collision Layers
const COLLISION_LAYER_TERRAIN: int = 1
const COLLISION_LAYER_PROJECTILE: int = 2
const COLLISION_LAYER_HITBOX: int = 4
const COLLISION_LAYER_HURTBOX: int = 8

# Groups
const GROUP_PLAYER: StringName = "player"
const GROUP_ENEMY: StringName = "enemy"
const GROUP_FIREBALL: StringName = "fireball"  # Legacy, but still used in spell_projectile.gd

