class_name UnitInstance
extends Resource

@export var definition: UnitDefinition

# Runtime Stats
@export var hp: int
@export var max_hp: int
@export var attack: int
@export var level: int = 1
@export var xp: int = 0
@export var max_xp: int = 2

# Temporary Abilities (Items)
var temporary_abilities: Array[Resource] = []
var equipped_items: Array[String] = []

# Helper to get tier name
const TIER_NAMES = {
	1: "Backyard",
	2: "Garage",
	3: "Gym",
	4: "Arena",
	5: "Hall of Fame"
}

# Proxy Properties for convenience (read-only from definition)
var unit_name: String:
	get: return definition.unit_name if definition else "Unknown"

var unit_texture: Texture2D:
	get: return definition.portrait if definition else null

var cost: int:
	get: return definition.cost if definition else 0

var sell_value: int:
	get: return (definition.sell_value * level) if definition else 0

var tier: int:
	get: return definition.tier if definition else 1

var unit_class: String:
	get: return BattleTypes.get_class_name(definition.unit_class) if definition else "Unknown"

var faction: String:
	get: return BattleTypes.get_faction_name(definition.faction) if definition else "Unknown"

var heel_face: String:
	get: return definition.heel_face if definition else "Face"

var ability_name: String:
	get: return definition.ability_name if definition else ""

var ability_description: String:
	get: 
		var desc = definition.ability_description if definition else ""
		
		# Resource-based description
		if definition and definition.ability_resource:
			if definition.ability_resource.has_method("get_description"):
				return definition.ability_resource.get_description(level, desc)
				
		# Fallback / Built-in handling (e.g. El Doblon Sell Value)
		if definition and definition.sell_value > 0 and "Sells for" in desc:
			# El Doblon pattern: "Sells for [b] 3 [/b] gold"
			# We want to replace the base sell value with calculated sell_value
			# Pattern: Find the base value string.
			var base_val = definition.sell_value
			var current_val = sell_value # This uses the getter which scales with level
			
			# Try to replace "[b] X [/b]" or just "X"
			return desc.replace("[b] " + str(base_val) + " [/b]", "[b] " + str(current_val) + " [/b]") \
				.replace(str(base_val), str(current_val))
		
		# Append Item descriptions
		if not temporary_abilities.is_empty():
			desc += "\n[color=yellow]Items:[/color]"
			for ab in temporary_abilities:
				if ab.has_method("get_description"):
					desc += "\n" + ab.get_description(1, "Item Ability") # Items usually level 1?
				
		return desc


func _init(p_definition: UnitDefinition = null) -> void:
	if p_definition:
		definition = p_definition
		# Initialize runtime stats from definition
		max_hp = definition.base_hp
		hp = max_hp
		attack = definition.base_attack
		level = 1
		xp = 0
		max_xp = 2 # Fixed for now as per previous logic

func get_tier_name() -> String:
	return TIER_NAMES.get(tier, "Tier " + str(tier))

func add_xp(amount: int) -> void:
	if level >= 2:
		return
		
	xp += amount
	if xp >= max_xp:
		level_up()

func level_up() -> void:
	xp -= max_xp
	level += 1
	# Increase stats on level up (+1/+1 per level)
	max_hp += 1
	hp = max_hp # Heal on level up
	attack += 1


func add_temporary_ability(ability: Resource) -> void:
	if ability and not ability in temporary_abilities:
		temporary_abilities.append(ability)

func add_equipped_item(item_name: String) -> void:
	equipped_items.append(item_name)

func clear_temporary_abilities() -> void:
	temporary_abilities.clear()
	equipped_items.clear()


# --- Ability System (Shop Phase) ---

func connect_shop_signals() -> void:
	if not GameData.unit_purchased.is_connected(_on_global_unit_purchased):
		GameData.unit_purchased.connect(_on_global_unit_purchased)
	if not GameData.gold_earned.is_connected(_on_gold_earned):
		GameData.gold_earned.connect(_on_gold_earned)

func disconnect_shop_signals() -> void:
	if GameData.unit_purchased.is_connected(_on_global_unit_purchased):
		GameData.unit_purchased.disconnect(_on_global_unit_purchased)
	if GameData.gold_earned.is_connected(_on_gold_earned):
		GameData.gold_earned.disconnect(_on_gold_earned)

func _on_global_unit_purchased(bought_unit: UnitInstance) -> void:
	if bought_unit == self: return 
	
	# Resource-based Ability Trigger
	if definition and definition.ability_resource:
		if definition.ability_resource.has_method("execute"):
			# Pass context
			var context = { "trigger": "unit_purchased", "bought_unit": bought_unit }
			definition.ability_resource.execute(self, context)

func _on_gold_earned(_amount: int) -> void:
	if definition and definition.ability_resource:
		if definition.ability_resource.has_method("execute"):
			var context = { "trigger": "gold_earned", "amount": _amount }
			definition.ability_resource.execute(self, context)
