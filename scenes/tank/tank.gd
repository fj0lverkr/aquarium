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

@onready
var _nav_region: NavigationRegion2D = $NavigationRegion2D
@onready
var _backdrop: TextureRect = $Backdrop
@onready
var _feed_parent: Node = $Feed
@onready
var _sand_spawner: SandSpawner = $SandSpawner

var _cursor_in_feed_area: bool = false
var _cursor_over_object: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TankManager.set_current_tank(self)
	_backdrop.set_deferred("size", _size)
	_backdrop.texture = _bd_texture
	SignalBus.on_mouse_over_object_changed.connect(_on_mouse_over_object_changed)
	SignalBus.on_fish_depth_changed.connect(_on_fish_depth_changed)
	SignalBus.on_object_depth_changed.connect(_on_object_depth_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("LeftClick") and _cursor_in_feed_area:
		ObjectFactory.spawn_feed(get_global_mouse_position(), _feed_parent)


func get_random_point_in_tank() -> Vector2:
	return NavigationServer2D.region_get_random_point(_nav_region.get_rid(), 1, false)


func get_object_scales() -> Vector2:
	return Vector2(_objects_min_scale, _objects_max_scale)


func get_depth_layers() -> int:
	return _depth_layers


func _set_sand_spawner() -> void:
	var should_enable: bool = false if (_cursor_over_object or _cursor_in_feed_area) else true
	_sand_spawner.set_enabled(should_enable)


func _on_feeder_area_mouse_exited() -> void:
	_cursor_in_feed_area = false
	_set_sand_spawner()


func _on_feeder_area_mouse_entered() -> void:
	_cursor_in_feed_area = true
	_set_sand_spawner()


func _on_mouse_over_object_changed(is_over: bool) -> void:
	_cursor_over_object = is_over
	_set_sand_spawner()


func _on_fish_depth_changed(f: Fish) -> void:
	f.z_index = -100 * f.get_depth_layer()


func _on_object_depth_changed(o: Node2D) -> void:
	if o.has_method("get_depth_layer"):
		o.z_index = -100 * o.get_depth_layer()