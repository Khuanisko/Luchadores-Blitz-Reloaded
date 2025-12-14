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

var tier: int:
	get: return definition.tier if definition else 1

var unit_class: String:
	get: return definition.unit_class if definition else "Unknown"

var faction: String:
	get: return definition.faction if definition else "Unknown"

var heel_face: String:
	get: return definition.heel_face if definition else "Face"

var ability_name: String:
	get: return definition.ability_name if definition else ""

var ability_description: String:
	get: return definition.ability_description if definition else ""


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
	# Increase stats on level up (doubling stats pattern from previous code)
	max_hp *= 2
	hp = max_hp # Heal on level up
	attack *= 2


# --- Ability System (Shop Phase) ---

func connect_shop_signals() -> void:
	if not GameData.unit_purchased.is_connected(_on_global_unit_purchased):
		GameData.unit_purchased.connect(_on_global_unit_purchased)

func disconnect_shop_signals() -> void:
	if GameData.unit_purchased.is_connected(_on_global_unit_purchased):
		GameData.unit_purchased.disconnect(_on_global_unit_purchased)

func _on_global_unit_purchased(bought_unit: UnitInstance) -> void:
	if bought_unit == self: return # Don't trigger on self buy (or do? Definition says "When you buy a unit")
	# Usually "buy another unit". Let's assume another unit for now.
	
	# Gonzales: Faction Bond
	if definition and definition.id == "gonzales":
		if bought_unit.faction == self.faction:
			_apply_faction_bond()

func _apply_faction_bond() -> void:
	print("Faction Bond Triggered for Gonzales!")
	max_hp += 1
	hp += 1

