class_name Fish
extends CharacterBody2D

## Base class for Fish, all other Fish should inherit from this.

enum State {IDLE, CHASING, RESTING, WANDERING, SEARCHING, FLEEING, }
enum EmoteName {SLEEPING, }

const EMOTES: Dictionary = {EmoteName.SLEEPING: "sleeping", }
const SWIM: String = "swim"

const ROTATION_TIME: float = 0.4
const DEPTH_TIME: float = 1.23
const SLOW_SWIM_FACTOR: int = 2
const SLOW_DIVE_FACTOR: int = 4

const StatusType = StatusValue.StatusType

@onready
var _collider: CollisionShape2D = $FishMainCollider
@onready
var _marker_mouth_bubbles: Marker2D = $MarkerMouthBubbles
@onready
var _transient_children: Node = $TransientChildren
@onready
var _mood_player: AnimationPlayer = $MoodPlayer
@onready
var _emotes: Dictionary[EmoteName, Node2D] = {EmoteName.SLEEPING: $SleepEmote, }
@onready
var _marker_mouth_eat: Marker2D = $MarkerMouthEat
@onready
var _anim_player: AnimationPlayer = $AnimationPlayer
@onready
var _sprite: Sprite2D = $Sprite2D
@onready
var _mouth_area: Area2D = $MouthArea
@onready
var _avoidance_area: Area2D = $AvoidanceArea
@onready
var _debug_label: Label = $DebugLabel

@export
var _status_collection: StatusCollection

## TODO: possible put these exported vars in an initializer func so a global spawner can set them up for individual fish?
## or do this from the child classes in stead?

@export
var _name: String = "Unnamed fish"
@export
var _swim_speed: float = 100.0
@export
var _wait_min_max: Vector2 = Vector2(2.0, 10.0)
@export
var _scale_multiplier: float = 5.0
@export
var _energy_coefficient: float = 1
@export
var _hunger_coefficient: float = 0.25
@export
var _idle_frame_index: int = 0
@export
var _sleep_frame_index: int = 3

var _stat_health: StatusValue
var _stat_hunger: StatusValue
var _stat_energy: StatusValue
var _min_scale: Vector2
var _max_scale: Vector2
var _tank_depth_layers: int
var _current_depth_layer: int = 1
var _current_state: State = State.IDLE
var _previous_state: State = State.IDLE
var _prev_vel_x: float = 0.0
var _distance_traveled: float = 0.0
var _current_feed_target: Feed = null
var _idle_tween: Tween
var _depth_tween: Tween
var _is_idling: bool = false
var _is_moving: bool = false
var _swim_destination: Vector2 = Vector2(-1, -1)

# variables to store initial transform values so we can set and reset them later.
var _collider_initial_position: Vector2
var _debug_label_initial_scale: Vector2
var _debug_label_initial_position: Vector2
var _marker_mouth_bubbles_initial_position: Vector2
var _marker_mouth_eat_initial_position: Vector2
var _mouth_area_initial_position: Vector2
var _avoidance_area_initial_position: Vector2
var _emotes_initial_positions: Dictionary[EmoteName, Vector2]


# OVERRIDDEN FUNCTIONS

func _ready() -> void:
	SignalBus.on_tank_changed.connect(_on_tank_changed)
	for e: Sprite2D in _emotes.values():
		e.hide()
	if not _status_collection or _status_collection.get_collection().size() == 0:
		print("Instance without StatusCollection removed.")
		queue_free()
	else:
		_setup()
		SignalBus.on_feed_spawned.connect(_on_feed_spawned)
		SignalBus.on_feed_picked.connect(_on_feed_picked)
		SignalBus.on_object_clicked.connect(_on_object_clicked)
		call_deferred("_setup_debug")
		_calculate_state()


func _physics_process(_delta: float) -> void:
	if TankManager.get_debug_mode():
		_set_debug_label()
	if _current_state != State.RESTING and _current_state != State.IDLE:
		_handle_movement()


# SETUP FUNCTIONS

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
		_setup_initial_values()
	else:
		queue_free()


