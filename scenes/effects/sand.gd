class_name Sand
extends RigidBody2D

var _allow_freeze: bool = false


func _ready() -> void:
	sleeping = false
	freeze = false
	await Util.wait(0.25)
	_allow_freeze = true


func _process(_delta: float) -> void:
	if absf(linear_velocity.x) <= 0.5 and absf(linear_velocity.y) <= 0.5 and _allow_freeze:
		freeze = true
		sleeping = true
