class_name Tank
extends Node2D

## Base class for Tank, all other Fishtanks should inherit from this.

@export
var _size: Vector2
@export_range(1.0, 5.0)
var _objects_min_scale: float = 1.0
@export_range(1.0, 5.0)
var _objects_max_scale: float = 5.0
@export_range(1, 5)
var _depth_layers: int = 5
@export
var _bd_texture: Texture2D
@export
var _debug_mode: bool = false

@onready
var _nav_region: NavigationRegion2D = $NavigationRegion2D
@onready
var _backdrop: TextureRect = $Backdrop
@onready
var _feed_parent: Node = $Feed
@onready
var _pebble_spawner: PebbleSpawner = $PebbleSpawner

var _cursor_in_feed_area: bool = false


# Private and override functions

func _ready() -> void:
	TankManager.set_current_tank(self)
	_backdrop.set_deferred("size", _size)
	_backdrop.texture = _bd_texture
	SignalBus.on_mouse_over_object_changed.connect(_on_mouse_over_object_changed)
	SignalBus.on_object_depth_changed.connect(_on_object_depth_changed)


func _process(_delta: float) -> void:
	_handle_input()


func _handle_input() -> void:
	var coo: Node2D = TankManager.get_cursor_over_object()
	if Input.is_action_just_pressed(Constants.IA_LMB):
		SignalBus.on_object_clicked.emit(coo)
		if _cursor_in_feed_area:
			ObjectFactory.spawn_feed(get_global_mouse_position(), _feed_parent)


func _set_pebble_spawner() -> void:
	var coo: Node2D = TankManager.get_cursor_over_object()
	var should_enable: bool = false if (coo != null or _cursor_in_feed_area) else true
	_pebble_spawner.set_enabled(should_enable)


# Public methods

func get_random_point_in_tank() -> Vector2:
	return NavigationServer2D.region_get_random_point(_nav_region.get_rid(), 1, false)


func get_object_scales() -> Vector2:
	return Vector2(_objects_min_scale, _objects_max_scale)


func get_depth_layers() -> int:
	return _depth_layers


func get_object_z_index(o: Node2D) -> int:
	return o.z_index


func get_debug_mode() -> bool:
	return _debug_mode


func get_pebble_body_rids() -> Array[RID]:
	if not _pebble_spawner:
		return []
	return _pebble_spawner.get_body_rids()


# Signal handlers

func _on_feeder_area_mouse_exited() -> void:
	_cursor_in_feed_area = false
	_set_pebble_spawner()


func _on_feeder_area_mouse_entered() -> void:
	_cursor_in_feed_area = true
	_set_pebble_spawner()


func _on_mouse_over_object_changed(o: Node2D) -> void:
	TankManager.set_cursor_over_object(o)
	_set_pebble_spawner()


func _on_object_depth_changed(o: Node2D) -> void:
	if o.has_method("get_depth_layer"):
		o.z_index = -100 * o.get_depth_layer()
