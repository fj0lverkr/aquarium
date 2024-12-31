extends Node

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func dice_roll(sides: int) -> int:
	return randi_range(1, sides)


func dice_rollf(sides: float) -> float:
	return randf_range(1.0, sides)


func set_depth_collision_layer(object: Node2D, depth_layer: int) -> void:
	if object.has_method("set_collision_layer_value"):
		for dl: int in Constants.PL_DEPTH_LAYER:
			object.set_collision_layer_value(Constants.PL_DEPTH_LAYER[dl], dl == depth_layer)
			object.set_collision_mask_value(Constants.PL_DEPTH_LAYER[dl], dl == depth_layer)