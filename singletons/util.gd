extends Node

func wait(t: float) -> void:
    await get_tree().create_timer(t).timeout