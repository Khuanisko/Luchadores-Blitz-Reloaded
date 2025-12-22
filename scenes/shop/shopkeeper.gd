# shopkeeper.gd
# Drop zone for buying units - the shopkeeper

extends Control

signal unit_purchased(unit: UnitInstance, source_slot: Control)

@onready var background: ColorRect = $Background
@onready var label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Children must pass through mouse events to allow drop
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_PASS
	if label:
		label.mouse_filter = Control.MOUSE_FILTER_PASS


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		var type = data.get("type")
		if type == "shop_unit":
			return true
		if type == "shop_item":
			return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary: return
	
	var type = data.get("type")
	var source_slot: Control = data.get("source")
	
	# Handle Unit Purchase
	if type == "shop_unit":
		var unit: UnitInstance = data.get("unit_data")
		unit_purchased.emit(unit, source_slot)
		
	# Handle Global Item Usage (Poster)
	elif type == "shop_item":
		var item: ItemDefinition = data.get("item")
		var cost = data.get("cost", 0)
		
		if item and source_slot:
			if GameData.gold >= cost:
				# Spend gold
				GameData.spend_gold(cost)
				
				# Execute item effect globally (null target)
				if item.item_effect:
					item.item_effect.execute(null)
					print("Item used on Shopkeeper: ", item.name)
				
				# Remove from shop
				source_slot.remove_from_shop()
			else:
				print("Not enough gold to buy item!")


func _notification(what: int) -> void:
	pass  # No visual reset needed


func _reset_visual() -> void:
	pass  # Keep transparent
