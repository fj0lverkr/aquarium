extends Node

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func dice_roll(sides:int) -> int:
	return randi_range(1, sides)


func dice_rollf(sides:float) -> float:
	return randf_range(1.0, sides)
