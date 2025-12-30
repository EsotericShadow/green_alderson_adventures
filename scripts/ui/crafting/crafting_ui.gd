extends CanvasLayer
## Crafting UI panel.
## Displays an alchemy crafting grid (Minecraft-like shapeless) by default.
## Keeps the legacy recipe list UI in-scene but hidden for now.

# Reuse existing inventory slot UI for consistent visuals + drag behavior.
const INVENTORY_SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot.tscn")

# Logging
var _logger = GameLogger.create("[CraftingUI] ")

@onready var control: Control = $Control
@onready var _recipe_root: HBoxContainer = $Control/PanelContainer/MarginContainer/HBoxContainer

# --- Alchemy Grid UI ---
@onready var _alchemy_root: HBoxContainer = $Control/PanelContainer/MarginContainer/AlchemyRoot
@onready var _inventory_grid: GridContainer = $Control/PanelContainer/MarginContainer/AlchemyRoot/InventoryPanel/InventoryScroll/InventoryGrid
@onready var _grid: GridContainer = $Control/PanelContainer/MarginContainer/AlchemyRoot/GridPanel/Grid
@onready var _clear_button: Button = $Control/PanelContainer/MarginContainer/AlchemyRoot/GridPanel/ClearButton
@onready var _output_icon: TextureRect = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/OutputDisplay/OutputIcon
@onready var _output_name: Label = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/OutputDisplay/OutputName
@onready var _craft_button: Button = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/CraftButton
@onready var _close_button: Button = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/CloseButton

# Tool feedback UI
@onready var _tool_mortar_icon: TextureRect = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Mortar/Icon
@onready var _tool_mortar_status: Label = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Mortar/Status
@onready var _tool_burner_icon: TextureRect = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Burner/Icon
@onready var _tool_burner_status: Label = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Burner/Status
@onready var _tool_flask_icon: TextureRect = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Flask/Icon
@onready var _tool_flask_status: Label = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Flask/Status
@onready var _tool_filter_icon: TextureRect = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Filter/Icon
@onready var _tool_filter_status: Label = $Control/PanelContainer/MarginContainer/AlchemyRoot/OutputPanel/Tools/Filter/Status

var _all_recipes: Array[RecipeData] = []
var _selected_item: ItemData = null

var _inventory_slot_nodes: Array[Node] = []
var _reserved_by_inventory_slot: Dictionary = {} # slot_index(int) -> reserved(int)

var _grid_slots: Array[Dictionary] = [] # 9 slots: { "item": ItemData, "count": int, "sources": Array[int] }
var _matched_recipe: RecipeData = null

var _tool_mortar: ItemData = null
var _tool_burner: ItemData = null
var _tool_flask: ItemData = null
var _tool_filter: ItemData = null

class AlchemyGridSlot:
	extends PanelContainer
	
	signal slot_clicked(slot_index: int, right_click: bool)
	signal item_dropped(from_inventory_slot: int, to_grid_slot: int)
	
	var slot_index: int = -1
	var item: ItemData = null
	var count: int = 0
	
	var _icon: TextureRect
	var _label: Label
	
	func _ready() -> void:
		custom_minimum_size = Vector2(110, 70)
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vb)
		
		_icon = TextureRect.new()
		_icon.custom_minimum_size = Vector2(40, 40)
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(_icon)
		
		_label = Label.new()
		_label.text = "Empty"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(_label)
		
		_set_style(false)
	
	func setup(index: int, item_data: ItemData, item_count: int) -> void:
		slot_index = index
		item = item_data
		count = item_count
		_refresh()
	
	func _refresh() -> void:
		if _icon == null or _label == null:
			return
		if item == null or count <= 0:
			_icon.texture = null
			_label.text = "Empty"
			tooltip_text = ""
		else:
			_icon.texture = item.icon
			_label.text = item.display_name + "\n x" + str(count)
			tooltip_text = item.display_name + ("\n" + item.description if item.description != "" else "")
	
	func _set_style(highlight: bool) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.2, 0.2, 0.7) if not highlight else Color(0.25, 0.25, 0.25, 0.85)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.3, 0.25, 1) if not highlight else Color(0.8, 0.7, 0.5, 1)
		add_theme_stylebox_override("panel", sb)
	
	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("slot_index") and data.has("item")
	
	func _drop_data(_pos: Vector2, data: Variant) -> void:
		if data is Dictionary and data.has("slot_index"):
			item_dropped.emit(int(data["slot_index"]), slot_index)
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				slot_clicked.emit(slot_index, false)
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				slot_clicked.emit(slot_index, true)
	
	func _mouse_enter() -> void:
		_set_style(true)
	
	func _mouse_exit() -> void:
		_set_style(false)


