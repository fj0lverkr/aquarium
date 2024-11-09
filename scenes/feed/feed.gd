class_name Feed
extends RigidBody2D

const ANIM_FADE_OUT: String = "fade_out"

@onready
var _degrade_timer: Timer = $DegradeTimer
@onready
var _anim_player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	pass


func _on_sleeping_state_changed() -> void:
	if sleeping:
		_degrade_timer.start()
	else:
		_degrade_timer.stop()


func _on_degrade_timer_timeout() -> void:
	_anim_player.play(ANIM_FADE_OUT)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_FADE_OUT:
		queue_free()
