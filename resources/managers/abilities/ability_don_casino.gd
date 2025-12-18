class_name AbilityDonCasino
extends ManagerAbilityBase

# Don Casino: Fixer
# Even rounds: Get a free unit (or 1 gold if full)

func execute_shop_round_start(shop_node) -> void:
	# Access GameData via singleton (global)
	
	# Even rounds only (2, 4, 6...)
	if GameData.current_round % 2 != 0:
		return
		
	# Check Team Board fullness
	# shop_node has `team_board` property
	var team_board = shop_node.team_board
	
	if team_board.is_full():
		GameData.gain_gold(1)
		print("[Don Casino] Team full - gained 1 gold")
		return
		
	# Get random unit from player's tier
	# shop_node has `available_units_pool`
	var pool = shop_node.available_units_pool
	var tier_units = pool.filter(
		func(u): return u.tier == GameData.player_tier
	)
	
	if tier_units.is_empty():
		return
		
	var random_unit = tier_units.pick_random()
	var unit = UnitInstance.new(random_unit)
	
	team_board.add_unit(unit)
	unit.connect_shop_signals()
	print("[Don Casino] Free unit: ", unit.unit_name)
