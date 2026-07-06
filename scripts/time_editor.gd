extends Control

@export var time: int = 0

func _ready():
	_display_time()

func set_time(time: int):
	self.time = time
	_display_time()

func _display_time():
	%Hours.set_value(time / 60)
	%Minutes.set_value(time % 60)
	%Text.text = Util.format_time(time)

func _value_changed():
	time = %Hours.value * 60 + %Minutes.value
	_display_time()

func _text_value_changed(text: String):
	if text.get_slice_count(':') == 2:
		var hours := text.get_slice(':', 0)
		var mins := text.get_slice(':', 1)
		if hours.is_valid_int() and mins.is_valid_int():
			var hr := hours.to_int()
			var mn := mins.to_int()
			if hr >= 0 and hr < 24 and mn >= 0 and mn < 60:
				time = hr * 60 + mn
	_display_time()
