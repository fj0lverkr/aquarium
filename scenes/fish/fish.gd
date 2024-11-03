class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

enum State {IDLE, HUNT, WANDER, REST, }

@export
var _status_collection: StatusCollection

var _stat_health: StatusValue
var _stat_hunger: StatusValue
var _stat_energy: StatusValue

var _current_state: State = State.IDLE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not _status_collection or _status_collection.get_collection().size() == 0:
		print("Instance without StatusCollection removed.")
		queue_free()
	else:
		_setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass


func _setup() -> void:
	var c: Array[StatusValue] = _status_collection.get_collection()
	for s: StatusValue in c:
		s.on_depleted.connect(_on_sv_depleted)

	if _status_collection.init_collection():
		_stat_health = _status_collection.get_stat_by_type(StatusValue.StatusType.HEALTH)
		_stat_hunger = _status_collection.get_stat_by_type(StatusValue.StatusType.HUNGER)
		_stat_energy = _status_collection.get_stat_by_type(StatusValue.StatusType.ENERGY)
		_check_minimum_stats_present()
	else:
		queue_free()


func _check_minimum_stats_present() -> void:
	if not _stat_health or not _stat_hunger or not _stat_energy:
		print("Entity is missing one or more required stats, freeing...")
		queue_free()


func _on_sv_depleted(s: StatusValue.StatusType) -> void:
	match s:
		StatusValue.StatusType.HEALTH:
			print("fish died")
		StatusValue.StatusType.HUNGER:
			print("fish is hungry")
		StatusValue.StatusType.ENERGY:
			print("fish is tired")