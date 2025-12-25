extends CanvasLayer
## Player Interface Panel
## Right-side panel with tabs for Inventory, Equipment, Spells, Stats, and Settings

const LOG_PREFIX := "[PLAYER_PANEL] "

# Tab indices
enum Tab { INVENTORY, EQUIPMENT, SPELLS, STATS, SETTINGS }

@onready var tab_bar: HBoxContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/TabBar
@onready var tab_content: Control = $Control/PanelContainer/MarginContainer/VBoxContainer/TabContent

# Tab buttons
@onready var inventory_tab_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/TabBar/InventoryTab
@onready var equipment_tab_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/TabBar/EquipmentTab
@onready var spells_tab_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/TabBar/SpellsTab
@onready var stats_tab_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/TabBar/StatsTab
@onready var settings_tab_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/TabBar/SettingsTab

# Tab content panels
@onready var inventory_panel: Control = $Control/PanelContainer/MarginContainer/VBoxContainer/TabContent/InventoryPanel
@onready var equipment_panel: Control = $Control/PanelContainer/MarginContainer/VBoxContainer/TabContent/EquipmentPanel
@onready var spells_panel: Control = $Control/PanelContainer/MarginContainer/VBoxContainer/TabContent/SpellsPanel
@onready var stats_panel: Control = $Control/PanelContainer/MarginContainer/VBoxContainer/TabContent/StatsPanel
@onready var settings_panel: Control = $Control/PanelContainer/MarginContainer/VBoxContainer/TabContent/SettingsPanel

var current_tab: Tab = Tab.INVENTORY


func _ready() -> void:
	layer = 15  # Between HUD (10) and SpellBar (19)
	print(LOG_PREFIX + "Player panel ready")
	
	# Connect tab buttons
	inventory_tab_button.pressed.connect(func(): switch_tab(Tab.INVENTORY))
	equipment_tab_button.pressed.connect(func(): switch_tab(Tab.EQUIPMENT))
	spells_tab_button.pressed.connect(func(): switch_tab(Tab.SPELLS))
	stats_tab_button.pressed.connect(func(): switch_tab(Tab.STATS))
	settings_tab_button.pressed.connect(func(): switch_tab(Tab.SETTINGS))
	
	# Show initial tab
	switch_tab(Tab.INVENTORY)


func switch_tab(tab: Tab) -> void:
	current_tab = tab
	
	# Hide all panels
	inventory_panel.visible = false
	equipment_panel.visible = false
	spells_panel.visible = false
	stats_panel.visible = false
	settings_panel.visible = false
	
	# Show selected panel
	match tab:
		Tab.INVENTORY:
			inventory_panel.visible = true
		Tab.EQUIPMENT:
			equipment_panel.visible = true
		Tab.SPELLS:
			spells_panel.visible = true
		Tab.STATS:
			stats_panel.visible = true
		Tab.SETTINGS:
			settings_panel.visible = true
	
	# Update button states (visual feedback)
	_update_tab_buttons()


func _update_tab_buttons() -> void:
	# Reset all buttons
	inventory_tab_button.button_pressed = (current_tab == Tab.INVENTORY)
	equipment_tab_button.button_pressed = (current_tab == Tab.EQUIPMENT)
	spells_tab_button.button_pressed = (current_tab == Tab.SPELLS)
	stats_tab_button.button_pressed = (current_tab == Tab.STATS)
	settings_tab_button.button_pressed = (current_tab == Tab.SETTINGS)
