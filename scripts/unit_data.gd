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
