class_name PotionCreator
extends RefCounted
## Worker class for creating potions with scaled potency.
## Follows single responsibility: creates potion instances with scaled values.

var _logger = GameLogger.create("[PotionCreator] ")


func create_scaled_potion(base_potion: PotionData, scaled_potency: int) -> PotionData:
	"""Creates a new PotionData instance with scaled potency.
	
	Args:
		base_potion: The base PotionData template
		scaled_potency: The scaled potency value to apply
	
	Returns: New PotionData instance with scaled potency
	"""
	if base_potion == null:
		_logger.log_error("create_scaled_potion() called with null base_potion")
		return null
	
	# Create a new PotionData instance (duplicate the resource)
	var scaled_potion: PotionData = base_potion.duplicate() as PotionData
	
	if scaled_potion == null:
		_logger.log_error("Failed to duplicate PotionData")
		return null
	
	# Apply scaled potency
	scaled_potion.potency = scaled_potency
	
	_logger.log("Created scaled potion: " + scaled_potion.display_name + " (potency: " + str(scaled_potency) + ")")
	
	return scaled_potion

