# unit_data.gd
# Resource class for unit data

class_name UnitData
extends Resource

@export var unit_name: String = "Fighter"
@export var unit_color: Color = Color.RED
@export var unit_texture: Texture2D = null
@export var hp: int = 1
@export var attack: int = 1
@export var cost: int = 3

@export var level: int = 1
@export var xp: int = 0
@export var max_xp: int = 2

func add_xp(amount: int) -> void:
	xp += amount
	if xp >= max_xp:
		level_up()

func level_up() -> void:
	xp -= max_xp
	level += 1
	# Increase stats on level up (doubling stats)
	hp *= 2
	attack *= 2
	# Increase requirement for next level if needed, or cap level
	# For now, let's keep max_xp at 2 for all levels as per request description
	# "jak przeciagniemy druga to sie ulepsza na 2 lvl" implies simple 1->2 flow.
	# But typically it scales. Let's stick to the request: "na ulepszenia na 2 poziom potrzebne sa jescze 2 dodatkowe takie same jednostki"
