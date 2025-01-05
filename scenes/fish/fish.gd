class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

## TODO: change movement logic to adhere to the following:
## - to get food, fish should swim to a feed item at the same "depth", changing "depth" if required
## - the change in depth should be used in all calculations that currently only use the distance traveled

enum State {IDLE, HUNT, REST, }
enum EmoteName {SLEEPING, }

const EMOTES: Dictionary = {EmoteName.SLEEPING: "sleeping", }
const SWIM: String = "swim"

const ROTATION_TIME: float = 0.4
const DEPTH_TIME: float = 1.23

const StatusType = StatusValue.StatusType

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
@onready
var _anim_player: AnimationPlayer = $AnimationPlayer
@onready
var _sprite: Sprite2D = $Sprite2D
@onready
var _mouth_area: Area2D = $MouthArea
@onready
var _debug_label:Label = $DebugLabel

@export
var _status_collection: StatusCollection

## TODO: possible put these exported vars in an initializer func so a global spawner can set them up for individual fish?
## or do this from the child classes in stead?

@export
var _name: String = "Unnamed fish"
@export
var _wait_min_max: Vector2 = Vector2(2.0, 10.0)
@export
var _swim_speed: float = 100.0
@export
var _energy_coefficient: float = 1
@export
var _hunger_coefficient: float = 0.25
@export
var _debug: bool = false


var _stat_health: StatusValue
var _stat_hunger: StatusValue
var _stat_energy: StatusValue

var _min_scale: Vector2
var _max_scale: Vector2
var _tank_depth_layers: int
var _current_depth_layer: int = -1
var _current_state: State = State.IDLE
var _current_nav_point: Vector2
var _prev_vel_x: float = 0.0
var _distance_traveled: float = 0.0
var _current_feed_target: Feed = null


func _ready() -> void:
	_debug_label.visible = _debug
	SignalBus.on_tank_changed.connect(_on_tank_changed)
	for e: Sprite2D in _emotes.values():
		e.hide()
	set_physics_process(false)
	if not _status_collection or _status_collection.get_collection().size() == 0:
		print("Instance without StatusCollection removed.")
		queue_free()
	else:
		_setup()
		NavigationServer2D.map_changed.connect(_on_nav_map_changed)
		SignalBus.on_feed_spawned.connect(_on_feed_spawned)
		SignalBus.on_feed_picked.connect(_on_feed_picked)
		SignalBus.on_object_clicked.connect(_on_object_clicked)


func _physics_process(_delta: float) -> void:
	if _current_state != State.REST:
		if _current_state == State.HUNT:
			_calculate_feed_target()
		_update_navigation()
		_handle_sprite_animation()

	if _debug:
		_set_debug_label()


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


func _setup_object_scale() -> void:
	var scales_by_tank: Dictionary = TankManager.get_object_scales()
	_min_scale = scales_by_tank.min
	_max_scale = scales_by_tank.max
	_tank_depth_layers = TankManager.get_depth_layers()
	var initial_dl: int = randi_range(1, _tank_depth_layers)
	_change_depth(initial_dl)


func _check_minimum_stats_present() -> void:
	if not _stat_health or not _stat_hunger or not _stat_energy:
		print("Entity is missing one or more required stats, freeing...")
		queue_free()


func _get_fish_size() -> float:
	var s: Vector2 = _collider.shape.get_rect().size * scale
	return s.x if s.x > s.y else s.y


func _update_navigation() -> void:
	if _current_state == State.HUNT:
		_calculate_feed_target()
		if _current_feed_target != null:
			_nav_agent.target_position = _current_feed_target.global_position
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
			_set_depth()
		State.HUNT:
			if _current_feed_target != null:
				_nav_agent.target_position = _current_feed_target.global_position
			else:
				_nav_agent.target_position = TankManager.get_random_point_in_tank()
				_set_depth()
	_distance_traveled = global_position.distance_to(_nav_agent.target_position)


func _set_depth() -> void:
	var roll: int = Util.dice_roll(6)
	if roll < 5:
		return
	var travel_time = global_position.distance_to(_nav_agent.target_position) / _swim_speed
	var dl: int = randi_range(1, _tank_depth_layers)
	var dif: int = abs(_current_depth_layer - dl)
	if travel_time > DEPTH_TIME * dif or _current_depth_layer == -1:
		_change_depth(dl)


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


