extends TextureButton

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		var type = data.get("type")
		# Open board if dragging an item or a unit
		if type == "shop_item" or type == "shop_unit" or type == "team_unit":
			var parent = get_parent()
			if parent and parent.has_method("open_board"):
				# Only trigger if not already open (though rope should be hidden if open)
				if not parent.is_open:
					parent.open_board()
			
			# We don't accept the drop itself, we just use the hover to trigger the action
			return false
	return false
