extends Node

const MBE: PackedScene = preload("res://scenes/fish/mouth_bubbles_emitter.tscn")
const FEED: PackedScene = preload("res://scenes/feed/feed.tscn")


func spawn_mouth_bubbles(where: Vector2, parent_scale: Vector2, parent: Node) -> void:
    var mbe: MoutBubblesEmitter = MBE.instantiate()
    mbe.global_position = where
    mbe.process_material.scale = parent_scale
    parent.add_child(mbe)


func spawn_feed(where: Vector2, parent: Node) -> void:
    var f: Feed = FEED.instantiate()
    f.global_position = where
    f.mass = 0.001
    f.gravity_scale = 0.05
    f.z_index = 0
    f.add_to_group(Constants.GRP_FEED)
    parent.add_child(f)
