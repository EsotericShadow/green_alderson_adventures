class_name MerchantData
extends Resource
## Defines merchant stock and pricing.

@export var id: String = ""
@export var display_name: String = ""
@export var greeting: String = "Welcome, traveler!"
@export var stock: Array[ItemData] = []
@export var prices: Array[int] = []

