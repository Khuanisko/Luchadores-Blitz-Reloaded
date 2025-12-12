extends SceneTree

func _init():
	print("Testing UnitData Leveling Logic...")
	
	var unit = QRCodeVerifier.new() # Using a dummy class if needed, but we can just use UnitData directly if it's a resource.
	# Wait, UnitData is a class_name.
	
	var data = UnitData.new()
	data.hp = 10
	data.attack = 2
	data.max_xp = 2
	
	print("Initial State: Level ", data.level, " XP ", data.xp, " HP ", data.hp)
	
	assert(data.level == 1, "Level should be 1")
	assert(data.xp == 0, "XP should be 0")
	
	print("Adding 1 XP...")
	data.add_xp(1)
	print("State: Level ", data.level, " XP ", data.xp)
	assert(data.level == 1, "Level should still be 1")
	assert(data.xp == 1, "XP should be 1")
	
	print("Adding 1 XP (Level Up)...")
	data.add_xp(1)
	print("State: Level ", data.level, " XP ", data.xp, " HP ", data.hp)
	assert(data.level == 2, "Level should be 2")
	assert(data.xp == 0, "XP should be 0 after level up")
	assert(data.hp == 12, "HP should increase by 2 (10->12)")
	assert(data.attack == 4, "Attack should increase by 2 (2->4)")
	
	print("UnitData Leveling Logic Verified!")
	quit()

class QRCodeVerifier:
	pass
