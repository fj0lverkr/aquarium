class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

enum State {IDLE, HUNT, REST, }
enum EmoteName {SLEEPING, }

const EMOTES: Dictionary = {EmoteName.SLEEPING: "sleeping", }

const ROTATION_TIME: float = 0.4

@onready
var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready
var _collider: CollisionShape2D = $CollisionShape2D
@onready
var _mbe_marker: Marker2D = $MarkerMouthBubbles
@onready
var _transient_children: Node = $TransientChildren
@onready
var _mood_player: AnimationPlayer = $MoodPlayer
@onready
var _emotes: Dictionary = {EmoteName.SLEEPING: $SleepEmote, }
@onready
var _marker_mouth_eat: Marker2D = $MarkerMouthEat

@export
var _status_collection: StatusCollection

## TODO: possible put these exported vars in an initializer func so a global spawner can set them up for individual fish?
## or do this from the child classes in stead?

@export
var _name: String = "Unnamed fish"
@export
var _wait_min_max: Vector2 = Vector2(2.0, 10.0)
@export
var _swim_speed: float = 0 # 100.0
## TODO: use this and a max scale to gradually have the fish grow into an adult.
@export
var _initial_scale: Vector2 = Vector2(5.0, 5.0)
@export
var _max_scale: Vector2 = Vector2(5.0, 5.0)
@export
var _energy_coefficient: float = 0.05
@export
var _hunger_coefficient: float = 0.25
@export
var _hunger_treshold: float = 0.5


var _stat_health: StatusValue
var _stat_hunger: StatusValue
var _stat_energy: StatusValue

var _current_state: State = State.IDLE
var _current_nav_point: Vector2
var _prev_vel_x: float = 0.0
var _distance_traveled: float = 0.0
var _current_feed_target: Feed = null


func _ready() -> void:
	_initial_scale = scale
	for e: Sprite2D in _emotes.values():
		e.hide()
	set_physics_process(false)
	if not _status_collection or _status_collection.get_collection().size() == 0:
		print("Instance without StatusCollection removed.")
		queue_free()
	else:
		_setup()
		NavigationServer2D.map_changed.connect(_on_nav_map_changed)
		SignalBus.on_feed_picked.connect(_on_feed_picked)
		

func _physics_process(_delta: float) -> void:
	if _current_state != State.REST:
		_calculate_feed_target()
		_update_navigation()


func _setup() -> void:
	var c: Array[StatusValue] = _status_collection.get_collection()
	for s: StatusValue in c:
		s.on_depleted.connect(_on_sv_depleted)
		s.on_maxed_out.connect(_on_sv_maxed_out)

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


func _update_navigation() -> void:
	var next_nav_point: Vector2 = _nav_agent.get_next_path_position()
	velocity = global_position.direction_to(next_nav_point) * _swim_speed
	if next_nav_point != _current_nav_point:
		_fish_look_at(next_nav_point)
		_current_nav_point = next_nav_point
	_correct_orientation()
	move_and_slide()


func _set_destination() -> void:
	match _current_state:
		State.IDLE:
			_nav_agent.target_position = TankManager.get_random_point_in_tank()
		State.HUNT:
			if _current_feed_target != null:
				_nav_agent.target_position = _current_feed_target.global_position
			else:
				_current_state = State.IDLE
				_set_destination()
	_distance_traveled = global_position.distance_to(_nav_agent.target_position)


func _fish_look_at(where: Vector2) -> void:
	var angle: float
	var direction: Vector2

	if _current_state != State.REST:
		direction = where
		angle = (where - global_position).angle()
	else:
		direction = Vector2.RIGHT if _prev_vel_x > 0.0 else Vector2.LEFT
		angle = (direction).angle()

	if _current_state == State.REST:
		var tween: Tween = create_tween()
		tween.tween_property(self, "rotation", lerp_angle(rotation, angle, 1.0), ROTATION_TIME)
	else:
		look_at(direction)


func _get_fish_size() -> float:
	var s: Vector2 = _collider.shape.get_rect().size * scale
	return s.x if s.x > s.y else s.y


func _correct_orientation() -> void:
	var new_scale: Vector2

	if velocity.x > 0.0 or (velocity.x == 0.0 and velocity.y == 0.0 and _prev_vel_x > 0.0):
		new_scale = _initial_scale
		_flip_emotes(false, false)
	else:
		new_scale = Vector2(_initial_scale.x, -_initial_scale.y)
		_flip_emotes(false, true)

	if new_scale == scale:
		return
	scale = new_scale


