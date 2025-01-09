class_name SandSpawner
extends Node2D

const SAND: PackedScene = preload("res://scenes/effects/sand.tscn")

@export
var _max_sand: int = 1500

var _sand_parent: Node
var _enabled: bool = true # TODO: make this value depend on a game state indicating the player is in sand placement mode.
var _sand_array: Array[Sand]

func _ready() -> void:
    _sand_array = []
    _sand_parent = get_tree().get_first_node_in_group(Constants.GRP_SAND)


func _process(_delta: float) -> void:
    global_position = get_global_mouse_position()
    if Input.is_action_pressed("LeftClick") and _enabled:
        _spawn_sand()


func _spawn_sand() -> void:
    var s: Sand = SAND.instantiate()
    s.global_position = global_position
    _sand_parent.add_child(s)
    _sand_array.append(s)
    _cull_sand()


func _cull_sand() -> void:
    var sand_to_cull: int = _sand_array.size() - _max_sand
    if sand_to_cull > 0:
        for i: int in range(sand_to_cull):
            var s: Sand = _sand_array.pop_at(0)
            s.queue_free()


func set_enabled(e: bool) -> void:
    _enabled = e