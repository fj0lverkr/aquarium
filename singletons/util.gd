extends Node

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func dice_roll(sides: int) -> int:
	return randi_range(1, sides)


func dice_rollf(sides: float) -> float:
	return randf_range(1.0, sides)


func set_depth_collision(o: Node2D, dl: int) -> void:
	set_depth_collision_layer(o, dl)
	set_depth_collision_mask(o, dl)


func set_depth_collision_layer(o: Node2D, dl: int) -> void:
	if o.has_method("set_collision_layer_value"):
		for d: int in Constants.PL_DEPTH_LAYER:
			o.set_collision_layer_value(Constants.PL_DEPTH_LAYER[d], d == dl)


func set_depth_collision_mask(o: Node2D, dl: int) -> void:
	if o.has_method("set_collision_mask_value"):
		for d: int in Constants.PL_DEPTH_LAYER:
			o.set_collision_mask_value(Constants.PL_DEPTH_LAYER[d], d == dl)


func calculate_bitmask(values: Array[int]) -> int:
	if values.is_empty():
		return -1
	var value: int = 0
	for v: int in values:
		value |= 1 << (v - 1)
	return value