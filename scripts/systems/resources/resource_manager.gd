extends Node
## Global resource loading system (autoload singleton).
## Centralizes all resource loading with caching and validation.
## Uses generic load_resource() method for type safety.

# Logging
var _logger = GameLogger.create("[ResourceManager] ")

# Resource paths (centralized)
const SPELLS_PATH: String = "res://resources/spells/"
const ITEMS_PATH: String = "res://resources/items/"
const POTIONS_PATH: String = "res://resources/potions/"
const EQUIPMENT_PATH: String = "res://resources/equipment/"
const RECIPES_PATH: String = "res://resources/recipes/"
const MERCHANTS_PATH: String = "res://resources/merchants/"

# Cache for loaded resources (keyed by resource type and ID)
var _cache: Dictionary = {
	"SpellData": {},
	"ItemData": {},
	"PotionData": {},
	"EquipmentData": {},
	"RecipeData": {},
	"PotionRecipeData": {},
	"MerchantData": {}
}


func _ready() -> void:
	_logger.log("ResourceManager initialized")
	_logger.log("  Spell path: " + SPELLS_PATH)
	_logger.log("  Item path: " + ITEMS_PATH)
	_logger.log("  Potion path: " + POTIONS_PATH)


## Generic resource loading method with type safety.
## 
## Args:
##   resource_type: Type name (e.g., "SpellData", "ItemData")
##   resource_id: Resource identifier (e.g., "fireball", "health_potion")
## 
## Returns:
##   Resource of the specified type, or null if not found
func load_resource(resource_type: String, resource_id: String) -> Resource:
	# Check cache first
	if _cache.has(resource_type) and _cache[resource_type].has(resource_id):
		return _cache[resource_type][resource_id]
	
	# Determine path based on type
	var path: String = _get_path_for_type(resource_type)
	if path.is_empty():
		_logger.log_error("Unknown resource type: " + resource_type)
		return null
	
	# Load from disk
	var full_path: String = path + resource_id + ".tres"
	var resource = load(full_path) as Resource
	if resource == null:
		_logger.log_error("Failed to load " + resource_type + ": " + resource_id + " from " + full_path)
		return null
	
	# Note: Type validation is handled by the type cast in the calling function (e.g., `as SpellData`)
	# We skip strict validation here since Godot's type system handles it at runtime
	
	# Cache it
	if not _cache.has(resource_type):
		_cache[resource_type] = {}
	_cache[resource_type][resource_id] = resource
	_logger.log_debug("Loaded " + resource_type + ": " + resource_id)
	return resource


## Gets the resource path for a given type.
func _get_path_for_type(resource_type: String) -> String:
	match resource_type:
		"SpellData":
			return SPELLS_PATH
		"ItemData":
			return ITEMS_PATH
		"PotionData":
			return POTIONS_PATH
		"EquipmentData":
			return EQUIPMENT_PATH
		"RecipeData", "PotionRecipeData":
			return RECIPES_PATH
		"MerchantData":
			return MERCHANTS_PATH
		_:
			return ""


# === TYPE-SPECIFIC LOADERS (for backwards compatibility) ===

func load_spell(spell_id: String) -> SpellData:
	return load_resource("SpellData", spell_id) as SpellData


func load_item(item_id: String) -> ItemData:
	return load_resource("ItemData", item_id) as ItemData


func load_potion(potion_id: String) -> PotionData:
	return load_resource("PotionData", potion_id) as PotionData


func load_equipment(equipment_id: String) -> EquipmentData:
	return load_resource("EquipmentData", equipment_id) as EquipmentData


func load_recipe(recipe_id: String) -> RecipeData:
	# Try loading as PotionRecipeData first, fall back to RecipeData
	var potion_recipe = load_resource("PotionRecipeData", recipe_id) as PotionRecipeData
	if potion_recipe != null:
		return potion_recipe
	return load_resource("RecipeData", recipe_id) as RecipeData


func load_merchant(merchant_id: String) -> MerchantData:
	return load_resource("MerchantData", merchant_id) as MerchantData


# === SCENE LOADING ===

func load_scene(scene_path: String) -> PackedScene:
	"""Loads a PackedScene resource by path.
	
	Args:
		scene_path: Path to .tscn file
		
	Returns:
		PackedScene resource, or null if not found
	"""
	if scene_path.is_empty():
		_logger.log_error("Empty scene path provided")
		return null
	
	var resource = load(scene_path) as PackedScene
	if resource == null:
		_logger.log_error("Failed to load scene: " + scene_path)
		return null
	
	_logger.log_debug("Loaded scene: " + scene_path)
	return resource


# === CACHE MANAGEMENT ===

func clear_cache() -> void:
	"""Clears all resource caches. Useful for hot-reloading or memory management."""
	for type in _cache:
		_cache[type].clear()
	_logger.log("Resource caches cleared")


func clear_cache_for_type(resource_type: String) -> void:
	"""Clears cache for a specific resource type."""
	if _cache.has(resource_type):
		_cache[resource_type].clear()
		_logger.log("Cache cleared for " + resource_type)
	else:
		_logger.log_error("Unknown resource type: " + resource_type)


func get_cache_size() -> Dictionary:
	"""Returns the current cache sizes for debugging."""
	var sizes := {}
	for type in _cache:
		sizes[type] = _cache[type].size()
	return sizes