func _ready() -> void:
	_logger.log("CraftingUI initialized")
	
	# Check dependencies
	if CraftingSystem == null:
		_logger.log_error("CraftingSystem is null!")
		return
	
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null!")
		return
	
	# Default to new alchemy grid UI (hide legacy recipe UI)
	if _recipe_root != null:
		_recipe_root.visible = false
	if _alchemy_root != null:
		_alchemy_root.visible = true
	
	# Connect signals
	CraftingSystem.item_crafted.connect(_on_item_crafted)
	CraftingSystem.craft_failed.connect(_on_craft_failed)
	InventorySystem.inventory_changed.connect(_refresh_inventory_grid)
	
	# Connect UI signals
	if _clear_button != null:
		_clear_button.pressed.connect(_clear_grid)
	if _craft_button != null:
		_craft_button.pressed.connect(_on_craft_pressed)
	if _close_button != null:
		_close_button.pressed.connect(_on_close_button_pressed)
	
	# Start hidden
	if control != null:
		control.visible = false
	
	# Load recipes (we match shapeless by ingredients)
	_all_recipes = CraftingSystem.get_all_recipes()

	_tool_mortar = ResourceManager.load_item("mortar_and_pestle") if ResourceManager != null else null
	_tool_burner = ResourceManager.load_item("bunsen_burner") if ResourceManager != null else null
	_tool_flask = ResourceManager.load_item("distilling_flask") if ResourceManager != null else null
	_tool_filter = ResourceManager.load_item("essence_filter") if ResourceManager != null else null

	_init_grid()
	_init_inventory_grid()
	_refresh_inventory_grid()
	_update_output_preview()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_crafting"):
		var ui_visible: bool = control.visible if control != null else false
		if ui_visible:
			close()
		else:
			open()


func open() -> void:
	_logger.log("open() called")
	if control != null:
		control.visible = true
		_all_recipes = CraftingSystem.get_all_recipes()
		_refresh_inventory_grid()
		_update_output_preview()
		if EventBus != null:
			EventBus.crafting_opened.emit()
	else:
		_logger.log_error("control is null!")


func close() -> void:
	_logger.log("close() called")
	if control != null:
		control.visible = false
		if EventBus != null:
			EventBus.crafting_closed.emit()
	else:
		_logger.log_error("control is null!")


func _init_grid() -> void:
	_grid_slots.clear()
	_grid_slots.resize(9)
	for i in range(9):
		_grid_slots[i] = {"item": null, "count": 0, "sources": []}
	
	if _grid == null:
		return
	
	# Create 9 buttons if not present
	if _grid.get_child_count() == 0:
		for i in range(9):
			var slot := AlchemyGridSlot.new()
			_grid.add_child(slot)
			slot.setup(i, null, 0)
			slot.item_dropped.connect(_on_grid_item_dropped)
			slot.slot_clicked.connect(_on_grid_slot_clicked)
	
	_render_grid()


func _init_inventory_grid() -> void:
	if _inventory_grid == null or InventorySystem == null:
		return
	
	# Clear existing
	for child in _inventory_grid.get_children():
		_inventory_grid.remove_child(child)
		child.queue_free()
	_inventory_slot_nodes.clear()
	
	_reserved_by_inventory_slot.clear()
	for i in range(InventorySystem.capacity):
		_reserved_by_inventory_slot[i] = 0
	
	for i in range(InventorySystem.capacity):
		var slot_node := INVENTORY_SLOT_SCENE.instantiate()
		_inventory_grid.add_child(slot_node)
		_inventory_slot_nodes.append(slot_node)
		
		# Click selects item (optional)
		if slot_node.has_signal("slot_clicked"):
			slot_node.slot_clicked.connect(_on_inventory_slot_clicked)


func _refresh_inventory_grid() -> void:
	if InventorySystem == null:
		return
	
	# Ensure grid is built for capacity
	if _inventory_slot_nodes.size() != InventorySystem.capacity:
		_init_inventory_grid()
	
	for i in range(InventorySystem.capacity):
		var node = _inventory_slot_nodes[i]
		var slot_data: Dictionary = InventorySystem.get_slot(i)
		var item: ItemData = slot_data.get("item")
		var count: int = slot_data.get("count", 0)
		var reserved: int = int(_reserved_by_inventory_slot.get(i, 0))
		var available: int = max(0, count - reserved)
		
		if node != null and node.has_method("setup"):
			# Mimic Minecraft: items placed in grid disappear from inventory view
			if item != null and available > 0:
				node.setup(i, item, available)
			else:
				node.setup(i, null, 0)
	
	_update_tool_feedback()


func _render_grid() -> void:
	if _grid == null:
		return
	
	var children := _grid.get_children()
	for i in range(min(children.size(), 9)):
		var slot_node := children[i]
		var slot := _grid_slots[i]
		var item: ItemData = slot["item"]
		var count: int = slot["count"]
		
		if slot_node is AlchemyGridSlot:
			(slot_node as AlchemyGridSlot).setup(i, item, count)


