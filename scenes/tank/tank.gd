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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_backdrop.set_deferred("size", _size)
	_backdrop.texture = _bd_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
