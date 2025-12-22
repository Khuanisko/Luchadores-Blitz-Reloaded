extends SceneTree

func _init():
	print("--- Starting Shop Tier Verification ---")
	
	# Load Shop Scene Script to access logic (we'll instantiate it)
	var shop_scene = load("res://scenes/shop/shop.tscn").instantiate()
	# Mock GameData
	GameData.current_round = 1
	
	# Test Round 1 (Tier 1 only)
	print("\n[Test] Round 1 (Tier 1 100%)")
	shop_scene._generate_shop_items()
	var tier2_count = 0
	for unit in shop_scene.shop_units:
		print(" - Generated: ", unit.unit_name, " Tier: ", unit.tier)
		if unit.tier > 1:
			tier2_count += 1
			
	if tier2_count == 0:
		print("[Pass] Only Tier 1 units generated.")
	else:
		print("[Fail] Found high tier units in Round 1!")

	# Test Round 3 (Tier 1 60%, Tier 2 40%)
	print("\n[Test] Round 3 (Tier 1 60%, Tier 2 40%)")
	GameData.current_round = 3
	
	# Run multiple times to get distribution
	var t1 = 0
	var t2 = 0
	for i in range(20):
		shop_scene._generate_shop_items()
		for unit in shop_scene.shop_units:
			if unit.tier == 1: t1 += 1
			elif unit.tier == 2: t2 += 1
	
	print("Distribution after 20 rerolls (100 units): T1=", t1, " T2=", t2)
	if t2 > 0:
		print("[Pass] Tier 2 units appeared.")
	else:
		print("[Warning] No Tier 2 units appeared (unlucky or broken?).")
		
	# Test UI function existence
	if shop_scene.has_method("_update_tier_ui"):
		print("[Pass] UI update method exists.")
	else:
		print("[Fail] UI update method missing.")

	print("\n--- Verification Complete ---")
	quit()