func _on_inventory_slot_clicked(slot_index: int) -> void:
	# Optional: clicking selects the item for "replace" operations
	if InventorySystem == null:
		return
	var slot: Dictionary = InventorySystem.get_slot(slot_index)
	_selected_item = slot.get("item")


func _on_grid_item_dropped(from_inventory_slot: int, to_grid_slot: int) -> void:
	_try_add_to_grid_from_inventory(from_inventory_slot, to_grid_slot)


func _on_grid_slot_clicked(slot_index: int, right_click: bool) -> void:
	# Left click: remove 1, Right click: clear slot
	if right_click:
		_clear_grid_slot(slot_index)
	else:
		_remove_one_from_grid_slot(slot_index)


func _try_add_to_grid_from_inventory(from_slot: int, to_grid_slot: int) -> void:
	if InventorySystem == null:
		return
	if from_slot < 0 or from_slot >= InventorySystem.capacity:
		return
	if to_grid_slot < 0 or to_grid_slot >= _grid_slots.size():
		return
	
	var inv_slot: Dictionary = InventorySystem.get_slot(from_slot)
	var item: ItemData = inv_slot.get("item")
	var count: int = inv_slot.get("count", 0)
	if item == null or count <= 0:
		return
	
	var reserved: int = int(_reserved_by_inventory_slot.get(from_slot, 0))
	if reserved >= count:
		return  # no available items left in this slot
	
	# If slot contains different item, clear it first (to release reservations)
	var slot := _grid_slots[to_grid_slot]
	if slot.get("item") != null and slot.get("item") != item:
		_clear_grid_slot(to_grid_slot)
		slot = _grid_slots[to_grid_slot]
	
	slot["item"] = item
	slot["count"] = int(slot.get("count", 0)) + 1
	var sources: Array = slot.get("sources", [])
	sources.append(from_slot)
	slot["sources"] = sources
	_grid_slots[to_grid_slot] = slot
	
	_reserved_by_inventory_slot[from_slot] = reserved + 1
	
	_render_grid()
	_refresh_inventory_grid()
	_update_output_preview()


func _remove_one_from_grid_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _grid_slots.size():
		return
	var slot := _grid_slots[slot_index]
	var count: int = int(slot.get("count", 0))
	if count <= 0:
		return
	
	var sources: Array = slot.get("sources", [])
	if sources.size() > 0:
		var from_slot: int = int(sources.pop_back())
		_reserved_by_inventory_slot[from_slot] = max(0, int(_reserved_by_inventory_slot.get(from_slot, 0)) - 1)
		slot["sources"] = sources
	
	count -= 1
	slot["count"] = count
	if count <= 0:
		slot["item"] = null
		slot["sources"] = []
	_grid_slots[slot_index] = slot
	
	_render_grid()
	_refresh_inventory_grid()
	_update_output_preview()


func _clear_grid_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _grid_slots.size():
		return
	var slot := _grid_slots[slot_index]
	var sources: Array = slot.get("sources", [])
	for from_slot in sources:
		var idx: int = int(from_slot)
		_reserved_by_inventory_slot[idx] = max(0, int(_reserved_by_inventory_slot.get(idx, 0)) - 1)
	
	_grid_slots[slot_index] = {"item": null, "count": 0, "sources": []}
	_render_grid()
	_refresh_inventory_grid()
	_update_output_preview()


func _clear_grid() -> void:
	# Release all reservations
	for i in range(_grid_slots.size()):
		_clear_grid_slot(i)
	_selected_item = null
	_matched_recipe = null
	_render_grid()
	_refresh_inventory_grid()
	_update_output_preview()


func _update_output_preview() -> void:
	_matched_recipe = _find_matching_recipe()
	
	if _matched_recipe == null:
		if _output_icon != null:
			_output_icon.texture = null
		if _output_name != null:
			_output_name.text = "No match"
		if _craft_button != null:
			_craft_button.disabled = true
		return
	
	# Show output
	if _output_icon != null:
		_output_icon.texture = _matched_recipe.result.icon if _matched_recipe.result != null else null
	if _output_name != null:
		_output_name.text = _matched_recipe.result.display_name if _matched_recipe.result != null else "Unknown"
	
	# Enable craft if CraftingSystem says it is craftable (includes alchemy level + inventory)
	if _craft_button != null:
		var can_craft_recipe: bool = CraftingSystem.can_craft(_matched_recipe)
		var tools_ok: bool = _are_required_tools_available(_matched_recipe)
		_craft_button.disabled = not (can_craft_recipe and tools_ok)
	
	_update_tool_feedback()


