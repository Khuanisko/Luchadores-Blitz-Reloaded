# team_board.gd
# Sliding team board with rope trigger

extends Control

signal unit_sold(unit_data: UnitData, source_slot: Control)

const UNIT_SLOT_SCENE = preload("res://scenes/shop/unit_slot.tscn")

var is_open: bool = false
var team_units: Array[UnitData] = []

@onready var board: Control = $Board
@onready var rope_button: TextureButton = $RopeButton
@onready var team_container: HBoxContainer = $Board/TeamContainer
@onready var sell_zone: Control = $Board/SellZone


func _ready() -> void:
	# Start hidden (board off screen)
	board.visible = false
	rope_button.pressed.connect(_on_rope_pressed)
	if sell_zone:
		sell_zone.unit_sold.connect(_on_unit_sold)
	# Wait for layout to be ready then hide board
	await get_tree().process_frame
	board.position.y = -1000  # Move far off screen
	board.visible = true


func _on_rope_pressed() -> void:
	if is_open:
		close_board()
	else:
		open_board()


func open_board() -> void:
	is_open = true
	# Hide rope when board opens
	rope_button.visible = false
	var tween = create_tween()
	tween.tween_property(board, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func close_board() -> void:
	is_open = false
	var tween = create_tween()
	tween.tween_property(board, "position:y", -1000, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	# Show rope when board closes
	tween.tween_callback(func(): rope_button.visible = true)


func _input(event: InputEvent) -> void:
	# Close when clicking outside board area
	if is_open and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			if not board.get_global_rect().has_point(mouse_pos):
				close_board()


func add_unit(unit_data: UnitData) -> void:
	team_units.append(unit_data)
	_update_team_display()


func _update_team_display() -> void:
	# Clear existing
	for child in team_container.get_children():
		child.queue_free()
	
	# Add all team units
	for i in range(team_units.size()):
		var unit_data = team_units[i]
		var team_slot = UNIT_SLOT_SCENE.instantiate()
		team_container.add_child(team_slot)
		team_slot.setup(unit_data)
		team_slot.is_in_shop = false
		team_slot.swap_requested.connect(_on_swap_requested)


func _on_swap_requested(from_slot: Control, to_slot: Control) -> void:
	var from_index = from_slot.get_index()
	var to_index = to_slot.get_index()
	
	if from_index >= 0 and to_index >= 0 and from_index < team_units.size() and to_index < team_units.size():
		var temp = team_units[from_index]
		team_units[from_index] = team_units[to_index]
		team_units[to_index] = temp
		_update_team_display()


func _on_unit_sold(unit_data: UnitData, source_slot: Control) -> void:
	var slot_index = source_slot.get_index()
	if slot_index >= 0 and slot_index < team_units.size():
		team_units.remove_at(slot_index)
		_update_team_display()
		unit_sold.emit(unit_data, source_slot)
