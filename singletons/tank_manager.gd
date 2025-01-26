extends Node

var _current_tank: Tank
var _cursor_over_object: Node2D = null

func set_current_tank(t: Tank) -> void:
	_current_tank = t
	SignalBus.on_tank_changed.emit()


func get_current_tank() -> Tank:
	return _current_tank


func get_random_point_in_tank() -> Vector2:
	return _current_tank.get_random_point_in_tank()


func get_object_scales() -> Dictionary:
	if !_current_tank:
		return {}
	var min_scale: float = _current_tank.get_object_scales().x
	var max_scale: float = _current_tank.get_object_scales().y
	return {
		"min": Vector2(min_scale, min_scale),
		"max": Vector2(max_scale, max_scale)
	}


func get_depth_layers() -> int:
	return _current_tank.get_depth_layers()


func set_cursor_over_object(o: Node2D) -> void:
	_cursor_over_object = o


func get_cursor_over_object() -> Node2D:
	return _cursor_over_object


func get_debug_mode() -> bool:
	return _current_tank.get_debug_mode()


func get_pebble_body_rids() -> Array[RID]:
	return _current_tank.get_pebble_body_rids()
