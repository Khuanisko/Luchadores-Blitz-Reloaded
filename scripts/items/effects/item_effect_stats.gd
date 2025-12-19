class_name ItemEffectStats
extends ItemEffect

@export var hp_bonus: int = 0
@export var attack_bonus: int = 0

func execute(target: UnitInstance) -> void:
    if target:
        if hp_bonus != 0:
            target.max_hp += hp_bonus
            target.hp += hp_bonus
            
        if attack_bonus != 0:
            target.attack += attack_bonus
