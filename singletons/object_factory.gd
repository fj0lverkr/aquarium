extends Node

const MBE: PackedScene = preload("res://scenes/fish/mouth_bubbles_emitter.tscn")


func spawn_mouth_bubbles(where: Vector2, parent: Node) -> void:
    var mbe: MoutBubblesEmitter = MBE.instantiate()
    mbe.global_position = where
    parent.add_child(mbe)