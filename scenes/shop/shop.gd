# shop.gd
# Main shop scene controller

extends Control

const UNIT_SLOT_SCENE = preload("res://scenes/shop/unit_slot.tscn")
const MANAGER_TOOLTIP_SCENE = preload("res://scenes/managers/manager_tooltip.tscn")

# Currency
const STARTING_GOLD: int = 1000
const UNIT_COST: int = 3
const REROLL_COST: int = 1
# Gold moved to GameData

# Shop Data
@export var available_units_pool: Array[UnitDefinition] = []
var shop_units: Array[UnitInstance] = []
var previous_gold: int = 1000

@onready var shop_container: HBoxContainer = $ShopContainer
@onready var shopkeeper: Control = $Shopkeeper
@onready var reroll_button: Button = $RerollButton
@onready var fight_button: Button = $FightButton
@onready var gold_label: Label = $GoldLabel
@onready var team_board: Control = $TeamBoard
@onready var hp_label: Label = $HUD/HPContainer/HPLabel
@onready var wins_label: Label = $HUD/WinsContainer/WinsLabel
@onready var round_label: Label = $HUD/RoundContainer/RoundLabel
@onready var manager_icon: TextureButton = $ManagerIcon

var manager_tooltip: Control


func _ready() -> void:
	GameData.reset_gold()
	previous_gold = GameData.gold
	_ensure_pool_loaded()
	_generate_shop_items()
	_populate_shop_ui()
	_restore_team()
	_connect_signals()
	_update_gold_display()
	_update_fight_button()
	_update_hud()
	_setup_manager_icon()
	_apply_don_casino_ability()



func _ensure_pool_loaded() -> void:
	if not available_units_pool.is_empty():
		return
		
	# Fallback: Load known units if none assigned in inspector
	var unit_ids = ["gonzales", "dolores", "marco", "eljaguarro", "eltorro"]
	for id in unit_ids:
		var path = "res://resources/units/" + id + ".tres"
		if ResourceLoader.exists(path):
			available_units_pool.append(load(path))


func _restore_team() -> void:
	if GameData.player_team.is_empty():
		return
		
	if team_board:
		for unit in GameData.player_team:
			# Fully heal unit before adding back to board
			unit.hp = unit.max_hp
			team_board.add_unit(unit)
			unit.connect_shop_signals()


func _generate_shop_items() -> void:
	shop_units.clear()
	
	if available_units_pool.is_empty():
		return

	# Create 5 random units
	for i in range(5):
		var def = available_units_pool.pick_random()
		var unit = UnitInstance.new(def)
		shop_units.append(unit)


func _populate_shop_ui() -> void:
	# Clear existing slots
	for child in shop_container.get_children():
		child.queue_free()

	for unit_instance in shop_units:
		var slot = UNIT_SLOT_SCENE.instantiate()
		shop_container.add_child(slot)
		slot.setup(unit_instance)


func _connect_signals() -> void:
	if shopkeeper:
		shopkeeper.unit_purchased.connect(_on_unit_purchased)
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
	if fight_button:
		fight_button.pressed.connect(_on_fight_pressed)
	if team_board:
		team_board.unit_sold.connect(_on_unit_sold)
	
	GameData.gold_changed.connect(_on_gold_changed)


func _on_unit_purchased(unit: UnitInstance, source_slot: Control) -> void:
	# Check if player can afford
	if GameData.gold < UNIT_COST:
		print("Not enough gold!")
		return
		
	# Check if team is full
	if team_board and team_board.is_full():
		print("Team is full!")
		return
	
	# Spend gold
	GameData.spend_gold(UNIT_COST)
	_update_gold_display()
	
	# Add unit to team board
	if team_board:
		team_board.add_unit(unit)
		
		# Connect triggers for the new team member
		unit.connect_shop_signals()
		
		# Notify potential listeners (other team members)
		GameData.unit_purchased.emit(unit)
	
	# Remove the slot from shop
	if source_slot:
		source_slot.remove_from_shop()
	
	_update_fight_button()
	print("Purchased: ", unit.unit_name, " for ", UNIT_COST, " gold")


func _on_reroll_pressed() -> void:
	if GameData.gold >= REROLL_COST:
		GameData.spend_gold(REROLL_COST)
		_update_gold_display()
		_reroll_shop()
	else:
		print("Not enough gold for reroll!")


func _reroll_shop() -> void:
	_generate_shop_items()
	_populate_shop_ui()
	print("Shop rerolled!")


func _on_gold_changed(new_amount: int) -> void:
	var diff = new_amount - previous_gold
	previous_gold = new_amount
	
	if diff != 0:
		_show_gold_indicator(diff)
		
	_update_gold_display()


