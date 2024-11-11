class_name Feed
extends RigidBody2D

const ANIM_FADE_OUT: String = "fade_out"

@onready
var _degrade_timer: Timer = $DegradeTimer
@onready
var _anim_player: AnimationPlayer = $AnimationPlayer
@onready
var _init_pos = get_position()

var _time: float = 0.0
var _amplitude: float = 1.0
var _freq: float = 1.0
var _floating: bool = false
var _picked_by: Fish = null

var nutri_value: float = 5.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not sleeping and _picked_by == null:
		_aquatic_move(delta)
	elif _picked_by != null:
		global_position = _picked_by.get_mouth_position()


func _aquatic_move(delta: float) -> void:
	_time += delta * _freq

	if _floating:
		set_position(_init_pos + Vector2(0, sin(_time) * _amplitude))
	else:
		set_position(global_position + Vector2(sin(_time) * (_amplitude / 2), 0))


func _fade_out() -> void:
	_anim_player.play(ANIM_FADE_OUT)


func check_pickable(checker: Fish) -> bool:
	if _picked_by == null:
		_picked_by = checker
		SignalBus.on_feed_picked.emit(self)
		_fade_out()
		return true
	else:
		return false


func _on_sleeping_state_changed() -> void:
	if sleeping:
		_degrade_timer.start()
	else:
		_degrade_timer.stop()


func _on_degrade_timer_timeout() -> void:
	_fade_out()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_FADE_OUT:
		queue_free()