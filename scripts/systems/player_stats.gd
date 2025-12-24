extends Node
## Global player stats system (autoload singleton).
## Manages base stats (STR/DEX/INT/VIT), derived values (health/mana/stamina), and gold.

# Signals (LOCKED NAMES per SPEC.md)
signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal stamina_changed(current: int, maximum: int)
signal gold_changed(amount: int)
signal stat_changed(stat_name: String, new_value: int)
signal player_died

# Base Stats (LOCKED NAMES, LOCKED DEFAULTS per SPEC.md)
var base_str: int = 5
var base_dex: int = 5
var base_int: int = 5
var base_vit: int = 5

# Current Values (LOCKED NAMES per SPEC.md)
var health: int = 100
var mana: int = 75
var stamina: int = 50
var gold: int = 0

# Constants (LOCKED FORMULAS per SPEC.md)
const HEALTH_PER_VIT: int = 20
const MANA_PER_INT: int = 15
const STAMINA_PER_DEX: int = 10
const MANA_REGEN_RATE: float = 2.0  # Mana per second
const STAMINA_REGEN_RATE: float = 5.0  # Stamina per second


func _ready() -> void:
	# Initialize health/mana/stamina to max values
	health = get_max_health()
	mana = get_max_mana()
	stamina = get_max_stamina()


func _process(delta: float) -> void:
	# Regenerate mana
	if mana < get_max_mana():
		var regen_amount: int = int(MANA_REGEN_RATE * delta) + 1  # +1 to ensure progress
		restore_mana(regen_amount)
	
	# Regenerate stamina
	if stamina < get_max_stamina():
		var regen_amount: int = int(STAMINA_REGEN_RATE * delta) + 1  # +1 to ensure progress
		restore_stamina(regen_amount)


# Derived Stats (LOCKED FORMULAS per SPEC.md)
func get_total_str() -> int:
	# Will add equipment bonuses in Commit 2C
	return base_str


func get_total_dex() -> int:
	# Will add equipment bonuses in Commit 2C
	return base_dex


func get_total_int() -> int:
	# Will add equipment bonuses in Commit 2C
	return base_int


func get_total_vit() -> int:
	# Will add equipment bonuses in Commit 2C
	return base_vit


func get_max_health() -> int:
	return get_total_vit() * HEALTH_PER_VIT


func get_max_mana() -> int:
	return get_total_int() * MANA_PER_INT


func get_max_stamina() -> int:
	return get_total_dex() * STAMINA_PER_DEX


# Health Methods (LOCKED SIGNATURES per SPEC.md)
func set_health(value: int) -> void:
	var old_health: int = health
	health = clampi(value, 0, get_max_health())
	if health != old_health:
		health_changed.emit(health, get_max_health())
		if health <= 0:
			player_died.emit()


func heal(amount: int) -> void:
	set_health(health + amount)


func take_damage(amount: int) -> void:
	set_health(health - amount)


# Mana Methods (LOCKED SIGNATURES per SPEC.md)
func set_mana(value: int) -> void:
	var old_mana: int = mana
	mana = clampi(value, 0, get_max_mana())
	if mana != old_mana:
		mana_changed.emit(mana, get_max_mana())


func consume_mana(amount: int) -> bool:
	if not has_mana(amount):
		return false
	set_mana(mana - amount)
	return true


func has_mana(amount: int) -> bool:
	return mana >= amount


func restore_mana(amount: int) -> void:
	set_mana(mana + amount)


# Stamina Methods (LOCKED SIGNATURES per SPEC.md)
func set_stamina(value: int) -> void:
	var old_stamina: int = stamina
	stamina = clampi(value, 0, get_max_stamina())
	if stamina != old_stamina:
		stamina_changed.emit(stamina, get_max_stamina())


func consume_stamina(amount: int) -> bool:
	if not has_stamina(amount):
		return false
	set_stamina(stamina - amount)
	return true


func has_stamina(amount: int) -> bool:
	return stamina >= amount


func restore_stamina(amount: int) -> void:
	set_stamina(stamina + amount)


# Gold Methods (LOCKED SIGNATURES per SPEC.md)
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if not has_gold(amount):
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func has_gold(amount: int) -> bool:
	return gold >= amount


# Stat Modification Methods (for future use)
func set_base_stat(stat_name: String, value: int) -> void:
	match stat_name:
		"str":
			base_str = value
			stat_changed.emit("str", value)
		"dex":
			base_dex = value
			stat_changed.emit("dex", value)
		"int":
			base_int = value
			stat_changed.emit("int", value)
		"vit":
			base_vit = value
			stat_changed.emit("vit", value)
			# Update health if VIT changed
			var new_max: int = get_max_health()
			if health > new_max:
				set_health(new_max)

