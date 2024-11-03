class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

enum STATE {IDLE, HUNT, WANDER, REST, }

@export
var _status_collection: StatusCollection


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not _status_collection or _status_collection.get_collection().size() == 0:
		queue_free()
	else:
		_status_collection.init_collection()
		var c: Array[StatusValue] = _status_collection.get_collection()
		for s: StatusValue in c:
			print("%s: %s" % [s.get_stat_name(), s.get_stat_value()])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass
