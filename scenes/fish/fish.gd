class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

enum State {IDLE, HUNT, WANDER, REST, }

const SPEED: float = 200.0
const LOOK_ROTATE_SPEED: float = 10.0
const MAX_SMOOTH_LOOK_DEG: float = 95.0

@onready
var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready
var _collider: CollisionShape2D = $CollisionShape2D
@onready
var _sprite: Sprite2D = $Sprite2D

@export
var _status_collection: StatusCollection
@export
var _wait_min_max: Vector2 = Vector2(0.1, 10.0)

var _stat_health: StatusValue
var _stat_hunger: StatusValue
var _stat_energy: StatusValue

var _current_state: State = State.IDLE
var _prev_vel_x: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_physics_process(false)
	if not _status_collection or _status_collection.get_collection().size() == 0:
		print("Instance without StatusCollection removed.")
		queue_free()
	else:
		_setup()
		NavigationServer2D.map_changed.connect(_on_nav_map_changed)


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
	var random_x = randf_range(_get_fish_size(), tank_size.x)
	var random_y = randf_range(0, tank_size.y)
	_nav_agent.target_position = Vector2(random_x, random_y)


func _fish_look_at(where: Vector2) -> void:
	var point: Vector2
	if velocity.x == 0:
		var look_x = 0 if _prev_vel_x < 0 else 99999
		point = Vector2(look_x, global_position.y)
	else:
		point = where

	var angle: float = (point - self.global_position).angle()
	var angle_dif_deg: float = absf(rad_to_deg(global_rotation) - rad_to_deg(angle))
	if angle_dif_deg <= MAX_SMOOTH_LOOK_DEG:
		global_rotation = lerp_angle(global_rotation, angle, get_physics_process_delta_time() * LOOK_ROTATE_SPEED)
	else:
		look_at(point)
	_sprite.flip_v = velocity.x < 0 or (velocity.x == 0 and _prev_vel_x < 0)


func _update_navigation() -> void:
	var next_nav_point: Vector2 = _nav_agent.get_next_path_position()
	var initial_velocity: Vector2 = global_position.direction_to(next_nav_point) * SPEED
	_nav_agent.set_velocity(initial_velocity)
	_fish_look_at(next_nav_point)


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


func _on_nav_map_changed(_map: RID) -> void:
	if !is_physics_processing():
		set_physics_process(true)
		_set_destination()


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()


func _on_navigation_finished() -> void:
	_prev_vel_x = velocity.x
	_fish_look_at(Vector2.ZERO)
	await Util.wait(randf_range(_wait_min_max.x, _wait_min_max.y))
	_set_destination()