func _setup_initial_values() -> void:
	_collider_initial_position = _collider.position
	_debug_label_initial_scale = _debug_label.scale
	_debug_label_initial_position = _debug_label.position
	_marker_mouth_bubbles_initial_position = _marker_mouth_bubbles.position
	_marker_mouth_eat_initial_position = _marker_mouth_eat.position
	_mouth_area_initial_position = _mouth_area.position
	_avoidance_area_initial_position = _avoidance_area.position

	# Emotes:
	for e: EmoteName in _emotes.keys():
		_emotes_initial_positions[e] = _emotes[e].position


func _setup_object_scale() -> void:
	var scales_by_tank: Dictionary = TankManager.get_object_scales()
	_min_scale = scales_by_tank.min
	_max_scale = scales_by_tank.max
	_tank_depth_layers = TankManager.get_depth_layers()
	var initial_dl: int = randi_range(1, _tank_depth_layers)
	_change_depth(initial_dl)


func _setup_debug() -> void:
	_debug_label.visible = TankManager.get_debug_mode()


# MOVEMENT FUNCTIONS

func _set_depth() -> void:
	var dl: int = randi_range(1, _tank_depth_layers)
	_change_depth(dl)


func _fish_look_at(where: Vector2) -> void:
	var angle: float
	var direction: Vector2

	if _current_state == State.RESTING or _current_state == State.IDLE:
		var tween: Tween = create_tween()
		var rotation_time: float = ROTATION_TIME * SLOW_SWIM_FACTOR if _current_state == State.WANDERING else ROTATION_TIME
		direction = Vector2.RIGHT if _prev_vel_x >= 0.0 else Vector2.LEFT
		angle = (direction).angle()
		tween.tween_property(self, "rotation", lerp_angle(rotation, angle, 1.0), rotation_time)
	else:
		direction = where
		angle = (where - global_position).angle()
		look_at(direction)
	
	_correct_orientation()


func _correct_orientation() -> void:
	var facing_right: bool = _is_facing_right()
	_sprite.flip_v = !facing_right

	# Flip and reposition _debug_label
	_debug_label.scale = _flip_vector2(_debug_label_initial_scale, !facing_right)
	_debug_label.position = _flip_vector2(_debug_label_initial_position, !facing_right)

	# These get their position.x set correctly when the Fish turns, so only the position.y should be corrected:
	_collider.position.y = _flip_vector2(_collider_initial_position, !facing_right).y
	_marker_mouth_bubbles.position.y = _flip_vector2(_marker_mouth_bubbles_initial_position, !facing_right).y
	_marker_mouth_eat.position.y = _flip_vector2(_marker_mouth_eat_initial_position, !facing_right).y
	_mouth_area.position.y = _flip_vector2(_mouth_area_initial_position, !facing_right).y
	_avoidance_area.position.y = _flip_vector2(_avoidance_area_initial_position, !facing_right).y

	# Emotes:
	_flip_emotes(!facing_right)


func _handle_movement() -> void:
	# TODO we use the distance to ease out the speed, needs finetuning!
	if velocity.x != 0.0 and _prev_vel_x != velocity.x:
		_prev_vel_x = velocity.x
	if _is_moving:
		match _current_state:
			State.WANDERING:
				_fish_look_at(_swim_destination)
				var distance: Vector2 = _swim_destination - position
				if distance.abs() < Vector2(1.0, 1.0) and _is_moving:
					position = _swim_destination
					_is_moving = false
				else:
					velocity = distance.normalized() * (_swim_speed if _current_state != State.WANDERING else _swim_speed / SLOW_SWIM_FACTOR) + distance / 10
					move_and_slide()

	_set_swim_destination()
	if _is_moving and (_current_state == State.WANDERING or _current_state == State.CHASING or _current_state == State.FLEEING):
		_fish_look_at(_swim_destination)
		var distance: Vector2 = _swim_destination - position
		if distance.abs() <= Vector2(2.0, 2.0) and _is_moving:
			position = _swim_destination
			_is_moving = false
		else:
			var speed = _swim_speed
			match _current_state:
				State.WANDERING:
					speed /= 2
				State.FLEEING:
					speed *= 2
				_:
					speed = speed
					
			velocity = distance.normalized() * speed + distance / 10
			move_and_slide()
	else:
		_calculate_state()