func _rest() -> void:
	_fish_look_at(Vector2.ZERO)
	await Util.wait(ROTATION_TIME)
	_play_emote(EmoteName.SLEEPING)
	ObjectFactory.spawn_mouth_bubbles(_mbe_marker.global_position, _transient_children)
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "global_position:y", global_position.y - 1, 0.33)
	tween.set_loops()
	tween.tween_property(self, "global_position:y", global_position.y + 2, 0.33)
	tween.tween_property(self, "global_position:y", global_position.y - 2, 0.33)
	await Util.wait(randf_range(_wait_min_max.x, _wait_min_max.y))
	for c: Node in _transient_children.get_children():
		if c is MoutBubblesEmitter:
			c.emitting = false
	tween.kill()
	_stat_energy.increase(1000)
	_stop_emote(EmoteName.SLEEPING)


func _play_emote(emote_name: EmoteName) -> void:
	var e: Sprite2D = _emotes.get(emote_name)
	e.show()
	_mood_player.play(EMOTES.get(emote_name))


func _stop_emote(emote_name: EmoteName) -> void:
	var e: Sprite2D = _emotes.get(emote_name)
	e.hide()
	_mood_player.stop()


func _flip_emotes(e_flip_v: bool, e_flip_h: bool) -> void:
	for e: Sprite2D in _emotes.values():
		e.flip_h = e_flip_h
		e.flip_v = e_flip_v


func _calculate_resources_spent() -> void:
	var energy_spent: float = _distance_traveled * _energy_coefficient
	var hunger_gained: float = _distance_traveled * _hunger_coefficient
	_stat_energy.decrease(energy_spent)
	_stat_hunger.decrease(hunger_gained)


func _calculate_feed_target() -> void:
	var feed: Array = get_tree().get_nodes_in_group(Constants.GRP_FEED)
	if feed.is_empty():
		_current_feed_target = null
		return
	
	for f: Feed in feed:
		if _current_feed_target == null or global_position.distance_to(f.global_position) < global_position.distance_to(_current_feed_target.global_position):
			_current_feed_target = f

	if _current_feed_target != null and _stat_hunger.get_stat_max_value() * _hunger_treshold >= _stat_hunger.get_stat_value():
		_current_state = State.HUNT


func get_mouth_position() -> Vector2:
	return _marker_mouth_eat.global_position


func get_debug_string() -> String:
	var debug: String = _name
	debug += "\n En %s/%s" % [_stat_energy.get_stat_value(), _stat_energy.get_stat_max_value()]
	debug += "\n Hu %s/%s" % [_stat_hunger.get_stat_value(), _stat_hunger.get_stat_max_value()]
	debug += "\n He %s/%s" % [_stat_health.get_stat_value(), _stat_health.get_stat_max_value()]

	return debug


func _on_sv_depleted(s: StatusValue.StatusType) -> void:
	match s:
		StatusValue.StatusType.HEALTH:
			#print("fish %s died" % self._name)
			pass
		StatusValue.StatusType.HUNGER:
			#print("fish %s is hungry" % self._name)
			pass
		StatusValue.StatusType.ENERGY:
			_current_state = State.REST


func _on_sv_maxed_out(s: StatusValue.StatusType) -> void:
	match s:
		StatusValue.StatusType.HEALTH:
			#print("fish %s at full health" % self._name)
			pass
		StatusValue.StatusType.HUNGER:
			#print("fish %s is full" % self._name)
			pass
		StatusValue.StatusType.ENERGY:
			_current_state = State.IDLE

func _on_nav_map_changed(_map: RID) -> void:
	if !is_physics_processing():
		set_physics_process(true)
		_set_destination()


func _on_navigation_finished() -> void:
	_prev_vel_x = velocity.x
	_calculate_resources_spent()
	if _current_state == State.REST:
		await _rest()
	_set_destination()


func _on_avoidance_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	_set_destination()


func _on_avoidance_area_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area.get_parent() is Fish and _current_state != State.REST:
		_nav_agent.navigation_finished.emit()


func _on_mouth_area_body_entered(body: Node2D) -> void:
	if not body is Feed:
		return

	var f: Feed = body
	if f.check_pickable(self):
		_stat_hunger.increase(f.nutri_value)
		_stat_energy.increase(f.nutri_value * 0.5)
		_stat_health.increase(f.nutri_value * 0.75)


func _on_feed_picked(feed: Feed) -> void:
	if _current_feed_target == feed:
		_current_feed_target = null
		_set_destination()
