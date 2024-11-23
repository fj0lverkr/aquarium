extends Node

var _current_tank: Tank


func set_current_tank(t: Tank) -> void:
    _current_tank = t


func get_current_tank() -> Tank:
    return _current_tank


func get_swimmable_area(fish_size: float) -> Dictionary:
    return _current_tank.get_swimmable_area(fish_size)