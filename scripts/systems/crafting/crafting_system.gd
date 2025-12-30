extends Node
## Global crafting system (autoload singleton).
## Manages recipe loading, ingredient validation, and crafting execution.
## Delegates potion creation to PotionCreator worker (single responsibility).

# Logging
var _logger = GameLogger.create("[CraftingSystem] ")

# Signals (LOCKED NAMES per SPEC.md)
signal item_crafted(recipe: RecipeData, result: ItemData)
signal craft_failed(recipe: RecipeData, reason: String)

# All recipes (loaded on ready)
var all_recipes: Array[RecipeData] = []

# Worker for potion creation
var _potion_creator: PotionCreator = PotionCreator.new()


func _ready() -> void:
	_logger.log("CraftingSystem initialized")
	
	# Check dependencies
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null, crafting will not work")
		return
	
	if ResourceManager == null:
		_logger.log_error("ResourceManager is null, recipes cannot be loaded")
		return
	
	if AlchemySystem == null:
		_logger.log_warning("AlchemySystem is null, potion scaling will not work")
	
	# Load all recipes
	_load_all_recipes()
	_logger.log("  Loaded " + str(all_recipes.size()) + " recipes")


## Loads all recipes from res://resources/recipes/ directory
func _load_all_recipes() -> void:
	var dir = DirAccess.open("res://resources/recipes/")
	if dir == null:
		_logger.log_error("Failed to open recipes directory: res://resources/recipes/")
		return
	
	all_recipes.clear()
	
	var error = dir.list_dir_begin()
	if error != OK:
		_logger.log_error("Failed to list recipes directory: " + str(error))
		return
	
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres") and not file_name.begins_with("."):
			var recipe_id = file_name.get_basename()
			var recipe = ResourceManager.load_recipe(recipe_id)
			if recipe != null:
				# Validate recipe data
				if recipe.ingredients.size() != recipe.ingredient_counts.size():
					_logger.log_error("Recipe '" + recipe.display_name + "' has mismatched ingredients/ingredient_counts arrays")
					file_name = dir.get_next()
					continue
				
				all_recipes.append(recipe)
				_logger.log_debug("Loaded recipe: " + recipe.display_name + " (id: " + recipe.id + ")")
			else:
				_logger.log_error("Failed to load recipe: " + recipe_id)
		file_name = dir.get_next()
	
	dir.list_dir_end()


## Returns all loaded recipes
func get_all_recipes() -> Array[RecipeData]:
	return all_recipes


## Returns recipes the player can currently craft (has all ingredients)
func get_craftable_recipes() -> Array[RecipeData]:
	var craftable: Array[RecipeData] = []
	for recipe in all_recipes:
		if can_craft(recipe):
			craftable.append(recipe)
	return craftable


## Checks if player has all required ingredients for a recipe
## Also checks alchemy level requirement for potion recipes.
## 
## Args:
##   recipe: The RecipeData to check
## 
## Returns: True if player has all ingredients in required quantities and meets level requirements
func can_craft(recipe: RecipeData) -> bool:
	if recipe == null:
		_logger.log_error("can_craft() called with null recipe")
		return false
	
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null, cannot check ingredients")
		return false
	
	# Validate recipe structure
	if recipe.ingredients.size() != recipe.ingredient_counts.size():
		_logger.log_error("Recipe '" + recipe.display_name + "' has mismatched ingredients/ingredient_counts arrays")
		return false
	
	if recipe.ingredients.is_empty():
		_logger.log_error("Recipe '" + recipe.display_name + "' has no ingredients")
		return false
	
	# Check alchemy level requirement for potion recipes
	if recipe is PotionRecipeData:
		var potion_recipe: PotionRecipeData = recipe as PotionRecipeData
		if AlchemySystem != null:
			if AlchemySystem.get_level() < potion_recipe.required_alchemy_level:
				_logger.log("Cannot craft recipe: " + recipe.display_name + " (alchemy level " + str(AlchemySystem.get_level()) + " < required " + str(potion_recipe.required_alchemy_level) + ")")
				return false
		else:
			_logger.log_warning("AlchemySystem not available, skipping level check for potion recipe")
	
	# Check each ingredient
	for i in range(recipe.ingredients.size()):
		var ingredient: ItemData = recipe.ingredients[i]
		var required_count: int = recipe.ingredient_counts[i]
		
		if ingredient == null:
			_logger.log_error("Recipe '" + recipe.display_name + "' has null ingredient at index " + str(i))
			return false
		
		if required_count <= 0:
			_logger.log_error("Recipe '" + recipe.display_name + "' has invalid ingredient count at index " + str(i))
			return false
		
		# Check if player has enough of this ingredient
		if not InventorySystem.has_item(ingredient, required_count):
			return false
	
	return true


