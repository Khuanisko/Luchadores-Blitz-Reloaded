# shop.gd
# Main shop scene controller

extends Control

const UNIT_SLOT_SCENE = preload("res://scenes/shop/unit_slot.tscn")
const ITEM_SLOT_SCENE = preload("res://scenes/shop/item_slot.tscn")
const MANAGER_TOOLTIP_SCENE = preload("res://scenes/managers/manager_tooltip.tscn")

# Currency
const STARTING_GOLD: int = 1000
const UNIT_COST: int = 3
const REROLL_COST: int = 1
# Gold moved to GameData

# Shop Data
@export var available_units_pool: Array[UnitDefinition] = []
@export var available_items_pool: Array[ItemDefinition] = []
var shop_units: Array[UnitInstance] = []
var shop_items: Array[ItemDefinition] = []
var previous_gold: int = 1000

@onready var shop_container: HBoxContainer = $ShopContainer
@onready var item_container: HBoxContainer = $ItemContainer
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
	_ensure_item_pool_loaded()
	_generate_shop_items()
	_populate_shop_ui()
	_restore_team()
	_connect_signals()
	_update_gold_display()
	_update_fight_button()
	_update_hud()
	_setup_manager_icon()
	_apply_manager_effects()



const TIER_PROBABILITIES = {
	"1-2":   {1: 100, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
	"3-4":   {1: 60,  2: 40, 3: 0, 4: 0, 5: 0, 6: 0},
	"5-6":   {1: 35,  2: 40, 3: 25, 4: 0, 5: 0, 6: 0},
	"7-8":   {1: 25,  2: 30, 3: 30, 4: 15, 5: 0, 6: 0},
	"9-10":  {1: 20,  2: 25, 3: 30, 4: 20, 5: 5, 6: 0},
	"11+":   {1: 15,  2: 20, 3: 25, 4: 25, 5: 10, 6: 5}
}

var tier_pools: Dictionary = {}
var current_tier_chances: Dictionary = {}
var current_tier_level: int = 1

func _ensure_pool_loaded() -> void:
	if not available_units_pool.is_empty() and not tier_pools.is_empty():
		return
		
	# Fallback: Load known units if none assigned in inspector
	if available_units_pool.is_empty():
		var unit_ids = ["gonzales", "dolores", "marco", "eljaguarro", "eltorro", "littledave", "elbarril", "eldoblon", "eltornado", "lavibora", "perrorabioso"] # Added more known units
		for id in unit_ids:
			var path = "res://resources/units/" + id + ".tres"
			if ResourceLoader.exists(path):
				available_units_pool.append(load(path))
	
	# Organize into tiers
	tier_pools.clear()
	for unit_def in available_units_pool:
		var t = unit_def.tier
		if not tier_pools.has(t):
			tier_pools[t] = []
		tier_pools[t].append(unit_def)
		
	# print("Tier Pools organized: ", tier_pools.keys())

func _ensure_item_pool_loaded() -> void:
	if not available_units_pool.is_empty(): # Bug in original check, but let's keep it safe
		if not available_items_pool.is_empty(): return
	
	var item_ids = ["burrito", "steel_chair", "jalapeno", "poster"]
	for id in item_ids:
		var path = "res://resources/items/" + id + ".tres"
		if ResourceLoader.exists(path):
			available_items_pool.append(load(path))


func _restore_team() -> void:
	if GameData.player_team.is_empty():
		return
		
	if team_board:
		for unit in GameData.player_team:
			# Fully heal unit before adding back to board
			unit.hp = unit.max_hp
			
			# Clear temporary abilities (from items)
			unit.clear_temporary_abilities()
			
			team_board.add_unit(unit)
			unit.connect_shop_signals()


func _generate_shop_items() -> void:
	shop_units.clear()
	
	_ensure_pool_loaded() # Ensure organized
	
	if available_units_pool.is_empty():
		return

	# Determine Probabilities and Max Tier based on Round
	var round_num = GameData.current_round
	var chances = {}
	var unlocked_tier = 1
	
	if round_num <= 2:
		chances = TIER_PROBABILITIES["1-2"]
		unlocked_tier = 1
	elif round_num <= 4:
		chances = TIER_PROBABILITIES["3-4"]
		unlocked_tier = 2
	elif round_num <= 6:
		chances = TIER_PROBABILITIES["5-6"]
		unlocked_tier = 3
	elif round_num <= 8:
		chances = TIER_PROBABILITIES["7-8"]
		unlocked_tier = 4
	elif round_num <= 10:
		chances = TIER_PROBABILITIES["9-10"]
		unlocked_tier = 5
	else:
		chances = TIER_PROBABILITIES["11+"]
		unlocked_tier = 6
		
	current_tier_chances = chances
	current_tier_level = unlocked_tier
	
	_update_tier_ui() # We'll implement this next call

	# Create 5 random units based on weights
	for i in range(5):
		var rolled_tier = _roll_tier(chances)
		var attempts = 3
		var unit_def: UnitDefinition = null
		
		# Try to find a unit in the rolled tier (or fallback)
		while attempts > 0:
			if tier_pools.has(rolled_tier) and not tier_pools[rolled_tier].is_empty():
				unit_def = tier_pools[rolled_tier].pick_random()
				break
			else:
				# Fallback to lower tier if pool empty
				rolled_tier = max(1, rolled_tier - 1)
				attempts -= 1
		
		# Absolute fallback
		if not unit_def:
			unit_def = available_units_pool.pick_random()
			
		var unit = UnitInstance.new(unit_def)
		shop_units.append(unit)

	# Generate Items (Max 2)
	shop_items.clear()
	if not available_items_pool.is_empty():
		for i in range(2):
			# 50% chance to spawn an item? Or always max 2?
			# Requirements: "Itemy beda pojawiac sie w sklepie na drugiej polce (...) maksymalnie 2 itemy"
			# Let's say always 2 for now to make testing easier, or randomly 1-2.
			var item = available_items_pool.pick_random()
			shop_items.append(item)
			
			
func _roll_tier(chances: Dictionary) -> int:
	var roll = randi() % 100 + 1 # 1-100
	var cumulative = 0
	
	for t in range(1, 7): # Tiers 1-6
		if chances.has(t):
			cumulative += chances[t]
			if roll <= cumulative:
				return t
	
	return 1 # Fallback


func _populate_shop_ui() -> void:
	# Clear existing slots
	for child in shop_container.get_children():
		child.queue_free()

	for unit_instance in shop_units:
		var slot = UNIT_SLOT_SCENE.instantiate()
		shop_container.add_child(slot)
		slot.setup(unit_instance)

	# Populate Items
	if item_container:
		for child in item_container.get_children():
			child.queue_free()
			
		for item_def in shop_items:
			var slot = ITEM_SLOT_SCENE.instantiate()
			item_container.add_child(slot)
			slot.setup(item_def)


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
	
	if not GameData.reroll_shop_requested.is_connected(_reroll_shop):
		GameData.reroll_shop_requested.connect(_reroll_shop)


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
		
		# Apply "Poster" buff if active
		if GameData.next_purchase_stats.hp > 0 or GameData.next_purchase_stats.attack > 0:
			unit.max_hp += GameData.next_purchase_stats.hp
			unit.hp += GameData.next_purchase_stats.hp
			unit.attack += GameData.next_purchase_stats.attack
			print("Poster Buff Applied: +%d HP, +%d Attack" % [GameData.next_purchase_stats.hp, GameData.next_purchase_stats.attack])
			
			# Reset buff
			GameData.next_purchase_stats = { "hp": 0, "attack": 0 }
		
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


func _apply_manager_effects() -> void:
	if not GameData.selected_manager:
		return
		
	if GameData.selected_manager.ability_script:
		var ability = GameData.selected_manager.ability_script.new()
		if ability.has_method("execute_shop_round_start"):
			ability.execute_shop_round_start(self)


func _update_tier_ui() -> void:
	var label_name = "TierLabel"
	var label = get_node_or_null(label_name)
	
	if not label:
		label = Label.new()
		label.name = label_name
		add_child(label)
		# Position at top center
		label.anchors_preset = Control.PRESET_TOP_WIDE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position.y = 80 # Below top bar
		label.add_theme_font_size_override("font_size", 36)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		label.add_theme_constant_override("outline_size", 6)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	label.text = "Current Tier: %d" % current_tier_level
	label.modulate.a = 1.0
	label.visible = true
	
	# Unique Tween for this label
	var tween = create_tween()
	tween.tween_interval(2.0) # Wait 2 seconds
	tween.tween_property(label, "modulate:a", 0.0, 1.5) # Fade out over 1.5s
	tween.tween_callback(func(): label.visible = false)
