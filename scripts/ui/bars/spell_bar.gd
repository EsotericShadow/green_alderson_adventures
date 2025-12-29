extends CanvasLayer
## Spell hotbar UI.
## Displays 10 spell slots (1-9, 0) and manages selection.

# Logging
var _logger = GameLogger.create("[SpellBar] ")

signal spell_selected(slot_index: int)

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/spell_slot.tscn")
const NUM_SLOTS: int = 10

@onready var slot_container: HBoxContainer = $Control/HBoxContainer

var slots: Array[SpellSlot] = []
var selected_index: int = 0
var _pending_spells: Array[SpellData] = []  # Spells to apply after _ready()


func _ready() -> void:
	_logger.log("_ready() called")
	_logger.log("CanvasLayer layer: " + str(layer) + ", visible: " + str(visible))
	var control := $Control
	if control != null:
		_logger.log("Control node found, visible: " + str(control.visible) + ", size: " + str(control.size))
		# Force visibility
		control.visible = true
	else:
		_logger.log_error("Control node not found!")
	
	if slot_container != null:
		_logger.log("HBoxContainer found, visible: " + str(slot_container.visible) + ", size: " + str(slot_container.size))
	else:
		_logger.log_error("HBoxContainer not found!")
	
	_create_slots()
	
	# Apply any spells that were queued before _ready() completed
	if _pending_spells.size() > 0:
		_logger.log("Applying " + str(_pending_spells.size()) + " queued spells...")
		var spells_to_apply = _pending_spells.duplicate()
		_pending_spells.clear()
		setup_spells(spells_to_apply)


func _create_slots() -> void:
	# Clear existing slots
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	if slot_container == null:
		_logger.log_error("slot_container is null! Cannot create slots.")
		return
	
	_logger.log("Creating " + str(NUM_SLOTS) + " spell slots...")
	
	# Create 10 slots
	for i in range(NUM_SLOTS):
		var slot: SpellSlot = SLOT_SCENE.instantiate()
		slot_container.add_child(slot)
		slot.setup(i, null)  # Start with no spell
		slot.slot_clicked.connect(_on_slot_clicked)
		slots.append(slot)
		_logger.log("  Created slot " + str(i + 1) + " (index " + str(i) + ")")
	
	_logger.log("Total slots created: " + str(slots.size()))
	
	# Select first slot by default
	if slots.size() > 0:
		select_slot(0)
		_logger.log("Selected slot 0 by default")
	else:
		_logger.log_error("No slots created!")


func setup_spells(spell_list: Array[SpellData]) -> void:
	_logger.log("setup_spells() called with " + str(spell_list.size()) + " spells")
	_logger.log("Current slots array size: " + str(slots.size()))
	
	# If nodes aren't ready yet, queue the spells for later
	if slot_container == null:
		_logger.log("slot_container not ready yet - queuing spells to apply after _ready()")
		_pending_spells = spell_list.duplicate()
		return
	
	# Ensure slots are created first
	if slots.size() == 0:
		_logger.log("No slots yet - creating them now...")
		_create_slots()
	
	# Set spells for each slot
	for i in range(min(spell_list.size(), NUM_SLOTS)):
		if i >= slots.size():
			_logger.log_error("Slot index " + str(i) + " out of bounds! Slots size: " + str(slots.size()))
			continue
		
		if slots[i] != null:
			if spell_list[i] != null:
				_logger.log("  Setting spell " + str(i) + ": " + spell_list[i].display_name)
			slots[i].setup(i, spell_list[i])
		else:
			_logger.log_error("Slot " + str(i) + " is null!")


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
