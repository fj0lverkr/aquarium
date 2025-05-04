class_name Mouth
extends Area2D

var _parent: Fish

func _ready() -> void:
	var parent: Node = get_parent()
	if not parent is Fish:
		queue_free()
	_parent = parent

func _on_mouth_area_body_entered(body: Node2D) -> void:
	if not body is Feed:
		return

	var f: Feed = body
	if f.check_pickable(_parent):
		# TODO: Play around with these values once we fully implement the stat value system
		_parent.set_stat_value(Fish.StatusType.HUNGER, f.nutri_value)
		_parent.set_stat_value(Fish.StatusType.ENERGY, f.nutri_value * 0.5)
		_parent.set_stat_value(Fish.StatusType.HEALTH, f.nutri_value * 0.2)
		_parent.unset_feed_target()
