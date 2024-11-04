class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

enum State {IDLE, HUNT, WANDER, REST, }

const SPEED: float = 200.0

@onready
var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready
var _collider: CollisionShape2D = $CollisionShape2D

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
func _physics_process(_delta: float) -> void:
	_update_navigation()


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


func _set_destination() -> void:
	var tank_size = TankManager.get_swimmable_dimensions(_get_fish_size())
	var ra
	_nav_agent.target_position


func _update_navigation() -> void:
	if _nav_agent.is_target_reachable() and not _nav_agent.is_navigation_finished():
		var next_nav_point: Vector2 = _nav_agent.get_next_path_position()
		look_at(next_nav_point)
		var initial_velocity: Vector2 = global_position.direction_to(next_nav_point) * SPEED
		_nav_agent.set_velocity(initial_velocity)
	else:
		_set_destination()


func _get_fish_size() -> float:
	var s: Vector2 = _collider.shape.get_rect().size
	return s.x if s.x > s.y else s.y


func _on_sv_depleted(s: StatusValue.StatusType) -> void:
	match s:
		StatusValue.StatusType.HEALTH:
			print("fish died")
		StatusValue.StatusType.HUNGER:
			print("fish is hungry")
		StatusValue.StatusType.ENERGY:
			print("fish is tired")


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
