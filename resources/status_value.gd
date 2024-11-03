@tool
class_name StatusValue
extends Resource

## Resource that hold the name and value of a status
##
## Initially sets the value to the init_value (or max_value if if the init_value > max_value).
## Exposes get functions for the name and value.
## Exposes increase and decrease functions to set the value.
## If the value becomes <= 0, the on_depleted signal is emitted.
##
## E.g. Health 100.0

@export
var _name: String

@export
var _max_value: float

@export
var _value: float

signal on_depleted


func _clamp_value() -> void:
    _value = _value if _value <= _max_value else _max_value
    _value = _value if _value > 0.0 else 0.0


func setup() -> void:
    _clamp_value()


func get_stat_name() -> String:
    return _name


func get_stat_value() -> float:
    return _value


func decrease(by: float) -> void:
    _value -= by
    if _value <= 0:
        _value = 0
        on_depleted.emit()


func increase(by: float) -> void:
    _value += by
    if _value > _max_value:
        _value = _max_value