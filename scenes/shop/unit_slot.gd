# unit_slot.gd
# Draggable unit slot for the shop

extends Control

signal purchased(unit_data: UnitData)
signal swap_requested(from_slot: Control, to_slot: Control)

var unit_data: UnitData = null
var is_in_shop: bool = true  # Only shop units can be dragged

@onready var background: ColorRect = $Background
@onready var character_texture: TextureRect = $CharacterTexture
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Children must pass through mouse events to allow drag
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_PASS
	if character_texture:
		character_texture.mouse_filter = Control.MOUSE_FILTER_PASS
	if name_label:
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS


func setup(data: UnitData) -> void:
	unit_data = data
	if name_label:
		name_label.text = data.unit_name
	if character_texture and data.unit_texture:
		character_texture.texture = data.unit_texture
	elif background:
		background.color = data.unit_color


func _get_drag_data(_at_position: Vector2) -> Variant:
	if unit_data == null:
		return null
	
	# Create drag preview
	var preview = _create_drag_preview()
	set_drag_preview(preview)
	
	# Return different type based on location
	var drag_type = "shop_unit" if is_in_shop else "team_unit"
	return {
		"type": drag_type,
		"unit_data": unit_data,
		"source": self
	}


func _create_drag_preview() -> Control:
	var preview = Control.new()
	preview.size = size
	preview.modulate.a = 0.8
	
	if unit_data.unit_texture:
		var tex_rect = TextureRect.new()
		tex_rect.texture = unit_data.unit_texture
		tex_rect.size = size
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(tex_rect)
	else:
		var bg = ColorRect.new()
		bg.size = size
		bg.color = unit_data.unit_color
		preview.add_child(bg)
	
	return preview


func remove_from_shop() -> void:
	queue_free()


# Drop handling for team unit swapping
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Only team slots can accept drops for swapping
	if is_in_shop:
		return false
	
	# Accept team units for swapping
	if data is Dictionary and data.get("type") == "team_unit":
		var source = data.get("source")
		# Don't swap with self
		if source != self:
			if background:
				background.modulate = Color(1.3, 1.3, 1.3)  # Highlight
			return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.get("type") == "team_unit":
		var source_slot = data.get("source")
		if source_slot and source_slot != self:
			swap_requested.emit(source_slot, self)
	_reset_visual()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_reset_visual()


func _reset_visual() -> void:
	if background:
		background.modulate = Color.WHITE
