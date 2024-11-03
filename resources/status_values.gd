class_name StatusCollection
extends Resource

@export
var _collection: Array[StatusValue]


func get_collection() -> Array[StatusValue]:
    return _collection


func init_collection() -> void:
    for s: StatusValue in _collection:
        s.setup()