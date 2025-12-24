extends Control
## Spell hotbar UI.
## Displays 10 spell slots (1-9, 0) and manages selection.

signal spell_selected(slot_index: int)

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/spell_slot.tscn")
const NUM_SLOTS: int = 10

@onready var slot_container: HBoxContainer = $Control/HBoxContainer

var slots: Array[SpellSlot] = []
var selected_index: int = 0


func _ready() -> void:
	_create_slots()


func _create_slots() -> void:
	# Clear existing slots
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	# Create 10 slots
	for i in range(NUM_SLOTS):
		var slot: SpellSlot = SLOT_SCENE.instantiate()
		slot_container.add_child(slot)
		slot.setup(i, null)  # Start with no spell
		slot.slot_clicked.connect(_on_slot_clicked)
		slots.append(slot)
	
	# Select first slot by default
	if slots.size() > 0:
		select_slot(0)


func setup_spells(spell_list: Array[SpellData]) -> void:
	# Set spells for each slot
	for i in range(min(spell_list.size(), NUM_SLOTS)):
		if slots[i] != null:
			slots[i].setup(i, spell_list[i])


func _select_slot(index: int) -> void:
	"""Public method to select a spell slot (called by player)."""
	select_slot(index)


func select_slot(index: int) -> void:
	"""Selects a spell slot by index."""
	if index < 0 or index >= slots.size():
		return
	
	# Deselect previous
	if selected_index >= 0 and selected_index < slots.size():
		slots[selected_index].set_selected(false)
	
	# Select new
	selected_index = index
	slots[selected_index].set_selected(true)
	
	# Emit signal
	spell_selected.emit(selected_index)


func _on_slot_clicked(slot_index: int) -> void:
	select_slot(slot_index)


func update_cooldown(slot_index: int, progress: float) -> void:
	# progress: 0.0 = ready, 1.0 = full cooldown
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].set_cooldown_progress(progress)

