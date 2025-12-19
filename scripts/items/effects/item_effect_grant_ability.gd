class_name ItemEffectGrantAbility
extends ItemEffect

@export var granted_ability: Resource
@export var equipped_item_name: String = "Item"

func execute(target: UnitInstance) -> void:
    if target and granted_ability:
        target.add_temporary_ability(granted_ability)
        
        if equipped_item_name != "":
            target.add_equipped_item(equipped_item_name)
