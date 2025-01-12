class_name PebbleSpawner
extends Node2D

### TODO ###
# Spawn sand in depth layers, add collision masks accordingly
# Adjust z-index accordingly
# Adjust scaling accordingly
# adjust shading accordinly


# Small inner class to store pebble data
class PebbleData:
	var body_rid: RID
	var current_position: Vector2

	func _init(b_rid: RID, initial_pos: Vector2) -> void:
		body_rid = b_rid
		current_position = initial_pos


@onready
var _debug_label: Label = $Debug

@export_range(0, 2000)
var _max_entities: int = 1500
@export
var _texture: Texture2D = preload("res://assets/images/effects/sand_8_8.png")

var _body: RID
var _shape: RID

var _enabled: bool = true # TODO: make this value depend on a game state indicating the player is in sand placement mode.
var _pebbles: Array[PebbleData]
var _spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_pebbles = []
	call_deferred("_setup_debug")


func _physics_process(_delta: float) -> void:
	queue_redraw()
	if Input.is_action_pressed("LeftClick") and _enabled:
		_spawn_position = get_global_mouse_position()
		_spawn_pebbles()
		_cull_pebbles()


func _draw() -> void:
	if not _texture:
		return
	var offset = _texture.get_size() / 2.0
	for p: PebbleData in _pebbles:
		draw_texture(
			_texture,
			p.current_position - offset
		)


func _setup_debug() -> void:
	_debug_label.visible = TankManager.get_debug_mode()


func _spawn_pebbles() -> void:
	_setup_physics()
	var p: PebbleData = PebbleData.new(_body, _spawn_position)
	_pebbles.append(p)
	_debug_label.text = "Pebble count: %s" % _pebbles.size()


func _setup_physics() -> void:
	# Create body
	_body = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_mode(_body, PhysicsServer2D.BODY_MODE_RIGID)

	# Create shape and add to body
	_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(_shape, 4)
	PhysicsServer2D.body_add_shape(_body, _shape)

	# Add body to worldspace
	PhysicsServer2D.body_set_space(_body, get_world_2d().space)
	PhysicsServer2D.body_set_state(_body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, _spawn_position))

	# Configure body
	PhysicsServer2D.body_set_collision_layer(_body, 64) # layer 7
	PhysicsServer2D.body_set_collision_mask(_body, 127) # mask 1-7
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_MASS, 0.001)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP_MODE, PhysicsServer2D.BODY_DAMP_MODE_REPLACE)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP, 2.5)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_BOUNCE, 0.25)

	# Add force integration callback to body
	PhysicsServer2D.body_set_force_integration_callback(_body, _body_moved, _pebbles.size() - 1)


func _body_moved(state: PhysicsDirectBodyState2D, index: int) -> void:
	if index < _pebbles.size() - 1:
		_pebbles[index].current_position = state.transform.origin


func _cull_pebbles() -> void:
	if _pebbles.size() >= _max_entities:
		_enabled = false


func _remove_data() -> void:
	var b: RID = _pebbles[0].body_rid
	PhysicsServer2D.free_rid(b)
	_pebbles.remove_at(0)


func _on_tree_exiting() -> void:
	for i: int in range(_pebbles.size()):
		_remove_data()


func set_enabled(e: bool) -> void:
	_enabled = e