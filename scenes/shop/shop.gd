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

# Sample units for the shop
var available_units: Array[UnitData] = []

@onready var shop_container: HBoxContainer = $ShopContainer
@onready var shopkeeper: Control = $Shopkeeper
@onready var reroll_button: Button = $RerollButton
@onready var fight_button: Button = $FightButton
@onready var gold_label: Label = $GoldLabel
@onready var team_board: Control = $TeamBoard


func _ready() -> void:
	_create_sample_units()
	_populate_shop()
	_restore_team()
	_connect_signals()
	_update_gold_display()
	_update_fight_button()


func _restore_team() -> void:
	if GameData.player_team.is_empty():
		return
		
	if team_board:
		for unit_data in GameData.player_team:
			# Fully heal unit before adding back to board
			unit_data.hp = unit_data.max_hp
			team_board.add_unit(unit_data)


func _create_sample_units() -> void:
	# Load units from character box textures
	var character_files = [
		"dolores",
		"eljaguarro",
		"eltorro",
		"gonzales",
		"marco"
	]
	
	for char_name in character_files:
		var texture_path = "res://assets/sprites/character_boxes/" + char_name + ".png"
		var texture = load(texture_path) as Texture2D
		
		var unit = UnitData.new()
		unit.unit_name = char_name.capitalize()
		unit.unit_texture = texture
		unit.unit_color = Color.WHITE  # Fallback color
		
		# Load stats from database
		var stats = CharacterStats.get_stats(char_name)
		unit.hp = stats.hp
		unit.max_hp = stats.hp
		unit.attack = stats.attack
		unit.cost = stats.cost
		
		available_units.append(unit)


func _populate_shop() -> void:
	for unit_data in available_units:
		var slot = UNIT_SLOT_SCENE.instantiate()
		shop_container.add_child(slot)
		slot.setup(unit_data)


func _connect_signals() -> void:
	if shopkeeper:
		shopkeeper.unit_purchased.connect(_on_unit_purchased)
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
	if fight_button:
		fight_button.pressed.connect(_on_fight_pressed)
	if team_board:
		team_board.unit_sold.connect(_on_unit_sold)


func _on_unit_purchased(unit_data: UnitData, source_slot: Control) -> void:
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
		team_board.add_unit(unit_data)
	
	# Remove the slot from shop
	if source_slot:
		source_slot.remove_from_shop()
	
	_update_fight_button()
	print("Purchased: ", unit_data.unit_name, " for ", UNIT_COST, " gold")


func _on_reroll_pressed() -> void:
	if gold >= REROLL_COST:
		gold -= REROLL_COST
		_update_gold_display()
		_reroll_shop()
	else:
		print("Not enough gold for reroll!")


func _reroll_shop() -> void:
	# Clear current shop
	for child in shop_container.get_children():
		child.queue_free()
	
	# Generate new random units
	available_units.clear()
	_create_sample_units()
	
	# Shuffle the units
	available_units.shuffle()
	
	# Populate shop with shuffled units
	_populate_shop()
	print("Shop rerolled!")


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "💰 %d" % gold
	# Update reroll button to show cost
	if reroll_button:
		reroll_button.text = "🎲 REROLL (-%d)" % REROLL_COST
		reroll_button.disabled = gold < REROLL_COST


func _on_unit_sold(unit_data: UnitData, _source_slot: Control) -> void:
	# Add gold
	gold += SELL_VALUE
	_update_gold_display()
	_update_fight_button()
	print("Sold: ", unit_data.unit_name, " for ", SELL_VALUE, " gold")


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
