class_name Feed
extends RigidBody2D

const ANIM_FADE_OUT: String = "fade_out"

@onready
var _sprite: Sprite2D = $Sprite2D
@onready
var _collider: CollisionShape2D = $CollisionShape2D
@onready
var _degrade_timer: Timer = $DegradeTimer
@onready
var _float_timer: Timer = $FloatTimer
@onready
var _anim_player: AnimationPlayer = $AnimationPlayer
@onready
var _init_pos = get_global_position()

var _time: float = 0.0
var _amplitude: float = 1.0
var _freq: float = 1.0
var _floating: bool = true
var _picked_by: Fish = null
var _reset_state: bool = false
var _depth_layer: int = 1
var _min_scale: Vector2
var _max_scale: Vector2
var _aquatic_move_stopped: bool = false

var nutri_value: float = 50.0


func _ready() -> void:
	_float_timer.wait_time = randf_range(0.25, 10.0)
	_float_timer.start()
	SignalBus.on_feed_spawned.emit()


func _physics_process(delta: float) -> void:
	if _picked_by == null:
		_aquatic_move(delta)
	else:
		global_position = _picked_by.get_mouth_position()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _reset_state:
		state.transform = Transform2D(0.0, _init_pos)
		_reset_state = false


func _aquatic_move(delta: float) -> void:
	_time += delta * _freq
	if !_aquatic_move_stopped:
		if _floating:
			set_global_position(_init_pos + Vector2(0, sin(_time) * _amplitude))
		else:
			set_global_position(global_position + Vector2(sin(_time) * (_amplitude / 2), 0))


func _fade_out() -> void:
	_anim_player.play(ANIM_FADE_OUT)


func _setup_depth(dl: int) -> void:
	_depth_layer = dl
	var scales_by_tank: Dictionary = TankManager.get_object_scales()
	var target_scale: Vector2
	_min_scale = scales_by_tank.min
	_max_scale = scales_by_tank.max
	target_scale.x = _max_scale.x / dl
	target_scale.y = _max_scale.y / dl
	if target_scale.x < _min_scale.x or target_scale.y < _min_scale.y:
		target_scale = _min_scale
	_sprite.scale = target_scale
	_collider.scale = target_scale
	_sprite.self_modulate = Constants.COL_DEPTH_MOD[dl]
	Util.set_depth_collision(self, dl)
	SignalBus.on_object_depth_changed.emit(self)


#Public methods

func check_pickable(checker: Fish = null) -> bool:
	if _picked_by == null:
		_picked_by = checker
		if checker != null:
			_collider.set_deferred("disabled", true)
			SignalBus.on_feed_picked.emit(checker)
			_fade_out()
		return true
	else:
		return false


func setup(dl: int) -> void:
	_setup_depth(dl)


func get_depth_layer() -> int:
	return _depth_layer


# Signal handlers

func _on_degrade_timer_timeout() -> void:
	_fade_out()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_FADE_OUT:
		queue_free()


func _on_float_timer_timeout() -> void:
	_floating = false
	_reset_state = true
	can_sleep = true


func _on_body_shape_entered(_body_rid:RID, body:Node, _body_shape_index:int, _local_shape_index:int) -> void:
	if body is TankBottom:
		_aquatic_move_stopped = true
		_degrade_timer.start()
