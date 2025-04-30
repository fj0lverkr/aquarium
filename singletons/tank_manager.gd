extends Node

var _current_tank: Tank
var _cursor_over_object: Node2D = null

func set_current_tank(t: Tank) -> void:
	_current_tank = t
	SignalBus.on_tank_changed.emit()


func get_current_tank() -> Tank:
	return _current_tank


func get_random_point_in_tank() -> Vector2:
	if _current_tank:
		return _current_tank.get_random_point_in_tank()
	return Vector2.ZERO


func get_swimmable_area_corners(start: bool, margin: float = 0.0) -> Vector2:
	if _current_tank:
		if start:
			return _current_tank.get_swimmable_area_start_pos(margin)
		return _current_tank.get_swimmable_area_end_pos(margin)
	return Vector2.ZERO


func clamp_to_tank(pos: Vector2, object_size: float) -> Vector2:
	var start: Vector2 = get_swimmable_area_corners(true, object_size)
	var end: Vector2 = get_swimmable_area_corners(false, object_size)
	var new_pos: Vector2 = pos

	new_pos.x = start.x if new_pos.x <= start.x else new_pos.x
	new_pos.x = end.x if new_pos.x >= end.x else new_pos.x
	new_pos.y = start.y if new_pos.y <= start.y else new_pos.y
	new_pos.y = end.y if new_pos.y >= end.y else new_pos.y

	return new_pos


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
	if not _current_tank:
		return false
	return _current_tank.get_debug_mode()


func get_pebble_body_rids() -> Array[RID]:
	return _current_tank.get_pebble_body_rids()