func _correct_orientation() -> void:
	var new_scale: Vector2
	var abs_scale: Vector2 = Vector2(absf(scale.x), absf(scale.y))

	if velocity.x > 0.0 or (velocity.x == 0.0 and velocity.y == 0.0 and _prev_vel_x > 0.0):
		new_scale = abs_scale
		_flip_emotes(false, false)
		if _debug:
			_flip_debug_label(false)
	else:
		new_scale = Vector2(abs_scale.x, -abs_scale.y)
		_flip_emotes(false, true)
		if _debug:
			_flip_debug_label(true)

	if new_scale == scale:
		return
	scale = new_scale


func _get_corrected_scale(target: Vector2) -> Vector2:
	var corrected_scale: Vector2 = Vector2.ZERO
	corrected_scale.x = target.x if scale.x >= 0 else -target.x
	corrected_scale.y = target.y if scale.y >= 0 else -target.y
	return corrected_scale


func _rest() -> void:
	_fish_look_at(Vector2.ZERO)
	await Util.wait(ROTATION_TIME)
	_play_emote(EmoteName.SLEEPING)
	ObjectFactory.spawn_mouth_bubbles(_mbe_marker.global_position, scale, _transient_children)
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
	_stat_energy.increase(1000) # TODO make this depend on the time rested
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


func _flip_debug_label(flip: bool) -> void:
	var half_label = _debug_label.size.x / 2
	_debug_label.position.x = 0
	_debug_label.scale.x = -1 if flip else 1
	_debug_label.position.x += half_label if flip else -half_label


func _handle_sprite_animation() -> void:
	match _current_state:
		State.IDLE, State.HUNT:
			if _anim_player.current_animation == SWIM and _anim_player.is_playing():
				return
			_anim_player.current_animation = SWIM
			_anim_player.play()
		State.REST:
			if _anim_player.current_animation == SWIM and _anim_player.is_playing():
				_anim_player.stop()


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

	var filtered_feed: Array = feed.filter(_filter_feed_by_dl)
	if not filtered_feed.is_empty():
		for f: Feed in filtered_feed:
			if _current_feed_target == null or global_position.distance_to(f.global_position) < global_position.distance_to(_current_feed_target.global_position):
				if f.check_pickable():
					_current_feed_target = f
	else:
		for f: Feed in feed:
			if _current_feed_target == null or global_position.distance_to(f.global_position) < global_position.distance_to(_current_feed_target.global_position):
				if f.check_pickable():
					var travel_time = global_position.distance_to(_nav_agent.target_position) / _swim_speed
					var dl: int = f.get_depth_layer()
					var dif: int = abs(_current_depth_layer - dl)
					if travel_time > DEPTH_TIME * dif:
						_current_feed_target = f

	if _current_feed_target != null and _current_feed_target.get_depth_layer() != _current_depth_layer:
		_change_depth(_current_feed_target.get_depth_layer())


func _filter_feed_by_dl(f: Feed) -> bool:
	return f.get_depth_layer() == _current_depth_layer


func _reset_feed_target() -> void:
	if _current_state != State.HUNT:
		return
	_calculate_feed_target()
	_set_destination()


func _reset_state() -> void:
	if _stat_energy.get_stat_value() <= 0 and _stat_hunger.get_stat_value() > 0:
		_current_state = State.REST
	elif _stat_hunger.get_stat_value() <= 0:
		_current_state = State.HUNT
	else:
		_current_state = State.IDLE


func _set_clickable(is_clickable: bool) -> void:
	SignalBus.on_mouse_over_object_changed.emit(self if is_clickable else null)


