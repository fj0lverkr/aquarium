class_name PebbleSpawner
extends Node2D

### TODO ###
# Spawn sand in depth layers, add collision masks accordingly --> DONE
# Adjust z-index accordingly
# Adjust scaling accordingly
# adjust shading accordinly


# Small inner class to store pebble data
class PebbleData:
	var body_rid: RID
	var current_position: Vector2
	var depth_layer: int
	var z_index: int
	var scale: int

	func _init(b_rid: RID, initial_pos: Vector2, dl: int) -> void:
		body_rid = b_rid
		current_position = initial_pos
		depth_layer = dl


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
var _tank_dl: int

func _ready() -> void:
	_pebbles = []
	call_deferred("_setup_debug")
	call_deferred("_setup_tank_data")


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


func _setup_tank_data() -> void:
	_tank_dl = TankManager.get_depth_layers()


func _spawn_pebbles() -> void:
	var dl: int = randi_range(1, _tank_dl)
	_setup_physics(dl)
	var p: PebbleData = PebbleData.new(_body, _spawn_position, dl)
	_pebbles.append(p)
	_debug_label.text = "Pebble count: %s" % _pebbles.size()


func _setup_physics(dl: int) -> void:
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
	_setup_depth_collision(dl)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_MASS, 0.001)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP_MODE, PhysicsServer2D.BODY_DAMP_MODE_REPLACE)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP, 2.5)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_BOUNCE, 0.25)

	# Add force integration callback to body
	PhysicsServer2D.body_set_force_integration_callback(_body, _body_moved, _pebbles.size() - 1)


func _body_moved(state: PhysicsDirectBodyState2D, index: int) -> void:
	if index < _pebbles.size() - 1:
		_pebbles[index].current_position = state.transform.origin


func _setup_depth_collision(dl: int) -> void:
	var layer_values: Array[int] = [7] # layer 7 "sand"
	var mask_values: Array[int] = [5] # mask 5 "tank borders"
	var dl_value: int = Constants.PL_DEPTH_LAYER[dl]
	var layer_value: int
	var mask_value: int
	layer_values.append(dl_value)
	mask_values.append(dl_value)
	layer_value = Util.calculate_bitmask(layer_values)
	mask_value = Util.calculate_bitmask(mask_values)
	if layer_value >= 0 and mask_value >= 0:
		PhysicsServer2D.body_set_collision_layer(_body, layer_value)
		PhysicsServer2D.body_set_collision_mask(_body, mask_value)


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