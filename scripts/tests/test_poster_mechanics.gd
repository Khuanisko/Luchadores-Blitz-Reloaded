extends SceneTree

func _init():
	print("--- Starting Poster Item Verification ---")
	
	# 1. Setup GameData State
	GameData.next_purchase_stats = { "hp": 0, "attack": 0 }
	var reroll_signaled = false
	GameData.reroll_shop_requested.connect(func(): reroll_signaled = true)
	
	print("Initial State: next_purchase_stats=", GameData.next_purchase_stats, " reroll_signaled=", reroll_signaled)
	
	# 2. Execute Poster Effect
	print("\n[Action] Executing Poster Effect...")
	var effect = load("res://scripts/items/effects/item_effect_poster.gd").new()
	effect.execute(null)
	
	# 3. Verify Signals and State
	if reroll_signaled:
		print("[Pass] Reroll signal emitted.")
	else:
		print("[Fail] Reroll signal NOT emitted.")
		
	if GameData.next_purchase_stats.hp == 1 and GameData.next_purchase_stats.attack == 1:
		print("[Pass] Next purchase stats updated (+1/+1).")
	else:
		print("[Fail] Next purchase stats mismatch: ", GameData.next_purchase_stats)
		
	# 4. Cleanup
	GameData.next_purchase_stats = { "hp": 0, "attack": 0 }
	print("\n--- Verification Complete ---")
	quit()
