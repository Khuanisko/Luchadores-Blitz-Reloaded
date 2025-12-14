# shop.gd
# Main shop scene controller

extends Control

const UNIT_SLOT_SCENE = preload("res://scenes/shop/unit_slot.tscn")

# Currency
const STARTING_GOLD: int = 1000
const UNIT_COST: int = 3
const REROLL_COST: int = 1
const SELL_VALUE: int = 1
var gold: int = STARTING_GOLD

# Shop Data
@export var available_units_pool: Array[UnitDefinition] = []
var shop_units: Array[UnitInstance] = []

@onready var shop_container: HBoxContainer = $ShopContainer
@onready var shopkeeper: Control = $Shopkeeper
@onready var reroll_button: Button = $RerollButton
@onready var fight_button: Button = $FightButton
@onready var gold_label: Label = $GoldLabel
@onready var team_board: Control = $TeamBoard
@onready var hp_label: Label = $HUD/HPContainer/HPLabel
@onready var wins_label: Label = $HUD/WinsContainer/WinsLabel
@onready var round_label: Label = $HUD/RoundContainer/RoundLabel


func _ready() -> void:
	_ensure_pool_loaded()
	_generate_shop_items()
	_populate_shop_ui()
	_restore_team()
	_connect_signals()
	_update_gold_display()
	_update_fight_button()
	_update_hud()


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


func _on_unit_purchased(unit: UnitInstance, source_slot: Control) -> void:
	# Check if player can afford
	if gold < UNIT_COST:
		print("Not enough gold!")
		return
		
	# Check if team is full
	if team_board and team_board.is_full():
		print("Team is full!")
		return
	
	# Spend gold
	gold -= UNIT_COST
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
	if gold >= REROLL_COST:
		gold -= REROLL_COST
		_update_gold_display()
		_reroll_shop()
	else:
		print("Not enough gold for reroll!")


func _reroll_shop() -> void:
	_generate_shop_items()
	_populate_shop_ui()
	print("Shop rerolled!")


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "💰 %d" % gold
	# Update reroll button to show cost
	if reroll_button:
		reroll_button.text = "🎲 REROLL (-%d)" % REROLL_COST
		reroll_button.disabled = gold < REROLL_COST


func _on_unit_sold(unit: UnitInstance, _source_slot: Control) -> void:
	# Disconnect triggers
	unit.disconnect_shop_signals()
	
	# Add gold
	gold += SELL_VALUE
	_update_gold_display()
	_update_fight_button()
	print("Sold: ", unit.unit_name, " for ", SELL_VALUE, " gold")


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