func _set_swim_destination() -> void:
	match _current_state:
		State.WANDERING:
			if _swim_destination == position or _swim_destination == Vector2(-1, -1):
				_swim_destination = TankManager.get_random_point_in_tank()
				_swim_destination = TankManager.clamp_to_tank(_swim_destination, _get_fish_size())
				if _swim_destination == Vector2.ZERO:
					_swim_destination = position
				_set_depth()
		State.FLEEING:
			if _swim_destination == position or _swim_destination == Vector2(-1, -1):
				_fish_look_at(Vector2.ZERO)
		_:
			pass


func _change_depth(target_depth_layer: int) -> void:
	if _current_depth_layer == target_depth_layer or target_depth_layer == 0:
		return

	var target_scale: Vector2 = Vector2.ONE * _scale_multiplier
	var tween_time: float = DEPTH_TIME * SLOW_DIVE_FACTOR if _current_state == State.WANDERING else ROTATION_TIME
	var target_modulate: Color = Constants.COL_DEPTH_MOD[target_depth_layer]

	if target_depth_layer > _tank_depth_layers:
		target_depth_layer = _tank_depth_layers
	if target_depth_layer <= 0:
		target_depth_layer = 1

	target_scale.x = _max_scale.x / target_depth_layer
	target_scale.y = _max_scale.y / target_depth_layer
	if target_scale.x < _min_scale.x or target_scale.y < _min_scale.y:
		target_scale = _min_scale

	target_scale = _get_corrected_scale(target_scale)

	if _current_depth_layer == -1:
		scale = target_scale
		_sprite.self_modulate = target_modulate
	else:
		_depth_tween = create_tween()
		_depth_tween.finished.connect(_on_depth_tween_finished)
		tween_time *= absf(_current_depth_layer - target_depth_layer)
		_depth_tween.tween_property(self, "scale", target_scale, tween_time)
		_depth_tween.parallel().tween_property(_sprite, "self_modulate", target_modulate, tween_time)

	_current_depth_layer = target_depth_layer
	call_deferred("_defer_on_depth_changed")
	Util.set_depth_collision(self, _current_depth_layer)
	Util.set_depth_collision_mask(_mouth_area, _current_depth_layer)


# ANIMATION FUNCTIONS

func _idle_animation() -> void:
	if _is_idling:
		return
	_is_idling = true
	var idle_time: float = randf_range(_wait_min_max.x, _wait_min_max.y)
	var initial_tween_time: float = randf_range(0.25, 0.55)
	var tween_down_time: float = randf_range(0.25, 0.55)
	var tween_up_time = randf_range(0.25, 0.55)
	var tween_loops: int = ceili((idle_time - initial_tween_time) / (tween_down_time + tween_up_time))
	_fish_look_at(Vector2.ZERO)
	await Util.wait(ROTATION_TIME)
	if _current_state == State.RESTING:
		_sprite.frame = _sleep_frame_index
		_play_emote(EmoteName.SLEEPING)

	ObjectFactory.spawn_mouth_bubbles(_marker_mouth_bubbles.global_position, scale, _transient_children)
	_idle_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
	_idle_tween.finished.connect(_on_idle_tween_finished)
	_idle_tween.tween_property(self, "global_position:y", global_position.y - 1, initial_tween_time)
	_idle_tween.set_loops(tween_loops)
	_idle_tween.tween_property(self, "global_position:y", global_position.y + 2, tween_down_time)
	_idle_tween.tween_property(self, "global_position:y", global_position.y - 2, tween_up_time)


func _end_idle() -> void:
	for c: Node in _transient_children.get_children():
		if c is MoutBubblesEmitter:
			c.emitting = false
	_idle_tween.kill()
	_is_idling = false
	_calculate_state()


