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
	if data is Dictionary and data.get("type") == "shop_unit":
		# No visual feedback - keep transparent
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.get("type") == "shop_unit":
		var unit: UnitInstance = data.get("unit_data") # Dictionary key can stay same or change, I'll keep 'unit_data' key in drag data for compatibility if minimal changes, but variable type is UnitInstance
		var source_slot: Control = data.get("source")
		
		# Emit signal to notify shop about purchase
		unit_purchased.emit(unit, source_slot)


func _notification(what: int) -> void:
	pass  # No visual reset needed


func _reset_visual() -> void:
	pass  # Keep transparent
