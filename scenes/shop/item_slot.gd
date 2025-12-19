class_name ItemSlot
extends Control

signal purchased(item: ItemDefinition)

var item_definition: ItemDefinition

@onready var icon_rect: TextureRect = $Icon

func setup(item: ItemDefinition) -> void:
	item_definition = item
	if icon_rect:
		icon_rect.texture = item.icon
		
	# Tooltip handled by mouse signals

func _get_drag_data(at_position: Vector2) -> Variant:
	if not item_definition:
		return null
		
	var preview = _create_drag_preview(at_position)
	set_drag_preview(preview)
	
	return {
		"type": "shop_item",
		"item": item_definition,
		"source": self,
		"cost": item_definition.cost
	}

func _create_drag_preview(at_position: Vector2) -> Control:
	var preview = Control.new()
	var icon = TextureRect.new()
	icon.texture = item_definition.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Match slot size for preview visibility
	icon.size = Vector2(100, 100) 
	# Center the icon on the mouse cursor
	icon.position = -icon.size / 2
	preview.add_child(icon)
	return preview

func remove_from_shop() -> void:
	queue_free()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if icon_rect: icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS

# Simple tooltip (can be improved later)
func _make_custom_tooltip(for_text: String) -> Object:
	if not item_definition: return null
	var label = Label.new()
	label.text = "%s\nCost: %d\n%s" % [item_definition.name, item_definition.cost, item_definition.description]
	return label
