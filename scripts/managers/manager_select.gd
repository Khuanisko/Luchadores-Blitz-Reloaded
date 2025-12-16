extends Control

@onready var select_button: Button = $SelectButton
@onready var container: HBoxContainer = $ManagersContainer

var selected_manager: ManagerDefinition
var manager_cards: Array[TextureRect] = []

# Hardcoded for simplicity as per plan, but could be dynamic
var managers_data = [
	preload("res://resources/managers/david_king.tres"),
	preload("res://resources/managers/don_casino.tres"),
	preload("res://resources/managers/the_promotor.tres")
]
const TOOLTIP_SCENE = preload("res://scenes/managers/manager_tooltip.tscn")
var current_tooltip: Control

func _ready() -> void:
	select_button.disabled = true
	select_button.pressed.connect(_on_select_pressed)
	
	# Clear placeholder children if any
	for child in container.get_children():
		child.queue_free()
		
	# Create cards
	for manager_def in managers_data:
		var card = _create_manager_card(manager_def)
		container.add_child(card)
		manager_cards.append(card)

func _create_manager_card(definition: ManagerDefinition) -> TextureRect:
	var tex_rect = TextureRect.new()
	tex_rect.texture = definition.portrait
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.custom_minimum_size = Vector2(300, 500) # Ensure size
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Enable input
	tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	tex_rect.gui_input.connect(_on_card_input.bind(tex_rect, definition))
	tex_rect.mouse_entered.connect(_on_card_mouse_entered.bind(definition))
	tex_rect.mouse_exited.connect(_on_card_mouse_exited)
	
	# Add a border or visual indicator (using a child ColorRect as selection overlay)
	var overlay = ColorRect.new()
	overlay.name = "SelectionOverlay"
	overlay.color = Color(1, 1, 0, 0.3) # Yellow transparent
	overlay.visible = false
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.add_child(overlay)
	
	return tex_rect

func _on_card_input(event: InputEvent, card: TextureRect, definition: ManagerDefinition) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_manager(card, definition)

func _on_card_mouse_entered(definition: ManagerDefinition) -> void:
	if current_tooltip:
		current_tooltip.queue_free()
	
	current_tooltip = TOOLTIP_SCENE.instantiate()
	add_child(current_tooltip)
	
	if current_tooltip.has_method("show_manager"):
		current_tooltip.show_manager(definition)
	
	# Position tooltip (follow mouse or fixed)
	# Let's put it near the mouse but with offset
	current_tooltip.global_position = get_global_mouse_position() + Vector2(20, 20)

func _on_card_mouse_exited() -> void:
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null

func _process(_delta: float) -> void:
	if current_tooltip:
		current_tooltip.global_position = get_global_mouse_position() + Vector2(20, 20)
		
		# Keep inside screen
		var viewport_rect = get_viewport_rect()
		var tooltip_rect = current_tooltip.get_global_rect()
		
		if tooltip_rect.end.x > viewport_rect.size.x:
			current_tooltip.global_position.x -= tooltip_rect.size.x + 40
		if tooltip_rect.end.y > viewport_rect.size.y:
			current_tooltip.global_position.y -= tooltip_rect.size.y + 40

func _select_manager(selected_card: TextureRect, definition: ManagerDefinition) -> void:
	selected_manager = definition
	select_button.disabled = false
	
	# Update visuals
	for card in manager_cards:
		var overlay = card.get_node("SelectionOverlay")
		if card == selected_card:
			overlay.visible = true
			card.modulate = Color.WHITE
		else:
			overlay.visible = false
			card.modulate = Color(0.7, 0.7, 0.7) # Dim others

func _on_select_pressed() -> void:
	if selected_manager:
		GameData.selected_manager = selected_manager
		# Transition to Shop
		get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")
