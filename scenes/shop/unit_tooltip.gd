# unit_tooltip.gd
# Tooltip displaying unit stats on hover

extends Control

@onready var name_label: Label = $NameLabel
@onready var hp_label: Label = $HeartIcon/Label
@onready var attack_label: Label = $FistIcon/Label
@onready var cost_label: Label = $CostLabel

func show_unit(unit_data) -> void:
	if unit_data == null:
		return
	
	if name_label:
		name_label.text = unit_data.unit_name
	
	if hp_label:
		hp_label.text = str(unit_data.hp)
	if attack_label:
		attack_label.text = str(unit_data.attack)
	
	if cost_label:
		cost_label.text = str(unit_data.cost)
	
	visible = true

func hide_tooltip() -> void:
	visible = false
