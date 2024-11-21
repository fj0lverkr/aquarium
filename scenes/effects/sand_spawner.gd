class_name SandSpawner
extends Node2D

const SAND: PackedScene = preload("res://scenes/effects/sand.tscn")

var _sand_parent: Node
var _enabled: bool = true # TODO: make this value depend on a game state indicating the player is in sand placement mode.

func _ready() -> void:
    _sand_parent = get_tree().get_first_node_in_group(Constants.GRP_SAND)


func _process(_delta: float) -> void:
    global_position = get_global_mouse_position()
    if Input.is_action_pressed("LeftClick") and _enabled:
        _spawn_sand()


func _spawn_sand() -> void:
    var s: Sand = SAND.instantiate()
    s.global_position = global_position
    _sand_parent.add_child(s)


func set_enabled(e: bool) -> void:
    _enabled = e