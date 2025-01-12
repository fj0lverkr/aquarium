class_name SandSpawner
extends Node2D


class SandData:
	var body_rid: RID
	var canvas_item_rid: RID

	func _init(b_rid: RID, ci_rid: RID) -> void:
		body_rid = b_rid
		canvas_item_rid = ci_rid


@export
var _max_sand: int = 500
@export
var _texture: Texture2D = preload("res://assets/images/effects/sand_8_8.png")

var _canvas_item: RID
var _rect: Rect2
var _image: Image

var _body: RID
var _shape: RID

var _enabled: bool = true # TODO: make this value depend on a game state indicating the player is in sand placement mode.
var _sand_array: Array[SandData]
var _spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_sand_array = []


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("LeftClick") and _enabled:
		_spawn_position = get_global_mouse_position()
		_spawn_sand()
		_cull_sand()


func _spawn_sand() -> void:
	_setup_rendering()
	_sand_array.append(_canvas_item)
	_setup_physics()
	var s: SandData = SandData.new(_body, _canvas_item)
	_sand_array.append(s)


func _setup_rendering() -> void:
	_image = _texture.get_image()
	_canvas_item = RenderingServer.canvas_item_create()
	_rect.size = Vector2(8, 8)
	RenderingServer.canvas_item_set_parent(_canvas_item, get_canvas_item())
	RenderingServer.canvas_item_add_texture_rect(_canvas_item, Rect2(-_texture.get_size() / 2, _texture.get_size()), _texture)


func _setup_physics() -> void:
	_body = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_mode(_body, PhysicsServer2D.BODY_MODE_RIGID)

	_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(_shape, 4)
	PhysicsServer2D.body_add_shape(_body, _shape)
	PhysicsServer2D.body_set_space(_body, get_world_2d().space)
	PhysicsServer2D.body_set_state(_body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, _spawn_position))
	PhysicsServer2D.body_set_collision_layer(_body, 64) # layer 7
	PhysicsServer2D.body_set_collision_mask(_body, 127) # mask 1-7
	PhysicsServer2D.body_set_force_integration_callback(_body, _body_moved, _sand_array.size() - 1)


func _body_moved(state: PhysicsDirectBodyState2D, index: int) -> void:
	if index < _sand_array.size() - 1:
		RenderingServer.canvas_item_set_transform(_sand_array[index].canvas_item_rid, state.transform)


func _cull_sand() -> void:
	if _sand_array.size() >= _max_sand:
		_enabled = false


func _remove_data() -> void:
	var ci: RID
	var b: RID
	ci = _sand_array[0].canvas_item_rid
	b = _sand_array[0].body_rid

	RenderingServer.free_rid(ci)
	PhysicsServer2D.free_rid(b)

	_sand_array.remove_at(0)


func _on_tree_exiting() -> void:
	for i: int in range(_sand_array.size()):
		_remove_data()


func set_enabled(e: bool) -> void:
	_enabled = e