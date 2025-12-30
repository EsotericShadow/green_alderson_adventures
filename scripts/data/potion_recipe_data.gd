class_name PotionRecipeData
extends RecipeData
## Extended recipe data for potions with alchemy level requirements and potency scaling.
## Follows single responsibility: defines potion recipe properties only.

@export var base_potency: int = 50  # Base potency at required_alchemy_level
@export var potency_per_level: int = 5  # Additional potency per alchemy level above required
@export var required_alchemy_level: int = 1  # Minimum alchemy level to craft this potion
@export var xp_reward: int = 10  # Alchemy XP granted when crafting this potion