func _play_emote(emote_name: EmoteName) -> void:
	var e: Sprite2D = _emotes.get(emote_name)
	e.show()
	_mood_player.play(EMOTES.get(emote_name))


func _stop_emote(emote_name: EmoteName) -> void:
	var e: Sprite2D = _emotes.get(emote_name)
	e.hide()
	_mood_player.stop()


func _flip_emotes(flip: bool) -> void:
	for e: EmoteName in _emotes.keys():
		_emotes[e].position.y = _flip_vector2(_emotes_initial_positions[e], flip).y
		_emotes[e].flip_h = flip
		_emotes[e].flip_v = flip


# STATE FUNCTIONS

func _handle_current_state() -> void:
	if _current_state != State.RESTING:
		_sprite.frame = _idle_frame_index

	match _current_state:
		State.CHASING, State.FLEEING:
			if _anim_player.current_animation == SWIM and _anim_player.is_playing():
				return
			_anim_player.current_animation = SWIM
			_anim_player.speed_scale = 1.0 if _current_state == State.CHASING else 2.0
			_anim_player.play()
		State.SEARCHING:
			pass
		State.WANDERING:
			_is_moving = true
			_set_swim_destination()
			if _anim_player.current_animation == SWIM and _anim_player.is_playing():
				return
			_anim_player.current_animation = SWIM
			_anim_player.speed_scale = 0.5
			_anim_player.play()
		State.RESTING, State.IDLE:
			_is_moving = false
			if _anim_player.is_playing():
				_anim_player.stop()
			_idle_animation()


func _calculate_state() -> void:
	match _current_state:
		State.IDLE, State.WANDERING:
			var dice_roll: float = randf()
			if dice_roll >= 0.5:
				#_set_current_state(State.IDLE)
				_set_current_state(State.RESTING)
			else:
				_set_current_state(State.WANDERING)
		State.RESTING:
			var dice_roll: float = randf()
			if dice_roll >= 0.4:
				_set_current_state(State.WANDERING)
			else:
				_set_current_state(State.IDLE)
		State.FLEEING:
			if _previous_state != State.FLEEING:
				_set_current_state(_previous_state)
			else:
				var dice_roll: float = randf()
				if dice_roll >= 0.5:
					_set_current_state(State.WANDERING)
					_is_moving = true
				else:
					_set_current_state(State.IDLE)
	_handle_current_state()


func _set_current_state(new_state: State) -> void:
	_previous_state = _current_state
	_current_state = new_state
	SignalBus.on_fish_state_changed.emit(self, _previous_state, _current_state)


# RESOURCE FUNCTIONS

func _calculate_resources_spent() -> void:
	var energy_spent: float = _distance_traveled * _energy_coefficient
	var hunger_gained: float = _distance_traveled * _hunger_coefficient
	_stat_energy.decrease(energy_spent)
	_stat_hunger.decrease(hunger_gained)


func _calculate_feed_target() -> void:
	if _current_state != State.CHASING:
		return

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
					_current_feed_target = f

	if _current_feed_target != null and _current_feed_target.get_depth_layer() != _current_depth_layer:
		_change_depth(_current_feed_target.get_depth_layer())


# PHYSICS FUNCTIONS

func _process_slide_collisions():
	var num_col: int = get_slide_collision_count()
	if num_col == 0:
		return

	for i: int in num_col:
		var sc: KinematicCollision2D = get_slide_collision(i)
		if TankManager.get_pebble_body_rids().has(sc.get_collider_rid()):
			# Here we can interact with the pebbles if needed.
			pass


# HELPER FUNCTIONS

func _flip_vector2(vec: Vector2, flip: bool) -> Vector2:
	return vec * -1 if flip else vec


func _check_minimum_stats_present() -> void:
	if not _stat_health or not _stat_hunger or not _stat_energy:
		print("Entity is missing one or more required stats, freeing...")
		queue_free()


func _get_fish_size() -> float:
	var s: Vector2 = _collider.shape.get_rect().size * scale
	return s.x if s.x > s.y else s.y


