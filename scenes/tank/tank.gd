@tool
class_name Tank
extends Node2D

## Base class for Tank, all other Fishtanks should inherit from this.

@export
var _size: Vector2
@export
var _bd_texture: Texture2D

@onready
var _backdrop: TextureRect = $Backdrop

var _cursor_in_feed_area: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_backdrop.set_deferred("size", _size)
	_backdrop.texture = _bd_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("LMB") and _cursor_in_feed_area:
		ObjectFactory.spawn_feed(get_global_mouse_position())


func _on_feeder_area_mouse_exited() -> void:
	_cursor_in_feed_area = false


func _on_feeder_area_mouse_entered() -> void:
	_cursor_in_feed_area = true
