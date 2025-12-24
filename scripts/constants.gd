extends Node

# Fireball Configuration
class_name FireballConfig

const DEFAULT_SPEED: float = 450.0
const DEFAULT_LIFETIME: float = 1.5
const DEFAULT_COOLDOWN: float = 0.8
const CAST_DELAY: float = 0.5

# Collision Layers
const COLLISION_LAYER_TERRAIN: int = 1
const COLLISION_LAYER_PROJECTILE: int = 2

# Groups
const GROUP_FIREBALL: StringName = "fireball"
const GROUP_PLAYER: StringName = "player"

