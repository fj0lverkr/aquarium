class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

enum State {IDLE, HUNT, REST, }

const LOOK_ROTATE_SPEED: float = 10.0
const MAX_SMOOTH_LOOK_DEG: float = 95.0

@onready
var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready
var _collider: CollisionShape2D = $CollisionShape2D
@onready
var _bubbles_mouth: GPUParticles2D = $MouthBubblesEmitter

@export
var _status_collection: StatusCollection
@export
var _wait_min_max: Vector2 = Vector2(2.0, 10.0)
@export
var _swim_speed: float = 100.0

var _stat_health: StatusValue
var _stat_hunger: StatusValue
var _stat_energy: StatusValue

var _current_state: State = State.IDLE
var _prev_vel_x: float = 0.0
var _distance_traveled: float = 0.0
var _initial_scale: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initial_scale = scale
	_bubbles_mouth.emitting = false
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
	_distance_traveled += global_position.distance_to(_nav_agent.target_position)


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

	scale = _initial_scale if velocity.x > 0.0 or (velocity.x == 0.0 and _prev_vel_x < 0.0) else Vector2(_initial_scale.x, -_initial_scale.y)


func _update_navigation() -> void:
	var next_nav_point: Vector2 = _nav_agent.get_next_path_position()
	velocity = global_position.direction_to(next_nav_point) * _swim_speed
	_fish_look_at(next_nav_point)
	move_and_slide()


func _get_fish_size() -> float:
	var s: Vector2 = _collider.shape.get_rect().size
	return s.x if s.x > s.y else s.y


func _rest() -> void:
	_fish_look_at(Vector2.ZERO)
	_bubbles_mouth.emitting = true
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "position:y", position.y - 1, 0.33)
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y + 2, 0.33)
	tween.tween_property(self, "position:y", position.y - 2, 0.33)
	await Util.wait(randf_range(_wait_min_max.x, _wait_min_max.y))
	tween.kill()
	_bubbles_mouth.emitting = false


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


func _on_navigation_finished() -> void:
	_prev_vel_x = velocity.x
	#_calculate_state()
	if _current_state == State.REST:
		await _rest()
		#_calculate_state()
	_set_destination()


func _on_avoidance_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	_nav_agent.navigation_finished.emit()
