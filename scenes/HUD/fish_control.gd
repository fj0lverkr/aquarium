class_name FishControl
extends Control

const StatusType = StatusValue.StatusType

@onready
var _name_label:Label = $ColorRect/MC/VB/LabelFishName
@onready
var _health_bar:TextureProgressBar = $ColorRect/MC/VB/PBHealth


var _fish:Fish


func _ready() -> void:
	visible = false
	SignalBus.on_object_clicked.connect(_on_object_clicked)


func _process(_delta:float) -> void:
	if _fish != null:
		_health_bar.max_value = _fish.get_max_stat_value(StatusType.HEALTH)
		_health_bar.value = _fish.get_current_stat_value(StatusType.HEALTH)


func _on_object_clicked(o:Node2D) -> void:
	if not o is Fish:
		visible = false
		_fish = null
	else:
		_fish = o
		_name_label.text = o.get_fish_name()
		visible = true
