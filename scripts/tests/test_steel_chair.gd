extends SceneTree

func _init():
    print("--- Starting Steel Chair Verification ---")
    
    # 1. Setup Units
    var p_def = UnitDefinition.new()
    p_def.id = "hero"
    p_def.unit_name = "Hero"
    p_def.base_attack = 1
    p_def.base_hp = 10
    
    var e_def = UnitDefinition.new()
    e_def.id = "dummy"
    e_def.unit_name = "Dummy"
    e_def.base_attack = 0
    e_def.base_hp = 10
    
    var p_unit = UnitInstance.new(p_def)
    var e_unit = UnitInstance.new(e_def)
    
    print("Units Initialized.")
    print("Hero Abilities: ", p_unit.temporary_abilities.size())
    
    # 2. Equip Steel Chair
    print("\n[Action] Equipping Steel Chair...")
    var chair_ability_script = load("res://scripts/items/abilities/steel_chair_ability.gd").new()
    chair_ability_script.execute(p_unit)
    
    if p_unit.temporary_abilities.size() == 1:
        print("[Pass] Temporary ability added.")
    else:
        print("[Fail] Temporary ability count mismatch: ", p_unit.temporary_abilities.size())
        
    if "Steel Chair" in p_unit.equipped_items:
        print("[Pass] Equipped item name recorded.")
    else:
        print("[Fail] Equipped item name missing.")
        
    # 3. Simulate Battle
    print("\n[Action] Simulating Battle...")
    var sim = BattleSimulator.new()
    var result = sim.simulate([p_unit], [e_unit])
    
    # Check Logs for Entrance Damage
    var found_trigger = false
    var damage_dealt = 0
    
    for event in result.log:
        if event.type == BattleTypes.EventType.ABILITY_TRIGGER and event.trigger == BattleTypes.AbilityTrigger.ON_TAG_IN:
             if event.source == 0: # Hero ID is likely 0
                found_trigger = true
                print("Found Ability Trigger: ", event)
        
        if event.type == BattleTypes.EventType.DAMAGE and event.source == 0:
             # Check if damage was from ability (usually comes right after trigger in logic, but battle log order varies)
             # Basic attack is 1. If we see 3, it's the chair.
             if event.amount == 3:
                 damage_dealt = event.amount
                 print("Found Damage Event: ", event)
    
    if found_trigger:
        print("[Pass] Entrance Ability Triggered.")
    else:
        print("[Fail] Entrance Ability DID NOT trigger.")
        
    if damage_dealt == 3:
        print("[Pass] Dealt 3 damage (Chair Effect).")
    else:
        print("[Fail] Did not see 3 damage event. (Might be mixed with attack if logic differs, but expected 3)")

    # 4. Cleanup
    print("\n[Action] Clearing Abilities (End of Battle)...")
    p_unit.clear_temporary_abilities()
    
    if p_unit.temporary_abilities.is_empty():
        print("[Pass] Temporary abilities cleared.")
    else:
        print("[Fail] Temporary abilities NOT cleared.")
        
    if p_unit.equipped_items.is_empty():
        print("[Pass] Equipped items cleared.")
    else:
        print("[Fail] Equipped items NOT cleared.")

    print("\n--- Verification Complete ---")
    quit()
