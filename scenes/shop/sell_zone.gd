# sell_zone.gd
# Drop zone for selling team units

extends Control

signal unit_sold(unit: UnitInstance, source_slot: Control)

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
	# Only accept team units for selling
	if data is Dictionary and data.get("type") == "team_unit":
		# Visual feedback - highlight sell zone
		if background:
			background.color = Color(0.8, 0.3, 0.3, 1)  # Red highlight
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.get("type") == "team_unit":
		var unit: UnitInstance = data.get("unit_data") # Using unit type hint
		var source_slot: Control = data.get("source")
		
		# Emit signal to notify shop about sale
		unit_sold.emit(unit, source_slot)
		
		# Reset visual
		_reset_visual()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_reset_visual()


func _reset_visual() -> void:
	if background:
		background.color = Color(0, 0, 0, 0)  # Transparent base