func _show_gold_indicator(amount: int) -> void:
	if not gold_label: return
	
	var label = Label.new()
	var text = str(amount)
	var color = Color.GREEN
	
	if amount > 0:
		text = "+" + text
	else:
		color = Color.RED
		
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 24)
	
	# Position below/near the gold label
	# Since gold_label might be in a container, we add this to the Shop root or a known container
	# and use global position.
	add_child(label)
	label.global_position = gold_label.global_position + Vector2(20, 30) # Offset below
	
	# Animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 30, 1.0).from_current()
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "💰 %d" % GameData.gold
	# Update reroll button to show cost
	if reroll_button:
		reroll_button.text = "🎲 REROLL (-%d)" % REROLL_COST
		reroll_button.disabled = GameData.gold < REROLL_COST


func _on_unit_sold(unit: UnitInstance, _source_slot: Control) -> void:
	# Disconnect triggers
	unit.disconnect_shop_signals()
	
	# Add gold
	var profit = unit.sell_value
	GameData.gain_gold(profit)
	_update_gold_display()
	_update_fight_button()
	print("Sold: ", unit.unit_name, " for ", profit, " gold")


func _update_fight_button() -> void:
	if fight_button and team_board:
		var has_units = not team_board.team_units.is_empty()
		fight_button.disabled = not has_units
		if has_units:
			fight_button.text = "FIGHT"
		else:
			fight_button.text = "NO TEAM"


func _on_fight_pressed() -> void:
	# Safety check - don't allow fight with empty team
	if team_board and team_board.team_units.is_empty():
		return
	
	if team_board:
		GameData.player_team = team_board.team_units.duplicate()
	
	GameData.generate_enemy_team()
	
	# Transition to battle arena
	get_tree().change_scene_to_file("res://scenes/battle/battle_arena.tscn")


func _update_hud() -> void:
	if hp_label:
		hp_label.text = str(GameData.player_lives)
	if wins_label:
		wins_label.text = str(GameData.player_wins)
	if round_label:
		round_label.text = str(GameData.current_round)


func _setup_manager_icon() -> void:
	if not manager_icon:
		return
		
	if GameData.selected_manager:
		var manager = GameData.selected_manager
		if manager.button_icon:
			manager_icon.texture_normal = manager.button_icon
		manager_icon.mouse_entered.connect(_on_manager_icon_mouse_entered)
		manager_icon.mouse_exited.connect(_on_manager_icon_mouse_exited)
		manager_icon.visible = true
	else:
		manager_icon.visible = false


func _on_manager_icon_mouse_entered() -> void:
	if not GameData.selected_manager:
		return
	
	if manager_tooltip:
		manager_tooltip.queue_free()
	
	manager_tooltip = MANAGER_TOOLTIP_SCENE.instantiate()
	add_child(manager_tooltip)
	
	if manager_tooltip.has_method("show_manager"):
		manager_tooltip.show_manager(GameData.selected_manager, false)


func _on_manager_icon_mouse_exited() -> void:
	if manager_tooltip:
		manager_tooltip.queue_free()
		manager_tooltip = null


func _process(_delta: float) -> void:
	if manager_tooltip:
		manager_tooltip.global_position = get_global_mouse_position() + Vector2(20, 20)
		
		# Keep inside screen
		var viewport_rect = get_viewport_rect()
		var tooltip_rect = manager_tooltip.get_global_rect()
		
		if tooltip_rect.end.x > viewport_rect.size.x:
			manager_tooltip.global_position.x -= tooltip_rect.size.x + 40
		if tooltip_rect.end.y > viewport_rect.size.y:
			manager_tooltip.global_position.y -= tooltip_rect.size.y + 40


func _apply_don_casino_ability() -> void:
	if not GameData.selected_manager:
		return
	if GameData.selected_manager.id != "don_casino":
		return
	
	# Even rounds only (2, 4, 6...)
	if GameData.current_round % 2 != 0:
		return
	
	# If team is full, give 1 gold instead
	if team_board.is_full():
		GameData.gain_gold(1)
		print("[Don Casino] Team full - gained 1 gold")
		return
	
	# Get random unit from player's tier
	var tier_units = available_units_pool.filter(
		func(u): return u.tier == GameData.player_tier
	)
	if tier_units.is_empty():
		return
	
	var random_unit = tier_units.pick_random()
	var unit = UnitInstance.new(random_unit)
	team_board.add_unit(unit)
	unit.connect_shop_signals()
	print("[Don Casino] Free unit: ", unit.unit_name)
