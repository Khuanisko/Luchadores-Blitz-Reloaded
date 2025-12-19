# unit_slot.gd
# Draggable unit slot for the shop

extends Control

signal purchased(unit: UnitInstance)
signal swap_requested(from_slot: Control, to_slot: Control)
signal merge_completed(target_slot: Control, source_slot: Control)

const TOOLTIP_SCENE = preload("res://scenes/shop/unit_tooltip.tscn")
const LEVEL_UP_VFX = preload("res://scenes/vfx/level_up_vfx.tscn")

var unit_instance: UnitInstance = null
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


func setup(unit: UnitInstance) -> void:
	unit_instance = unit
	
	if unit == null:
		if name_label:
			name_label.text = ""
		if character_texture:
			character_texture.texture = null
		if background:
			background.color = Color.WHITE # Reset to default or transparent
		return

	if name_label:
		name_label.text = unit.unit_name
	if character_texture and unit.unit_texture:
		character_texture.texture = unit.unit_texture
	elif background:
		background.color = Color.GRAY


func _get_drag_data(at_position: Vector2) -> Variant:
	if unit_instance == null:
		return null
	
	# Create drag preview with proper offset
	var preview = _create_drag_preview(at_position)
	set_drag_preview(preview)
	
	# Return different type based on location
	var drag_type = "shop_unit" if is_in_shop else "team_unit"
	return {
		"type": drag_type,
		"unit_data": unit_instance,
		"source": self
	}


func _create_drag_preview(at_position: Vector2) -> Control:
	# Fixed size for drag preview (larger to match shelf appearance)
	var preview_size = Vector2(100, 100)
	
	# Debug: print actual sizes
	# print("Creating preview - current size: ", size, " preview_size: ", preview_size, " custom_min: ", custom_minimum_size)
	
	# Create a simple Control container
	var preview = Control.new()
	
	# Calculate the scale ratio to properly offset the click position
	var scale_ratio = preview_size / size if size != Vector2.ZERO else Vector2.ONE
	var scaled_offset = at_position * scale_ratio
	
	if unit_instance.unit_texture:
		var tex_rect = TextureRect.new()
		tex_rect.texture = unit_instance.unit_texture
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Get texture size and calculate scale to fit in 50x50
		var tex_size = unit_instance.unit_texture.get_size()
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
		bg.color = Color.GRAY
		bg.position = -scaled_offset
		bg.modulate.a = 0.8
		preview.add_child(bg)
	
	return preview


func remove_from_shop() -> void:
	queue_free()


# Drop handling for team unit swapping and merging
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Only team slots can accept drops for swapping/merging
	if is_in_shop:
		return false
	
	# Accept team units for swapping
	# Accept team units for swapping
	if data is Dictionary:
		var type = data.get("type")
		
		# Swapping Logic
		if type == "team_unit":
			var source = data.get("source")
			# Don't swap with self
			if source != self:
				var source_data = data.get("unit_data")
				
				# Highlight for swap
				if background:
					background.modulate = Color(1.3, 1.3, 1.3)
					
					# Check for merge possibility (same unit name, same level, and not max level)
					if unit_instance and source_data and unit_instance.unit_name == source_data.unit_name and unit_instance.level == source_data.level and unit_instance.level < 2:
						background.modulate = Color(1.5, 1.5, 1.0) # Golden highlight for merge
						
				return true
				
		# Item Purchase Logic
		if type == "shop_item":
			var cost = data.get("cost", 999)
			# Check affordance
			if GameData.gold >= cost:
				if background:
					background.modulate = Color(1.2, 1.5, 1.2) # Greenish highlight
				return true
				
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.get("type") == "team_unit":
		var source_slot = data.get("source")
		var source_data = data.get("unit_data")
		
		if source_slot and source_slot != self:
			# Check for merge (same condition as can_drop)
			if unit_instance and source_data and unit_instance.unit_name == source_data.unit_name and unit_instance.level == source_data.level and unit_instance.level < 2:
				# Merge Logic
				var old_level = unit_instance.level
				unit_instance.add_xp(1)
				
				if unit_instance.level > old_level:
					_play_level_up_vfx()
				
				# Visual update for current slot
				setup(unit_instance)
				_reset_visual()
				
				# If tooltip is showing, update it
				if tooltip_instance and tooltip_instance.visible:
					tooltip_instance.show_unit(unit_instance)
				
				# Notify parent (TeamBoard) to remove source unit from data model
				merge_completed.emit(self, source_slot)
				return

			# Swap Request if not merged
			swap_requested.emit(source_slot, self)

	# Handle Item Purchase
	if data is Dictionary and data.get("type") == "shop_item":
		var item: ItemDefinition = data.get("item")
		var source_slot: Control = data.get("source")
		var cost = data.get("cost", 0)
		
		if item and source_slot and GameData.gold >= cost:
			# Execute item ability
			if item.item_effect:
				item.item_effect.execute(unit_instance)
				print("Item used: ", item.name, " on ", unit_instance.unit_name)
			
			# Spend gold
			GameData.spend_gold(cost)
			
			# Remove from shop
			source_slot.remove_from_shop()
			
			# Visual update
			_reset_visual()
			if tooltip_instance and tooltip_instance.visible:
				tooltip_instance.show_unit(unit_instance)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_reset_visual()


func _play_level_up_vfx() -> void:
	var vfx = LEVEL_UP_VFX.instantiate()
	# Add to main scene/root to ensure it's visible and not clipped by UI containers
	get_tree().root.add_child(vfx)
	vfx.global_position = global_position + (size / 2) # Center on slot
	vfx.z_index = 101 # High Z-index to render on top


func _reset_visual() -> void:
	if background:
		background.modulate = Color.WHITE


func _on_mouse_entered() -> void:
	if unit_instance == null:
		return
	
	# Create tooltip instance if not exists
	if tooltip_instance == null:
		tooltip_instance = TOOLTIP_SCENE.instantiate()
		# Add to root so it's on top of everything
		get_tree().root.add_child(tooltip_instance)
	
	# Update tooltip content
	tooltip_instance.show_unit(unit_instance)
	
	# Force update to get accurate size
	tooltip_instance.reset_size()
	
	# Calculate Position
	var slot_rect = get_global_rect()
	var viewport_rect = get_viewport().get_visible_rect()
	var tooltip_width = tooltip_instance.size.x
	
	# Default: To the right
	var final_x = slot_rect.end.x - 50
	
	# Check if it overflows right edge
	if final_x + tooltip_width > viewport_rect.size.x:
		# Flip to Left
		final_x = slot_rect.position.x - tooltip_width + 50
	
	tooltip_instance.global_position = Vector2(final_x, slot_rect.position.y + 10)


func _on_mouse_exited() -> void:
	if tooltip_instance:
		tooltip_instance.hide_tooltip()


func _exit_tree() -> void:
	# Clean up tooltip when slot is removed
	if tooltip_instance and is_instance_valid(tooltip_instance):
		tooltip_instance.queue_free()
