# unit_data.gd
# Resource class for unit data

class_name UnitData
extends Resource

@export var unit_name: String = "Fighter"
@export var unit_color: Color = Color.RED
@export var unit_texture: Texture2D = null
@export var hp: int = 1
@export var max_hp: int = 1
@export var attack: int = 1
@export var cost: int = 3
@export var tier: int = 1

# New tooltip fields
@export var unit_class: String = "Luchador"
@export var faction: String = "Independent"
@export var heel_face: String = "Face" # "Face" (Good) or "Heel" (Bad)
@export var ability_name: String = "Basic Strike"
@export_multiline var ability_description: String = "Deals damage to the opponent."

const TIER_NAMES = {
	1: "Backyard",
	2: "Garage",
	3: "Indie",
	4: "Superstar",
	5: "Main Event",
	6: "Hall of Fame"
}

func get_tier_name() -> String:
	return TIER_NAMES.get(tier, "Tier " + str(tier))


@export var level: int = 1
@export var xp: int = 0
@export var max_xp: int = 2

func add_xp(amount: int) -> void:
	if level >= 2:
		return
		
	xp += amount
	if xp >= max_xp:
		level_up()

func level_up() -> void:
	xp -= max_xp
	level += 1
	# Increase stats on level up (doubling stats)
	max_hp *= 2
	hp = max_hp # Heal on level up
	attack *= 2
	# Cap at level 2 - prevent further xp gain happens in add_xp

	# Increase requirement for next level if needed, or cap level
	# For now, let's keep max_xp at 2 for all levels as per request description
