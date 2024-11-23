extends Node

var _current_tank: Tank


func set_current_tank(t: Tank) -> void:
    _current_tank = t


func get_current_tank() -> Tank:
    return _current_tank


func get_random_point_in_tank() -> Vector2:
    return _current_tank.get_random_point_in_tank()