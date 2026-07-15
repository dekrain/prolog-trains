@icon('res://resources/time_label.dpitex')
@tool
class_name TimeLabel extends ClickablePanel

enum Mode {
	Absolute,
	Relative,
}

@export var time: int
@export var mode: Mode = Mode.Absolute

var _hbox := HBoxContainer.new()
var _icon := TextureRect.new()
var _label := Label.new()

func _init():
	super._init()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.label_settings = preload('res://resources/time_label.tres')
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon := EditorIcon.new()
	icon.icon = &'Time'
	_icon.texture = icon
	_hbox.add_child(_icon)
	_hbox.add_child(_label)
	add_child(_hbox)

func _ready():
	super._ready()
	_label.text = _format()

func set_time(mins: int):
	time = mins
	_label.text = _format()

func _format() -> String:
	var str := Util.format_time(time)
	if mode == Mode.Relative:
		return '+ ' + str
	return str