func _set_clickable(is_clickable: bool) -> void:
	SignalBus.on_mouse_over_object_changed.emit(self if is_clickable else null)


func _filter_feed_by_dl(f: Feed) -> bool:
	return f.get_depth_layer() == _current_depth_layer


func _is_facing_right() -> bool:
	return _marker_mouth_eat.global_position.x > global_position.x or velocity.x > 0


func _get_corrected_scale(target: Vector2) -> Vector2:
	var corrected_scale: Vector2 = Vector2.ZERO
	corrected_scale.x = target.x if scale.x >= 0 else -target.x
	corrected_scale.y = target.y if scale.y >= 0 else -target.y
	return corrected_scale


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


func _get_nearest_to_tank_wall() -> float:
	var point_on_left: Vector2 = Vector2(TankManager.get_swimmable_area_corners(true, _get_fish_size() / 2).x, position.y)
	var point_on_right: Vector2 = Vector2(TankManager.get_swimmable_area_corners(false, _get_fish_size() / 2).x, position.y)
	var point_on_top: Vector2 = Vector2(position.x, TankManager.get_swimmable_area_corners(true, _get_fish_size() / 2).y)
	var point_on_bottom: Vector2 = Vector2(position.x, TankManager.get_swimmable_area_corners(false, _get_fish_size() / 2).y)

	var distances: Array[float]

	distances.append(position.distance_to(point_on_left))
	distances.append(position.distance_to(point_on_right))
	distances.append(position.distance_to(point_on_top))
	distances.append(position.distance_to(point_on_bottom))

	var shortest: float = distances[0]

	for d: float in distances:
		if d < shortest:
			shortest = d

	return shortest


func _calculate_escape_vector(from: Vector2) -> Vector2:
	var radius: float = _get_nearest_to_tank_wall()
	var angle_to: float = global_position.angle_to(from)
	var angle_reverse: float = angle_to - PI
	var escape_to: Vector2 = Vector2(position.x + radius * cos(angle_reverse), position.y + radius * sin(angle_reverse))
	escape_to = TankManager.clamp_to_tank(escape_to, _get_fish_size())
	return escape_to


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
			_current_state = State.RESTING
		StatusValue.StatusType.HUNGER:
			_current_state = State.CHASING


func _on_sv_maxed_out(s: StatusValue.StatusType) -> void:
	match s:
		StatusValue.StatusType.HEALTH:
			pass
		StatusValue.StatusType.HUNGER, StatusValue.StatusType.ENERGY:
			_current_state = State.IDLE


func _on_idle_tween_finished() -> void:
	if _current_state == State.RESTING:
		_stat_energy.increase(1000) # TODO make this depend on the time rested
		_stop_emote(EmoteName.SLEEPING)
	_end_idle()


func _on_depth_tween_finished() -> void:
	_depth_tween.kill()


func _on_avoidance_area_body_entered(body: Node2D) -> void:
	if body == self or not body is Fish:
		return
	_set_current_state(State.FLEEING)
	_swim_destination = _calculate_escape_vector(body.position)


func _on_avoidance_area_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area.get_parent() is Fish and _current_state != State.RESTING and _is_area_on_same_depth_layer(area):
		pass


func _on_mouth_area_body_entered(body: Node2D) -> void:
	if not body is Feed:
		return

	var f: Feed = body
	if f.check_pickable(self):
		_stat_hunger.increase(f.nutri_value)
		_stat_energy.increase(f.nutri_value * 0.5)
		_stat_health.increase(f.nutri_value * 0.75)
		_calculate_state()
		if _current_feed_target == f:
			_current_feed_target = null


func _on_feed_spawned() -> void:
	_calculate_feed_target()


func _on_feed_picked(by: Fish) -> void:
	if by == self:
		return
	_calculate_feed_target()


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
	var z_in_tank: int = TankManager.get_current_tank().get_object_z_index(self)
	var debug_string: String = "State: %s DL: %s, Z: %s" % [State.keys().get(_current_state), _current_depth_layer, z_in_tank]
	_debug_label.text = debug_string