## Executes crafting - consumes ingredients and grants result
## 
## Args:
##   recipe: The RecipeData to craft
## 
## Returns: True if crafting succeeded, false otherwise
func craft(recipe: RecipeData) -> bool:
	if recipe == null:
		_logger.log_error("craft() called with null recipe")
		craft_failed.emit(null, "Invalid recipe")
		return false
	
	if InventorySystem == null:
		_logger.log_error("InventorySystem is null, cannot craft")
		craft_failed.emit(recipe, "Inventory system unavailable")
		return false
	
	# Check if player can craft this recipe
	if not can_craft(recipe):
		_logger.log("Cannot craft recipe: " + recipe.display_name + " (insufficient ingredients)")
		craft_failed.emit(recipe, "Insufficient ingredients")
		return false
	
	# Check inventory space for result (use base result for space check)
	# Note: Scaled potions will be separate instances, so this is a conservative check
	var result: ItemData = recipe.result
	var result_count: int = recipe.result_count
	
	if result == null:
		_logger.log_error("Recipe '" + recipe.display_name + "' has null result")
		craft_failed.emit(recipe, "Invalid recipe result")
		return false
	
	# Check if we can add the result - delegates to InventorySpaceCalculator
	var is_potion_recipe: bool = recipe is PotionRecipeData
	var can_add: bool = InventorySpaceCalculator.has_space_for_items(result, result_count, is_potion_recipe)
	
	if not can_add:
		_logger.log("Cannot craft recipe: " + recipe.display_name + " (inventory full)")
		craft_failed.emit(recipe, "Inventory full")
		return false
	
	# Consume ingredients
	_consume_ingredients(recipe)
	
	# Grant result (with scaled potency for potions)
	var actual_result: ItemData = _create_result(recipe)
	_grant_result_item(actual_result, result_count)
	
	# Grant alchemy XP for potion recipes
	if recipe is PotionRecipeData:
		var potion_recipe: PotionRecipeData = recipe as PotionRecipeData
		if AlchemySystem != null and potion_recipe.xp_reward > 0:
			AlchemySystem.gain_xp(potion_recipe.xp_reward)
	
	# Emit success signal
	_logger.log("Crafted: " + recipe.display_name + " → " + actual_result.display_name + " x" + str(result_count))
	item_crafted.emit(recipe, actual_result)
	
	return true


## Removes required ingredients from inventory
func _consume_ingredients(recipe: RecipeData) -> void:
	for i in range(recipe.ingredients.size()):
		var ingredient: ItemData = recipe.ingredients[i]
		var count: int = recipe.ingredient_counts[i]
		
		var removed: bool = InventorySystem.remove_item(ingredient, count)
		if not removed:
			_logger.log_error("Failed to remove ingredient: " + ingredient.display_name + " x" + str(count) + " (should not happen if can_craft() was called)")


## Creates the result item with scaled potency if it's a potion recipe
func _create_result(recipe: RecipeData) -> ItemData:
	var result: ItemData = recipe.result
	
	# Handle potion recipes with scaling
	if recipe is PotionRecipeData:
		var potion_recipe: PotionRecipeData = recipe as PotionRecipeData
		var base_potion: PotionData = result as PotionData
		
		if base_potion == null:
			_logger.log_error("PotionRecipeData has non-PotionData result: " + result.display_name)
			return result
		
		if AlchemySystem != null:
			# Calculate scaled potency
			var scaled_potency: int = AlchemySystem.calculate_scaled_potency(
				potion_recipe.base_potency,
				potion_recipe.potency_per_level,
				potion_recipe.required_alchemy_level
			)
			
			# Create scaled potion using worker
			var scaled_potion: PotionData = _potion_creator.create_scaled_potion(base_potion, scaled_potency)
			if scaled_potion != null:
				return scaled_potion
			else:
				_logger.log_error("Failed to create scaled potion, using base potion")
				return base_potion
	
	# Non-potion recipe or scaling failed, return base result
	return result


## Adds crafted result to inventory
func _grant_result_item(result: ItemData, count: int) -> void:
	if result == null:
		_logger.log_error("_grant_result_item() called with null result")
		return
	
	var leftover: int = InventorySystem.add_item(result, count)
	if leftover > 0:
		_logger.log_error("Failed to add result to inventory (full): " + result.display_name + " x" + str(leftover) + " (should not happen if space was checked)")

