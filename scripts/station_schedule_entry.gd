extends HBoxContainer

@onready var _l_from: Label = $From
@onready var _l_to: Label = $To
@onready var _l_schedule: Label = $Schedule
var _time := TimeLabel.new()

func _ready():
	_time.disable()
	add_child(_time)

func setup(schedule: Schedule, reverse: bool, time: int):
	if reverse:
		_l_from.text = schedule.path_names[-1]
		_l_to.text = schedule.path_names[0]
	else:
		_l_from.text = schedule.path_names[0]
		_l_to.text = schedule.path_names[-1]
	_l_schedule.text = schedule.name
	_time.set_time(time)
