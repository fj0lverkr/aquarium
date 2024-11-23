class_name Tank
extends Node2D

## Base class for Tank, all other Fishtanks should inherit from this.

@export
var _size: Vector2
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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TankManager.set_current_tank(self)
	_backdrop.set_deferred("size", _size)
	_backdrop.texture = _bd_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("LeftClick") and _cursor_in_feed_area:
		ObjectFactory.spawn_feed(get_global_mouse_position(), _feed_parent)


func get_random_point_in_tank() -> Vector2:
	return NavigationServer2D.region_get_random_point(_nav_region.get_rid(), 1, false)


func _on_feeder_area_mouse_exited() -> void:
	_cursor_in_feed_area = false
	_sand_spawner.set_enabled(true)


func _on_feeder_area_mouse_entered() -> void:
	_cursor_in_feed_area = true
	_sand_spawner.set_enabled(false)
