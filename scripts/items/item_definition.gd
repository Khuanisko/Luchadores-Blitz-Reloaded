class_name ItemDefinition
extends Resource

@export var id: String = ""
@export var name: String = "Item"
@export_multiline var description: String = ""
@export var cost: int = 3
@export var tier: int = 1
@export var icon: Texture2D

@export_group("Ability")
@export var item_effect: ItemEffect
