class_name MerchantData
extends Resource
## Defines a merchant's stock and pricing.
## stock and prices arrays must be same size.
## Sell price is always 50% of buy price.

@export var id: String = ""
@export var display_name: String = ""
@export var greeting: String = "Welcome, traveler!"
@export var stock: Array[ItemData] = []
@export var prices: Array[int] = []

