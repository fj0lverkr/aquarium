class_name StatusCollection
extends Resource

@export
var _collection: Array[StatusValue]


func _ensure_unique() -> bool:
    for t: StatusValue.StatusType in StatusValue.StatusType.values():
        var filter: Array[StatusValue] = _collection.filter(func(s: StatusValue): return s.get_stat_type() == t)
        if filter.size() > 1:
            print("StatusCollection has multiple of %s, freeing parent!" % StatusValue.StatusType.keys()[t])
            return false
    return true

func get_collection() -> Array[StatusValue]:
    return _collection


func get_stat_by_type(t: StatusValue.StatusType) -> StatusValue:
    var filter: Array[StatusValue] = _collection.filter(func(s: StatusValue): return s.get_stat_type() == t)
    if filter.is_empty():
        return
    return filter.front()


func init_collection() -> bool:
    if _ensure_unique():
        for s: StatusValue in _collection:
            s.setup()
        return true
    return false