func _change_depth(target_depth_layer: int) -> void:
	if _current_depth_layer == target_depth_layer:
		return

	var tween: Tween
	var target_scale: Vector2 = Vector2.ONE
	var tween_time: float = DEPTH_TIME
	var wait_time: float = randf_range(0.1, 0.15)
	var target_modulate: Color = Constants.COL_DEPTH_MOD[target_depth_layer]

	if target_depth_layer > _tank_depth_layers:
		target_depth_layer = _tank_depth_layers
	if target_depth_layer == 0:
		target_depth_layer = 1

	target_scale.x = _max_scale.x / target_depth_layer
	target_scale.y = _max_scale.y / target_depth_layer
	if target_scale.x < _min_scale.x or target_scale.y < _min_scale.y:
		target_scale = _min_scale

	await Util.wait(wait_time)
	target_scale = _get_corrected_scale(target_scale)

	if _current_depth_layer == -1:
		scale = target_scale
		_sprite.self_modulate = target_modulate
		call_deferred("_defer_on_depth_changed")
	else:
		tween = create_tween()
		tween_time *= absf(_current_depth_layer - target_depth_layer)
		tween.tween_property(self, "scale", target_scale, tween_time)
		tween.parallel().tween_property(_sprite, "self_modulate", target_modulate, tween_time)
		SignalBus.on_object_depth_changed.emit(self)

	_current_depth_layer = target_depth_layer
	Util.set_depth_collision(self, _current_depth_layer)
	Util.set_depth_collision_mask(_mouth_area, _current_depth_layer)


func _is_body_on_same_depth_layer(body: Node) -> bool:
	if not body.has_method("get_depth_layer"):
		return false
	return body.get_depth_layer() == _current_depth_layer


func _is_area_on_same_depth_layer(area: Area2D) -> bool:
	var parent: Node = area.get_parent()
	if not parent.has_method("get_depth_layer"):
		return false
	return parent.get_depth_layer() == _current_depth_layer


func _defer_on_depth_changed() -> void:
	SignalBus.on_object_depth_changed.emit(self)


# PUBLIC FUNCTIONS

func get_mouth_position() -> Vector2:
	return _marker_mouth_eat.global_position


func get_depth_layer() -> int:
	return _current_depth_layer


func get_fish_name() -> String:
	return _name


func get_max_stat_value(s: StatusType) -> float:
	return _status_collection.get_stat_by_type(s).get_stat_max_value()


func get_current_stat_value(s: StatusType) -> float:
	return _status_collection.get_stat_by_type(s).get_stat_value()


# SIGNAL HANDLERS

func _on_tank_changed() -> void:
	_setup_object_scale()


func _on_sv_depleted(s: StatusValue.StatusType) -> void:
	match s:
		StatusValue.StatusType.HEALTH:
			pass
		StatusValue.StatusType.ENERGY:
			_current_state = State.REST
		StatusValue.StatusType.HUNGER:
			_current_state = State.HUNT


func _on_sv_maxed_out(s: StatusValue.StatusType) -> void:
	match s:
		StatusValue.StatusType.HEALTH:
			pass
		StatusValue.StatusType.HUNGER, StatusValue.StatusType.ENERGY:
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
	if _is_body_on_same_depth_layer(body):
		_set_destination()


func _on_avoidance_area_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area.get_parent() is Fish and _current_state != State.REST and _is_area_on_same_depth_layer(area):
		_nav_agent.navigation_finished.emit()


func _on_mouth_area_body_entered(body: Node2D) -> void:
	if not body is Feed:
		return

	var f: Feed = body
	if f.check_pickable(self):
		_stat_hunger.increase(f.nutri_value)
		_stat_energy.increase(f.nutri_value * 0.5)
		_stat_health.increase(f.nutri_value * 0.75)
		if _current_state == State.HUNT:
			_reset_state()
		if _current_feed_target == f:
			_current_feed_target = null
		_set_destination()


func _on_feed_spawned() -> void:
	_reset_feed_target()


func _on_feed_picked(by: Fish) -> void:
	if by == self:
		return
	_reset_feed_target()


func _on_mouse_entered() -> void:
	_set_clickable(true)


func _on_mouse_exited() -> void:
	_set_clickable(false)


func _on_object_clicked(o: Node2D) -> void:
	if o == self:
		_sprite.material = Constants.MAT_SPRITE_OUTLINE
	else:
		_sprite.material = Constants.MAT_SPRITE_BASE


# DEBUG

func _set_debug_label() -> void:
	var z_in_tank:int = TankManager.get_current_tank().get_object_z_index(self)
	var debug_string: String = "DL: %s, Z: %s" % [_current_depth_layer, z_in_tank]
	_debug_label.text = debug_string
