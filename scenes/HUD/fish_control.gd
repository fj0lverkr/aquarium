class_name FishControl
extends Control

const StatusType = StatusValue.StatusType

@onready
var _name_label:Label = $ColorRect/MC/VB/LabelFishName
@onready
var _health_bar:TextureProgressBar = $ColorRect/MC/VB/HB/VBBars/PBHealth
@onready
var _health_label:Label = $ColorRect/MC/VB/HB/VBValues/LabelHealthVal
@onready
var _hunger_bar:TextureProgressBar = $ColorRect/MC/VB/HB/VBBars/PBHunger
@onready
var _hunger_label:Label = $ColorRect/MC/VB/HB/VBValues/LabelHungerVal
@onready
var _energy_bar:TextureProgressBar = $ColorRect/MC/VB/HB/VBBars/PBEnergy
@onready
var _energy_label:Label = $ColorRect/MC/VB/HB/VBValues/LabelEnergyVal


var _fish:Fish


func _ready() -> void:
	visible = false
	SignalBus.on_object_clicked.connect(_on_object_clicked)


func _process(_delta:float) -> void:
	if _fish != null:
		_health_bar.max_value = _fish.get_max_stat_value(StatusType.HEALTH)
		_health_bar.value = _fish.get_current_stat_value(StatusType.HEALTH)
		_health_label.text = "%s/%s" % [_health_bar.value, _health_bar.max_value]
		_hunger_bar.max_value = _fish.get_max_stat_value(StatusType.HUNGER)
		_hunger_bar.value = _fish.get_current_stat_value(StatusType.HUNGER)
		_hunger_label.text = "%s/%s" % [_hunger_bar.value, _hunger_bar.max_value]
		_energy_bar.max_value = _fish.get_max_stat_value(StatusType.ENERGY)
		_energy_bar.value = _fish.get_current_stat_value(StatusType.ENERGY)
		_energy_label.text = "%s/%s" % [_energy_bar.value, _energy_bar.max_value]


func _on_object_clicked(o:Node2D) -> void:
	if not o is Fish:
		visible = false
		_fish = null
	else:
		_fish = o
		_name_label.text = o.get_fish_name()
		visible = true
