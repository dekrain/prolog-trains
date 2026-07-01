class_name ScheduleButton extends Button

@export var schedule: Schedule

func _ready():
	text = schedule.name
