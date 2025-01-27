class_name PoopNode
extends RigidBody2D

var _size:int = 1
var _texture:Texture


func setup(size:int, dl:int) -> void:
	_size = size
	match size:
		1:
			_texture = preload("res://assets/images/poop/fish-log-8x8.png")
		2:
			_texture = preload("res://assets/images/poop/fish-log-16x8.png")
		3:
			_texture = preload("res://assets/images/poop/fish-log-24x8.png")
		4:
			_texture = preload("res://assets/images/poop/fish-log-32x8.png")
		_:
			print("Poop node size invalid: %s" % size)
