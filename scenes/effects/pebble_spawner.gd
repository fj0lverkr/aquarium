class_name PebbleSpawner
extends Node2D


# Small inner class to store pebble data
class PebbleData:
	var body_rid: RID
	var current_position: Vector2
	var current_rotation: float
	var depth_layer: int
	var scale: int

	func _init(b_rid: RID, initial_pos: Vector2, dl: int) -> void:
		body_rid = b_rid
		current_position = initial_pos
		depth_layer = dl


# Inner class to help drawing the pebbles
class PebbleGraphic extends Node2D:
	var _pb: PebbleData
	var _t: Texture2D
	var _sf: float


	func _init(pb: PebbleData, t: Texture2D, sf: float):
		_pb = pb
		_t = t
		_sf = sf
		scale *= sf
		SignalBus.on_object_depth_changed.emit(self)


	func _physics_process(_delta: float) -> void:
		queue_redraw()


	func _draw() -> void:
		if not _t:
			return
		var offset: Vector2 = _t.get_size() / 2.0
		var draw_pos: Vector2 = _pb.current_position / _sf - offset
		draw_texture(_t, draw_pos, Constants.COL_DEPTH_MOD[_pb.depth_layer])


	func get_depth_layer() -> int:
		return _pb.depth_layer


# PebbleSpawner BEGIN
@onready
var _debug_label: Label = $Debug

@export_range(0, 2000)
var _max_entities: int = 2000
@export
var _texture: Texture2D = preload("res://assets/images/effects/sand_8_8.png")

var _body: RID
var _shape: RID

var _enabled: bool = true # TODO: make this value depend on a game state indicating the player is in sand placement mode.
var _pebbles: Array[PebbleData]
var _spawn_position: Vector2 = Vector2.ZERO
var _tank_dl: int
var _scale_factor: float = 2.0

func _ready() -> void:
	_pebbles = []
	call_deferred("_setup_debug")
	call_deferred("_setup_tank_data")


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("LeftClick") and _enabled:
		_spawn_position = get_global_mouse_position()
		_spawn_pebbles()
		_cull_pebbles()


func _setup_debug() -> void:
	_debug_label.visible = TankManager.get_debug_mode()


func _setup_tank_data() -> void:
	_tank_dl = TankManager.get_depth_layers()


func _spawn_pebbles() -> void:
	var g: PebbleGraphic
	var dl: int = randi_range(1, _tank_dl)

	_setup_scale_factor(dl)
	_setup_physics(dl)
	var p: PebbleData = PebbleData.new(_body, _spawn_position, dl)
	g = PebbleGraphic.new(p, _texture, _scale_factor)
	_pebbles.append(p)
	add_child(g)

	_debug_label.text = "Pebble count: %s" % _pebbles.size()


func _setup_scale_factor(dl: int) -> void:
	var min_sf: float
	var max_sf: float
	match dl:
		1:
			min_sf = 1.5
			max_sf = 2.5
		2:
			min_sf = 1
			max_sf = 2
		3:
			min_sf = 0.75
			max_sf = 1.5
		4:
			min_sf = 0.75
			max_sf = 1.0
		5:
			min_sf = 0.5
			max_sf = 1.0

	_scale_factor = randf_range(min_sf, max_sf)


func _setup_physics(dl: int) -> void:
	var gs: float = randf_range(0.25, 1.0)
	var ss: float = 4 * _scale_factor

	# Create body
	_body = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_mode(_body, PhysicsServer2D.BODY_MODE_RIGID)

	# Create shape and add to body
	_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(_shape, ss)
	PhysicsServer2D.body_add_shape(_body, _shape)

	# Add body to worldspace
	PhysicsServer2D.body_set_space(_body, get_world_2d().space)
	PhysicsServer2D.body_set_state(_body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, _spawn_position))

	# Configure body
	_setup_depth_collision(dl)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_MASS, 0.0001)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE, gs)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP_MODE, PhysicsServer2D.BODY_DAMP_MODE_REPLACE)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP, 2.5)
	PhysicsServer2D.body_set_param(_body, PhysicsServer2D.BODY_PARAM_BOUNCE, 0.25)

	# Add force integration callback to body
	PhysicsServer2D.body_set_force_integration_callback(_body, _body_moved, _pebbles.size() - 1)


func _body_moved(state: PhysicsDirectBodyState2D, index: int) -> void:
	if index < _pebbles.size() - 1:
		_pebbles[index].current_position = state.transform.origin
		_pebbles[index].current_rotation = state.transform.get_rotation()


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


func get_body_rids() -> Array[RID]:
	var rids: Array[RID] = []
	for pd: PebbleData in _pebbles:
		rids.append(pd.body_rid)
	return rids