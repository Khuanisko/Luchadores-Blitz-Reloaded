# shop.gd
# Main shop scene controller

extends Control

const UNIT_SLOT_SCENE = preload("res://scenes/shop/unit_slot.tscn")

# Currency
const STARTING_GOLD: int = 10
const UNIT_COST: int = 3
const REROLL_COST: int = 1
const SELL_VALUE: int = 1
var gold: int = STARTING_GOLD

# Sample units for the shop
var available_units: Array[UnitData] = []
var team_units: Array[UnitData] = []

@onready var shop_container: HBoxContainer = $ShopContainer
@onready var shopkeeper: Control = $Shopkeeper
@onready var reroll_button: Button = $RerollButton
@onready var sell_zone: Control = $SellZone
@onready var gold_label: Label = $GoldLabel
@onready var team_container: HBoxContainer = $TeamContainer
@onready var team_label: Label = $TeamLabel


func _ready() -> void:
	_create_sample_units()
	_populate_shop()
	_connect_signals()
	_update_gold_display()


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
	if sell_zone:
		sell_zone.unit_sold.connect(_on_unit_sold)


func _on_unit_purchased(unit_data: UnitData, source_slot: Control) -> void:
	# Check if player can afford
	if gold < UNIT_COST:
		print("Not enough gold!")
		return
	
	# Spend gold
	gold -= UNIT_COST
	_update_gold_display()
	
	# Add unit to team
	team_units.append(unit_data)
	
	# Remove the slot from shop
	if source_slot:
		source_slot.remove_from_shop()
	
	# Update team display
	_update_team_display()
	
	print("Purchased: ", unit_data.unit_name, " for ", UNIT_COST, " gold")


func _update_team_display() -> void:
	# Clear existing team display
	for child in team_container.get_children():
		child.queue_free()
	
	# Add all team units
	for i in range(team_units.size()):
		var unit_data = team_units[i]
		var team_slot = UNIT_SLOT_SCENE.instantiate()
		team_container.add_child(team_slot)
		team_slot.setup(unit_data)
		# Mark as team unit (can drag for swapping, but not for buying)
		team_slot.is_in_shop = false
		# Connect swap signal
		team_slot.swap_requested.connect(_on_swap_requested)
	
	# Update label
	team_label.text = "Twoja Drużyna (%d)" % team_units.size()


func _on_swap_requested(from_slot: Control, to_slot: Control) -> void:
	# Find indices of both slots
	var from_index = from_slot.get_index()
	var to_index = to_slot.get_index()
	
	if from_index >= 0 and to_index >= 0 and from_index < team_units.size() and to_index < team_units.size():
		# Swap in data array
		var temp = team_units[from_index]
		team_units[from_index] = team_units[to_index]
		team_units[to_index] = temp
		
		# Update display
		_update_team_display()
		print("Swapped positions: ", from_index, " <-> ", to_index)


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


func _on_unit_sold(unit_data: UnitData, source_slot: Control) -> void:
	# Find and remove unit from team
	var slot_index = source_slot.get_index()
	if slot_index >= 0 and slot_index < team_units.size():
		team_units.remove_at(slot_index)
		
		# Add gold
		gold += SELL_VALUE
		_update_gold_display()
		
		# Update team display
		_update_team_display()
		
		print("Sold: ", unit_data.unit_name, " for ", SELL_VALUE, " gold")
