extends BaseWorker
class_name SpellSelectionManager
## Worker that manages spell selection and hotbar UI connection.
## Handles equipped spells array and spell bar UI updates.

# Spell system (Commit 3C: 10 spell slots)
var equipped_spells: Array[SpellData] = []  # Size 10
var selected_spell_index: int = 0
var spell_bar: Node = null  # Reference to spell bar UI (CanvasLayer)


func _on_initialize() -> void:
	# Load default spells (Commit 3C: 10 spell slots)
	equipped_spells.resize(10)
	equipped_spells[0] = ResourceManager.load_spell("fireball")
	equipped_spells[1] = ResourceManager.load_spell("waterball")
	equipped_spells[2] = ResourceManager.load_spell("earthball")
	equipped_spells[3] = ResourceManager.load_spell("airball")
	# Slots 4-9 remain null for now
	
	# Find and connect to spell bar UI
	_find_spell_bar()
	
	_logger.log_info("  ✓ Loaded " + str(_count_equipped_spells()) + " spells")


func _find_spell_bar() -> void:
	"""Finds the spell bar UI in the scene tree."""
	# Spell bar is now a CanvasLayer, so find it directly in the scene
	var scene_tree: SceneTree = get_tree()
	if scene_tree == null:
		return
	
	spell_bar = scene_tree.current_scene.get_node_or_null("SpellBar")
	if spell_bar == null:
		# Try finding it in HUD (if it's still there)
		var hud: Node = scene_tree.current_scene.get_node_or_null("HUD")
		if hud != null:
			spell_bar = hud.get_node_or_null("SpellBar")
	
	if spell_bar == null:
		_logger.log_error("⚠️ SpellBar not found - spell bar UI unavailable")
		return
	
	_logger.log_debug("  ✓ SpellBar found: " + str(spell_bar.name) + " (type: " + spell_bar.get_class() + ")")
	
	# Setup spell bar with equipped spells
	if spell_bar.has_method("setup_spells"):
		spell_bar.setup_spells(equipped_spells)
		spell_bar.select_slot(selected_spell_index)
		_logger.log_debug("  ✓ Spell bar connected and spells set up")
	else:
		_logger.log_error("SpellBar missing setup_spells() method!")


func _count_equipped_spells() -> int:
	"""Returns the number of equipped spells."""
	var count := 0
	for spell in equipped_spells:
		if spell != null:
			count += 1
	return count


## Returns the currently selected spell.
func get_selected_spell() -> SpellData:
	if selected_spell_index >= 0 and selected_spell_index < equipped_spells.size():
		return equipped_spells[selected_spell_index]
	return null


## Selects a spell slot (0-9).
func select_spell(index: int) -> void:
	if index < 0 or index >= equipped_spells.size():
		return
	
	if equipped_spells[index] == null:
		_logger.log_debug("⚠️ Spell slot " + str(index + 1) + " is empty")
		return
	
	selected_spell_index = index
	_logger.log_debug("📖 Selected spell slot " + str(index + 1) + ": " + equipped_spells[index].display_name)
	
	# Update spell bar UI
	if spell_bar != null and spell_bar.has_method("select_slot"):
		spell_bar.select_slot(index)

