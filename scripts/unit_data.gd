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
