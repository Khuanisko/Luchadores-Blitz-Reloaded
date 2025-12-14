class_name UnitDefinition
extends Resource

@export_group("Identity")
@export var id: String = ""
@export var unit_name: String = "Luchador"
@export var portrait: Texture2D

@export_group("Stats")
@export var base_hp: int = 1
@export var base_attack: int = 1
@export var cost: int = 3
@export var sell_value: int = 1
@export var tier: int = 1

@export_group("Traits")
@export var unit_class: String = "Luchador" # e.g. Striker, Technician
@export var faction: String = "Independent"
@export_enum("Face", "Heel") var heel_face: String = "Face"

@export_group("Ability")
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""
@export var ability_resource: Resource