func _are_required_tools_available(recipe: RecipeData) -> bool:
	if recipe == null or InventorySystem == null:
		return false
	var required := _get_required_tools(recipe)
	for tool_id in required:
		var tool: ItemData = required[tool_id]
		if tool == null:
			return false
		if not InventorySystem.has_item(tool, 1):
			return false
	return true


func _get_required_tools(recipe: RecipeData) -> Dictionary:
	# Minimal rule set for now:
	# - Any potion craft requires mortar & pestle (crushing/prep step)
	# - "Vial method" recipes (or recipes that use a filled vial ingredient) require burner + flask + filter
	var tools := {}
	
	if recipe != null and recipe.result is PotionData:
		tools["mortar"] = _tool_mortar
	
	var needs_advanced: bool = recipe != null and (recipe.id.contains("_vial"))
	if recipe != null:
		for ing in recipe.ingredients:
			if ing is PotionData:
				needs_advanced = true
				break
	
	if needs_advanced:
		tools["burner"] = _tool_burner
		tools["flask"] = _tool_flask
		tools["filter"] = _tool_filter
	
	return tools


func _set_tool_row(icon_node: TextureRect, label_node: Label, item: ItemData, required: bool) -> void:
	if icon_node != null:
		icon_node.texture = item.icon if item != null else null
	if label_node == null:
		return
	
	if not required:
		label_node.text = (item.display_name if item != null else "Tool") + ": optional"
		label_node.modulate = Color(0.8, 0.8, 0.8)
		return
	
	var has_tool: bool = item != null and InventorySystem != null and InventorySystem.has_item(item, 1)
	label_node.text = (item.display_name if item != null else "Tool") + (": OK" if has_tool else ": MISSING")
	label_node.modulate = Color(0.6, 1.0, 0.6) if has_tool else Color(1.0, 0.6, 0.6)


func _update_tool_feedback() -> void:
	var recipe := _matched_recipe
	var required := _get_required_tools(recipe) if recipe != null else {}
	
	_set_tool_row(_tool_mortar_icon, _tool_mortar_status, _tool_mortar, required.has("mortar"))
	_set_tool_row(_tool_burner_icon, _tool_burner_status, _tool_burner, required.has("burner"))
	_set_tool_row(_tool_flask_icon, _tool_flask_status, _tool_flask, required.has("flask"))
	_set_tool_row(_tool_filter_icon, _tool_filter_status, _tool_filter, required.has("filter"))


func _find_matching_recipe() -> RecipeData:
	if CraftingSystem == null:
		return null
	
	# Build multiset from grid
	var grid_counts: Dictionary = {} # ItemData -> int
	for slot in _grid_slots:
		var item: ItemData = slot.get("item")
		var count: int = slot.get("count", 0)
		if item != null and count > 0:
			grid_counts[item] = int(grid_counts.get(item, 0)) + count
	
	if grid_counts.is_empty():
		return null
	
	# Match exact ingredient counts (shapeless)
	for recipe in _all_recipes:
		if recipe == null:
			continue
		
		# Alchemy bench: focus on potion-related recipes
		if recipe.result == null:
			continue
		if not (recipe.result is PotionData) and not recipe.id.contains("potion"):
			continue
		
		if recipe.ingredients.size() != recipe.ingredient_counts.size():
			continue
		
		var recipe_counts: Dictionary = {}
		for i in range(recipe.ingredients.size()):
			var ing: ItemData = recipe.ingredients[i]
			var req: int = recipe.ingredient_counts[i]
			if ing == null or req <= 0:
				recipe_counts.clear()
				break
			recipe_counts[ing] = int(recipe_counts.get(ing, 0)) + req
		
		if recipe_counts.is_empty():
			continue
		
		if recipe_counts.size() != grid_counts.size():
			continue
		
		var is_match := true
		for ing in recipe_counts.keys():
			if int(grid_counts.get(ing, -1)) != int(recipe_counts[ing]):
				is_match = false
				break
		
		if is_match:
			return recipe
	
	return null


func _on_craft_pressed() -> void:
	if _matched_recipe == null:
		return
	if CraftingSystem == null:
		return
	if not _are_required_tools_available(_matched_recipe):
		_logger.log("Cannot craft: missing required tools")
		_update_tool_feedback()
		return
	
	var success := CraftingSystem.craft(_matched_recipe)
	if success:
		_clear_grid()
		_refresh_inventory_grid()
		_update_output_preview()


func _on_close_button_pressed() -> void:
	close()


func _on_item_crafted(_recipe: RecipeData, result: ItemData) -> void:
	_logger.log("Item crafted signal received: " + result.display_name)
	_refresh_inventory_grid()
	_update_output_preview()


func _on_craft_failed(recipe: RecipeData, reason: String) -> void:
	_logger.log("Craft failed: " + recipe.display_name + " - " + reason)
