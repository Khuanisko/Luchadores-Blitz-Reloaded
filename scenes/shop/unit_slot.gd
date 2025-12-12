# unit_slot.gd
# Draggable unit slot for the shop

extends Control

signal purchased(unit_data: UnitData)
signal swap_requested(from_slot: Control, to_slot: Control)

const TOOLTIP_SCENE = preload("res://scenes/shop/unit_tooltip.tscn")

var unit_data: UnitData = null
var is_in_shop: bool = true  # Only shop units can be dragged
var tooltip_instance: Control = null

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
	
	# Connect hover signals for tooltip
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(data: UnitData) -> void:
	unit_data = data
	
	if data == null:
		if name_label:
			name_label.text = ""
		if character_texture:
			character_texture.texture = null
		if background:
			background.color = Color.WHITE # Reset to default or transparent
		return

	if name_label:
		name_label.text = data.unit_name
	if character_texture and data.unit_texture:
		character_texture.texture = data.unit_texture
	elif background:
		background.color = data.unit_color


func _get_drag_data(at_position: Vector2) -> Variant:
	if unit_data == null:
		return null
	
	# Create drag preview with proper offset
	var preview = _create_drag_preview(at_position)
	set_drag_preview(preview)
	
	# Return different type based on location
	var drag_type = "shop_unit" if is_in_shop else "team_unit"
	return {
		"type": drag_type,
		"unit_data": unit_data,
		"source": self
	}


func _create_drag_preview(at_position: Vector2) -> Control:
	# Fixed size for drag preview (larger to match shelf appearance)
	var preview_size = Vector2(100, 100)
	
	# Debug: print actual sizes
	print("Creating preview - current size: ", size, " preview_size: ", preview_size, " custom_min: ", custom_minimum_size)
	
	# Create a simple Control container
	var preview = Control.new()
	
	# Calculate the scale ratio to properly offset the click position
	var scale_ratio = preview_size / size if size != Vector2.ZERO else Vector2.ONE
	var scaled_offset = at_position * scale_ratio
	
	if unit_data.unit_texture:
		var tex_rect = TextureRect.new()
		tex_rect.texture = unit_data.unit_texture
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Get texture size and calculate scale to fit in 50x50
		var tex_size = unit_data.unit_texture.get_size()
		var scale_factor = min(preview_size.x / tex_size.x, preview_size.y / tex_size.y)
		
		# Apply scale to get exactly 50x50 (or smaller if keeping aspect)
		tex_rect.scale = Vector2(scale_factor, scale_factor)
		tex_rect.size = tex_size
		tex_rect.position = -scaled_offset
		tex_rect.modulate.a = 0.8
		
		preview.add_child(tex_rect)
	else:
		# Fallback to ColorRect
		var bg = ColorRect.new()
		bg.size = preview_size
		bg.color = unit_data.unit_color
		bg.position = -scaled_offset
		bg.modulate.a = 0.8
		preview.add_child(bg)
	
	return preview


func remove_from_shop() -> void:
	queue_free()


signal merge_completed(target_slot: Control, source_slot: Control)

# Drop handling for team unit swapping and merging
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Only team slots can accept drops for swapping/merging
	if is_in_shop:
		return false
	
	# Accept team units for swapping
	if data is Dictionary and data.get("type") == "team_unit":
		var source = data.get("source")
		# Don't swap with self
		if source != self:
			var source_data = data.get("unit_data")
			
			# Highlight for swap
			if background:
				background.modulate = Color(1.3, 1.3, 1.3)
				
				# Check for merge possibility (same unit name and strictly same level)
				if unit_data and source_data and unit_data.unit_name == source_data.unit_name and unit_data.level == source_data.level:
					background.modulate = Color(1.5, 1.5, 1.0) # Golden highlight for merge
					
			return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.get("type") == "team_unit":
		var source_slot = data.get("source")
		var source_data = data.get("unit_data")
		
		if source_slot and source_slot != self:
			# Check for merge
			if unit_data and source_data and unit_data.unit_name == source_data.unit_name and unit_data.level == source_data.level:
				# Merge Logic
				unit_data.add_xp(1)
				
				# Visual update for current slot
				setup(unit_data)
				_reset_visual()
				
				# If tooltip is showing, update it
				if tooltip_instance and tooltip_instance.visible:
					tooltip_instance.show_unit(unit_data)
				
				# Notify parent (TeamBoard) to remove source unit from data model
				merge_completed.emit(self, source_slot)
				return

			# Swap Request if not merged
			swap_requested.emit(source_slot, self)
	_reset_visual()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_reset_visual()


func _reset_visual() -> void:
	if background:
		background.modulate = Color.WHITE


func _on_mouse_entered() -> void:
	if unit_data == null:
		return
	
	# Create tooltip instance if not exists
	if tooltip_instance == null:
		tooltip_instance = TOOLTIP_SCENE.instantiate()
		# Add to root so it's on top of everything
		get_tree().root.add_child(tooltip_instance)
	
	# Update tooltip content
	tooltip_instance.show_unit(unit_data)
	
	# Position tooltip to the right of the unit slot but with significant overlap
	var slot_rect = get_global_rect()
	tooltip_instance.global_position = Vector2(slot_rect.end.x - 50, slot_rect.position.y + 10)


func _on_mouse_exited() -> void:
	if tooltip_instance:
		tooltip_instance.hide_tooltip()


func _exit_tree() -> void:
	# Clean up tooltip when slot is removed
	if tooltip_instance and is_instance_valid(tooltip_instance):
		tooltip_instance.queue_free()
