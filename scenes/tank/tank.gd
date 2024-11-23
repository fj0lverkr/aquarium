class_name Tank
extends Node2D

## Base class for Tank, all other Fishtanks should inherit from this.

@export
var _size: Vector2
@export
var _bd_texture: Texture2D

@onready
var _water_shader: Sprite2D = $WaterOverlay/ShaderOverlay
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


func get_swimmable_area(fish_size: float) -> Dictionary:
	var water_size: Vector2 = Vector2(_water_shader.texture.get_width(), _water_shader.texture.get_height()) * _water_shader.transform.get_scale()
	var water_pos: Vector2 = _water_shader.position
	var min_x: float = (0.0 if water_pos.x < 0 else water_pos.x) + fish_size / 2
	var min_y: float = (0.0 if water_pos.y < 0 else water_pos.y) + fish_size / 2
	var max_x: float = water_size.x - fish_size / 2
	var max_y: float = water_size.y - fish_size / 2
	var water_min: Vector2 = Vector2(min_x, min_y)
	var water_max: Vector2 = Vector2(max_x, max_y)

	return {
		"min": water_min,
		"max": water_max
	}


func _on_feeder_area_mouse_exited() -> void:
	_cursor_in_feed_area = false
	_sand_spawner.set_enabled(true)


func _on_feeder_area_mouse_entered() -> void:
	_cursor_in_feed_area = true
	_sand_spawner.set_enabled(false)
