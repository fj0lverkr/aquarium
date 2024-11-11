extends Node

const MBE: PackedScene = preload("res://scenes/fish/mouth_bubbles_emitter.tscn")
const FEED: PackedScene = preload("res://scenes/feed/feed.tscn")


func spawn_mouth_bubbles(where: Vector2, parent: Node) -> void:
    var mbe: MoutBubblesEmitter = MBE.instantiate()
    mbe.global_position = where
    parent.add_child(mbe)


func spawn_feed(where: Vector2, parent: Node) -> void:
    var f: Feed = FEED.instantiate()
    f.global_position = where
    f.mass = 0.001
    f.gravity_scale = 0.05
    f.z_index = 0
    parent.add_child(f)
    SignalBus.on_feed_requested.emit()
